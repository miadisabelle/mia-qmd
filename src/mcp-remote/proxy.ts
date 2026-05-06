/**
 * qmd-remote proxy: pairs an SDK Client (over `ssh ... -- qmd mcp`) with an
 * SDK Server (over local stdio). Forwards every request verbatim, with two
 * surgical rewrites:
 *
 *   - tools/call → injectCollections() for the `query` tool
 *   - initialize → upstream's identity is replayed; instructions get the
 *     qmd-remote provenance footer appended.
 *
 * tools/list is cached on first call and re-published verbatim, so the
 * proxy's tool surface is exactly whatever the remote exposes — adding tools
 * to the local MCP later requires zero proxy changes (rispec 07 §Schema
 * Identity Strategy).
 *
 * Refs miadisabelle/mia-qmd#10 (Wave 1, rispec 07).
 */

import { Client } from "@modelcontextprotocol/sdk/client/index.js";
import { StdioClientTransport } from "@modelcontextprotocol/sdk/client/stdio.js";
// We use the low-level `Server` (not `McpServer`) on purpose. `McpServer`
// requires per-tool registration with a named Zod schema — that breaks the
// rispec's tools/list re-publish strategy, where the proxy must surface
// whatever the remote exposes without knowing the tool list at compile time.
// The deprecation hint applies to typical app authors; a generic forwarder
// needs raw setRequestHandler. (rispec 07 §Schema Identity Strategy.)
import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import {
  CallToolRequestSchema,
  CallToolResultSchema,
  ListToolsRequestSchema,
  ListToolsResultSchema,
  ListResourcesRequestSchema,
  ListResourcesResultSchema,
  ListResourceTemplatesRequestSchema,
  ListResourceTemplatesResultSchema,
  ReadResourceRequestSchema,
  ReadResourceResultSchema,
} from "@modelcontextprotocol/sdk/types.js";
import { injectCollections } from "./injector.js";
import { enrichInstructions } from "./enrich-initialize.js";
import type { ResolvedConfig, LogLevel } from "./config.js";

/** Numeric ordering for log-level gating. */
const LEVELS: Record<LogLevel, number> = { error: 0, warn: 1, info: 2, debug: 3 };

function makeLogger(level: LogLevel) {
  const threshold = LEVELS[level];
  return (msgLevel: LogLevel, msg: string) => {
    if (LEVELS[msgLevel] <= threshold) console.error(`[qmd-remote ${msgLevel}] ${msg}`);
  };
}

/**
 * Connect to the remote `qmd mcp` over SSH. Returns a connected Client and
 * the remote server's identity captured during initialize.
 */
async function connectUpstream(config: ResolvedConfig) {
  const transport = new StdioClientTransport({
    command: "ssh",
    args: [...config.sshOpts, config.host, "--", config.remoteBin, "mcp"],
  });
  const client = new Client(
    { name: "qmd-remote-proxy", version: "0.1.0" },
    { capabilities: {} },
  );
  await client.connect(transport);
  return { client, transport };
}

export async function startProxy(config: ResolvedConfig): Promise<void> {
  const log = makeLogger(config.logLevel);
  log("info", `connecting to ${config.host} via ssh -- ${config.remoteBin} mcp`);

  let upstream = await connectUpstream(config);
  let toolsListCache: unknown | null = null;

  // Capture remote identity for initialize replay.
  const remoteVersion = upstream.client.getServerVersion();
  const remoteCaps = upstream.client.getServerCapabilities() ?? {};
  const remoteInstructions = upstream.client.getInstructions();
  log("info", `upstream: ${remoteVersion?.name ?? "?"} ${remoteVersion?.version ?? "?"}`);

  // Build the agent-facing Server. Identity is replayed from upstream so
  // capabilities advertised match exactly what the remote can serve.
  const downstream = new Server(
    {
      name: remoteVersion?.name ?? "qmd",
      version: remoteVersion?.version ?? "0.0.0",
    },
    {
      capabilities: remoteCaps,
      instructions: enrichInstructions(remoteInstructions, config.host, config.collections),
    },
  );

  /**
   * Lazy reconnect: on EOF the SDK will throw on the next request. Catch,
   * fail the in-flight request with a clear MCP error, and respawn for the
   * NEXT call.
   */
  async function withReconnect<T>(fn: () => Promise<T>): Promise<T> {
    try {
      return await fn();
    } catch (err: any) {
      const msg = String(err?.message ?? err);
      const looksDisconnected =
        msg.includes("closed") || msg.includes("EPIPE") || msg.includes("ECONNRESET")
        || err?.code === -32000;
      if (looksDisconnected) {
        log("warn", `upstream disconnected: ${msg} — will respawn on next call`);
        try { await upstream.client.close(); } catch { /* ignore */ }
        upstream = await connectUpstream(config);
        toolsListCache = null;
      }
      // Surface as MCP error -32000 per rispec 07 §Connection lifecycle.
      const e = new Error("remote disconnected") as any;
      e.code = -32000;
      throw e;
    }
  }

  // tools/list — cache and re-publish verbatim.
  downstream.setRequestHandler(ListToolsRequestSchema, async () => {
    if (toolsListCache !== null) return toolsListCache as any;
    const result = await withReconnect(() =>
      upstream.client.request({ method: "tools/list" }, ListToolsResultSchema),
    );
    toolsListCache = result;
    return result as any;
  });

  // tools/call — pre-flight inject collections, forward.
  downstream.setRequestHandler(CallToolRequestSchema, async (req) => {
    const params = injectCollections(req.params as any, config.collections);
    log("debug", `tools/call ${params.name}`);
    return withReconnect(() =>
      upstream.client.request({ method: "tools/call", params }, CallToolResultSchema),
    ) as any;
  });

  // resources/list, resources/templates/list, resources/read — verbatim.
  downstream.setRequestHandler(ListResourcesRequestSchema, async (req) =>
    withReconnect(() =>
      upstream.client.request({ method: "resources/list", params: req.params }, ListResourcesResultSchema),
    ) as any,
  );
  downstream.setRequestHandler(ListResourceTemplatesRequestSchema, async (req) =>
    withReconnect(() =>
      upstream.client.request(
        { method: "resources/templates/list", params: req.params },
        ListResourceTemplatesResultSchema,
      ),
    ) as any,
  );
  downstream.setRequestHandler(ReadResourceRequestSchema, async (req) =>
    withReconnect(() =>
      upstream.client.request({ method: "resources/read", params: req.params }, ReadResourceResultSchema),
    ) as any,
  );

  await downstream.connect(new StdioServerTransport());
  log("info", "qmd-remote proxy ready");
}
