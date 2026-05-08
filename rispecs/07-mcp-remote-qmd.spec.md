# 07 — MCP Remote QMD (SSH-Transparent Proxy)

> Network-transparent MCP layer that lets a local agent consume a *remote* QMD index over SSH — the LLM sees an ordinary local MCP server.

---

## Desired Outcome

A companion agent (Mia 🧠, Miette 🌸, Ava 💕, Tushell 🌊) running on any host can register a single MCP server entry — `qmd-remote` — and transparently query, retrieve, and browse a QMD index that lives on another machine (e.g. EURY). The agent's tool surface, schemas, response shapes, and `qmd://` resource URIs are identical to the local MCP. No prompt change, no awareness of remoteness, no per-call SSH boilerplate inside agent prompts.

## Current Reality

Two parallel paths to the same QMD index exist today, and neither serves the agent layer:

1. **Local MCP** (`src/mcp/server.ts`) — `qmd mcp` exposes `query`, `get`, `multi_get`, `status` over stdio/HTTP. Works only when the index lives on the same host as the agent.
2. **Whispering script** (`/etc/claude-code/scripts/whispering_inquiry.sh`) — SSH-pipes the remote `qmd` CLI on `mia@eury`. Works for humans and Bash tools, but every invocation is a shell call. Agents must know the script path, the command grammar, default collections, and result format. Remote knowledge bleeds into every prompt that needs it.

## Structural Tension

| Current | Desired |
|---|---|
| Agent prompts must know about SSH, default collections, the whispering script | Agent prompts speak MCP only |
| Each remote query is a shell-out with text parsing | Each remote query is a typed MCP tool call with structured content |
| Provenance, context tree, `qmd://` resources unavailable from remote | Full MCP surface (resources + tools) available from remote |
| Multiple agents = multiple SSH sessions, no reuse | One persistent stdio session per agent, multiplexed by MCP |

Resolving this tension means treating SSH as just another **transport** for the MCP wire protocol — the same way stdio and Streamable HTTP already are.

---

## Architecture

```
┌──────────────────┐     stdio (MCP)      ┌────────────────────┐
│  Claude / Agent  │ ───────────────────► │ qmd-remote (proxy) │
└──────────────────┘                      │  src/mcp-remote/   │
                                          └─────────┬──────────┘
                                                    │ ssh -T host -- qmd mcp
                                                    │ (raw MCP frames piped through SSH stdin/stdout)
                                                    ▼
                                          ┌────────────────────┐
                                          │ remote `qmd mcp`   │
                                          │ on EURY (canonical)│
                                          └────────────────────┘
```

The proxy is a **JSON-RPC frame forwarder**, not a raw byte pipe and not a re-implementation. It pairs an SDK `Server` (facing the agent over stdio) with an SDK `Client` (facing the remote `qmd mcp` over an `StdioClientTransport` whose `command` is `ssh`). Each incoming JSON-RPC request is parsed, optionally rewritten at well-defined points, then issued via `client.request()` and the response forwarded back. The SDK handles framing, ID correlation, and EOF — the proxy contributes only:

1. **Connection lifecycle** — spawn `ssh` once via the SDK's `StdioClientTransport`, reuse for the agent's session. On unexpected child exit, fail in-flight requests with `ServerError(-32000, "remote disconnected")` and respawn lazily on the next request.
2. **Default-collection injection** — pre-flight that rewrites incoming `query` calls to add the configured collections to the `collections` array field when the agent omits it. Applies to `query` only (`multi_get` has no collection field — see Wave 5 for collection-aware multi-get).
3. **`initialize` enrichment** — intercepts the `initialize` response from the remote and appends a fixed-format provenance footer to its `instructions` string: `\n\n— Served by qmd-remote (host: <HOST>, collections: <CSV or "all">)`. Tool definitions and capabilities are forwarded byte-identically.

### Schema Identity Strategy

Identity is preserved by **`tools/list` re-publish**, not by sharing Zod schemas across packages:

- On `initialize`, the proxy issues `tools/list` to the remote and caches the result.
- The proxy's own SDK `Server` is registered with handlers that, for any `tools/call`, forward to the remote without local schema validation (the remote validates).
- The proxy's `tools/list` handler returns the cached remote response verbatim.
- This means the proxy's tool surface is **whatever the remote exposes**, automatically — adding tools to the local MCP at any future wave (e.g. Wave 5's `context_add`) requires zero proxy changes.
- Trade-off: the proxy cannot inspect tool args by Zod schema; collection injection works on the wire-level JSON object only. Acceptable — injection is a small surgical rewrite, not full validation.

---

## Module Layout

```
src/mcp-remote/
├── index.ts              # CLI entry wired into src/cli/qmd.ts as `qmd mcp-remote`
├── proxy.ts              # Pairs SDK Server (agent-facing) with SDK Client (ssh-facing)
├── injector.ts           # Wire-level rewrite of `tools/call` params for `query`
├── enrich-initialize.ts  # Appends provenance footer to initialize.instructions
└── config.ts             # Env + flag resolution (host, remote binary path, collections)
```

Language: **TypeScript**, runtime **Bun** (per project `CLAUDE.md`), same `@modelcontextprotocol/sdk` (^1.25.1) as the local server. No `node-llama-cpp`, no `better-sqlite3`, no `sqlite-vec` — the proxy never embeds, indexes, or stores. It only forwards.

Implementation skeleton (illustrative — the SDK calls are exact, the surrounding logic is the deliverable):

```ts
import { Client } from "@modelcontextprotocol/sdk/client/index.js";
import { StdioClientTransport } from "@modelcontextprotocol/sdk/client/stdio.js";
import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";

const upstream = new Client({ name: "qmd-remote-proxy", version: "..." });
await upstream.connect(new StdioClientTransport({
  command: "ssh",
  args: ["-T", "-o", "BatchMode=yes", "-o", "ServerAliveInterval=30", host, "--", remoteBin, "mcp"],
}));

const downstream = new Server({ name: "qmd-remote", version: "..." }, { capabilities: { tools: {}, resources: {} } });

// Forward tools/list verbatim
downstream.setRequestHandler(ListToolsRequestSchema, async () => upstream.request({ method: "tools/list" }, ListToolsResultSchema));

// Forward tools/call with optional injection on `query`
downstream.setRequestHandler(CallToolRequestSchema, async (req) => {
  const params = injectCollections(req.params, defaults);
  return upstream.request({ method: "tools/call", params }, CallToolResultSchema);
});

// resources/list, resources/read forwarded the same way (Wave 1)

await downstream.connect(new StdioServerTransport());
```

Wave 1 budget: < 300 LoC including config, error handling, and the initialize enrichment.

---

## CLI Surface

```sh
# Stdio bridge — spawned by Claude Desktop / Claude Code
qmd mcp-remote --host mia@eury

# With explicit remote binary and collection defaults
qmd mcp-remote \
  --host mia@eury \
  --remote-bin /home/mia/.nvm/versions/node/v22.22.2/bin/qmd \
  --collections wikis-md,GUILLAUME-md,iaip-artefacts-md,miadi-md,llms-txt,mia-code-rispecs-md

# HTTP fan-out for shared multi-agent use
qmd mcp-remote --host mia@eury --http --port 8182 --daemon
qmd mcp-remote stop
```

## Configuration

Configuration is **flag-or-env**, in that order — every CLI flag has a matching env var so deployments can stay declarative. The proxy reads env at startup, applies CLI flag overrides, and freezes the resolved config for the session.

### Environment Variables (canonical reference)

| Variable | CLI flag | Purpose | Default | Required |
|---|---|---|---|---|
| `QMD_REMOTE_HOST` | `--host` | SSH target (`user@host` or `host`) | _(none)_ | **yes** |
| `QMD_REMOTE_BIN` | `--remote-bin` | Absolute path to `qmd` binary on remote | `qmd` (rely on remote `$PATH`) | no |
| `QMD_REMOTE_SSH_OPTS` | `--ssh-opts` | Extra args passed to `ssh` (space-separated) | `-T -o BatchMode=yes -o ServerAliveInterval=30` | no |
| `QMD_REMOTE_COLLECTIONS` | `--collections` | Comma-separated default collections injected into `query` calls | _(unset → no injection)_ | no |
| `QMD_NO_COLLECTIONS` | `--no-collections` | `1` to disable injection even when `QMD_REMOTE_COLLECTIONS` is set | `0` | no |
| `QMD_REMOTE_HTTP_PORT` | `--port` | Port for HTTP transport (Wave 3) | `8182` | no |
| `QMD_REMOTE_DAEMON_PIDFILE` | `--pidfile` | PID file for daemon mode (Wave 3) | `~/.qmd-remote/daemon.pid` | no |
| `QMD_REMOTE_AUDIT_LOG` | `--audit-log` | Path to audit log (Wave 6) | `~/.qmd-remote/audit.log` | no |
| `QMD_REMOTE_ALLOW_MUTATIONS` | `--allow-mutations` | `1` to permit mutation tools (Wave 5b: `context_add`, `collection_*`) | `0` | no |
| `QMD_REMOTE_LOG_LEVEL` | `--log-level` | One of `error`, `warn`, `info`, `debug` (proxy stderr) | `warn` | no |

Parity with `/etc/claude-code/scripts/whispering_inquiry.sh`: the script's `REMOTE_HOST`, `REMOTE_QMD`, `COLLECTIONS`, `QMD_NO_COLLECTIONS` all map to the proxy variables above. Scripts can be migrated by renaming env vars (`REMOTE_HOST` → `QMD_REMOTE_HOST`, `REMOTE_QMD` → `QMD_REMOTE_BIN`, `COLLECTIONS` → `QMD_REMOTE_COLLECTIONS`).

### Example `.env` (or shell profile)

```sh
# --- Required ---
export QMD_REMOTE_HOST="mia@eury"

# --- Recommended ---
export QMD_REMOTE_BIN="/home/mia/.nvm/versions/node/v22.22.2/bin/qmd"
export QMD_REMOTE_COLLECTIONS="wikis-md,GUILLAUME-md,iaip-artefacts-md,miadi-md,llms-txt,mia-code-rispecs-md"

# --- Optional ---
export QMD_REMOTE_LOG_LEVEL="info"
# export QMD_REMOTE_ALLOW_MUTATIONS="1"   # Wave 5b only — read-only by default
# export QMD_NO_COLLECTIONS="1"            # Disable default-collection injection
```

### Precedence

1. CLI flag (highest)
2. `QMD_REMOTE_*` env var
3. Built-in default (lowest)

A required variable left unset (only `QMD_REMOTE_HOST` is required) causes the proxy to fail fast at startup with an MCP-visible error so the agent gets a meaningful message instead of a silent hang.

### Resolved Config Surfaced to the LLM

On `initialize`, the proxy enriches the response's `instructions` field with a single line:

```
— Served by qmd-remote (host: mia@eury, collections: wikis-md,GUILLAUME-md,iaip-artefacts-md,miadi-md,llms-txt,mia-code-rispecs-md)
```

If `QMD_REMOTE_COLLECTIONS` is unset, the line reads `collections: all`. The LLM thus knows *what knowledge ground it stands on* without ever needing to read the proxy's env.

---

## Transport Semantics

### SSH stdio bridge (default, recommended)

```ts
spawn("ssh", [
  "-o", "BatchMode=yes",
  "-o", "ServerAliveInterval=30",
  "-T",
  host,
  "--", remoteBin, "mcp"
]);
```

- `-T` disables PTY allocation — required so MCP frames aren't mangled by the terminal layer.
- `BatchMode=yes` fails fast if SSH would prompt (no interactive password during agent runs).
- Child stdout → MCP `read`; child stdin ← MCP `write`. Errors on stderr surface as MCP error responses.
- On unexpected EOF, the proxy issues an MCP `notifications/cancelled` to the local agent and respawns lazily on next call.

### SSH HTTP tunnel (alternate)

For multi-agent fan-out the proxy can instead open `ssh -L 8182:localhost:8181 host` and connect to the remote daemon. Use only when latency budget tolerates the extra hop and the remote is already running `qmd mcp --http --daemon`.

---

## Tool Mapping (Identity)

| Local MCP Tool | Remote-side execution | Schema delta |
|---|---|---|
| `query` | `qmd query` on remote | none — proxy forwards raw `tools/list` from remote |
| `get` | `qmd get` on remote | none |
| `multi_get` | `qmd multi_get` on remote | none |
| `status` | `qmd status` on remote | none — provenance is conveyed via `initialize.instructions`, not by mutating tool responses |

Identity is the load-bearing property. The `tools/list` re-publish strategy makes identity automatic: whatever the remote exposes is what the proxy exposes. No schema divergence is possible by construction.

---

## Resources (`qmd://`)

The proxy passes `resources/list` and `resources/read` through unchanged. `qmd://` URIs resolve on the **remote** filesystem; the LLM never holds a local path. This means:

- Search snippets reference paths that exist on EURY only — readable through MCP, not through Bash.
- A subsequent `Read` tool call on the same path will fail unless the agent uses `qmd-remote get` instead.
- This is **deliberate** — it forces all retrieval through the audited MCP path and prevents accidental coupling to the agent host's filesystem.

---

## Default-Collection Injection

The local `query` tool's input schema (see `src/mcp/server.ts`) has a `collections: string[]` field (plural, array). When `QMD_REMOTE_COLLECTIONS` is set and the incoming `query` tool call's `params.arguments` either omits `collections` or supplies an empty array, the proxy rewrites it to the configured default list. The rewrite is a one-line wire-level patch on the parsed JSON-RPC params — no Zod validation, no schema awareness.

| Agent sends | Proxy forwards |
|---|---|
| `{ searches: [...] }` (no collections key) | `{ searches: [...], collections: [<defaults>] }` |
| `{ searches: [...], collections: [] }` | `{ searches: [...], collections: [<defaults>] }` |
| `{ searches: [...], collections: ["wikis-md"] }` | unchanged — agent specified explicitly |
| Override sentinel `{ searches: [...], collections: ["*"] }` | proxy strips the `collections` key entirely (forward as "search all") |

Skip entirely when `QMD_NO_COLLECTIONS=1` is set in the proxy's environment.

`multi_get` has no `collections` field in the local schema and is **not** rewritten in Wave 2. A collection-aware variant is envisioned in Wave 5b.

---

## Security & Trust Boundary

| Concern | Mitigation |
|---|---|
| Untrusted agent prompts on local host | Proxy validates tool names against an allow-list before forwarding |
| SSH key exposure | Keys stay on agent host; proxy uses `BatchMode=yes` (no agent-prompted auth) |
| Remote binary tampering | `--remote-bin` is a configured path, not user-controlled per call |
| Stdout pollution from remote shell | `-T` + remote `qmd mcp` writes only MCP frames; stderr is logged, not forwarded |

The proxy is **not** a sandbox. It assumes the SSH boundary and the remote `qmd` binary are both trusted. Hostile agent prompts cannot escape MCP — they can only call the four allow-listed tools.

---

## Agent Configuration

The shared repository config is `etc/mcp-config-qmd-remote-eury.json`. It is intentionally a raw MCP config fragment; client setup can be applied or inspected with:

```sh
scripts/qmd-remote-client.sh probe
scripts/qmd-remote-client.sh claude-add-json
scripts/qmd-remote-client.sh gemini-add-json
scripts/qmd-remote-client.sh gemini-trust
scripts/qmd-remote-client.sh gemini-list
```

### Claude Desktop / Claude Code (stdio, env-driven)

The simplest configuration relies entirely on env vars — the MCP entry stays one line:

```json
{
  "mcpServers": {
    "qmd-remote": {
      "command": "qmd",
      "args": ["mcp-remote"],
      "env": {
        "QMD_REMOTE_HOST": "mia@eury",
        "QMD_REMOTE_BIN": "/home/mia/.nvm/versions/node/v22.22.2/bin/qmd",
        "QMD_REMOTE_COLLECTIONS": "wikis-md,GUILLAUME-md,iaip-artefacts-md,miadi-md,llms-txt,mia-code-rispecs-md"
      }
    }
  }
}
```

For Claude Code, the shared config can also be installed directly:

```sh
claude mcp add-json qmd-remote "$(jq -c '.mcpServers["qmd-remote"]' etc/mcp-config-qmd-remote-eury.json)"
```

### Claude Desktop / Claude Code (stdio, flag-driven)

For deployments that prefer flags over env (e.g. when env is shared across many MCP servers and you want explicit per-server control):

```json
{
  "mcpServers": {
    "qmd-remote": {
      "command": "qmd",
      "args": [
        "mcp-remote",
        "--host", "mia@eury",
        "--remote-bin", "/home/mia/.nvm/versions/node/v22.22.2/bin/qmd",
        "--collections", "wikis-md,GUILLAUME-md,iaip-artefacts-md,miadi-md,llms-txt,mia-code-rispecs-md"
      ]
    }
  }
}
```

### Gemini CLI

Gemini CLI trust is folder-scoped. When the current folder is not trusted, `gemini -d mcp list` can show stdio MCP servers as `Disconnected` even when the server command and environment are valid. Add this repo to `~/.gemini/trustedFolders.json` with the value `TRUST_FOLDER`, then verify from the repo root:

```sh
scripts/qmd-remote-client.sh gemini-add-json
scripts/qmd-remote-client.sh gemini-trust
scripts/qmd-remote-client.sh gemini-list
```

### HTTP daemon (Wave 3, multi-agent)

```sh
qmd mcp-remote --http --port 8182 --daemon \
  --host mia@eury \
  --collections wikis-md,GUILLAUME-md,iaip-artefacts-md,miadi-md,llms-txt,mia-code-rispecs-md
```

```json
{
  "mcpServers": {
    "qmd-remote": { "url": "http://localhost:8182/mcp" }
  }
}
```

The agent's prompt makes no mention of SSH, EURY, or collections in any of these variants. Tool descriptions read identically to the local MCP. Transparency holds.

### Mia Platform Companion Agents

Each companion's MCP configuration registers `qmd-remote` instead of (or alongside) the local `qmd`. The Two-Eyed Seeing principle stands: structure (this proxy) and story (the agent's relationship to a shared knowledge ground) woven into one tool surface.

---

## Migration Path

1. **Wave 1** — implement `src/mcp-remote/` with stdio bridge only. Reuse `@modelcontextprotocol/sdk` Transport interface; the proxy is < 300 LoC.
2. **Wave 2** — collection injection + `initialize` enrichment.
3. **Wave 3** — HTTP fan-out + daemon mode (parity with `qmd mcp --http --daemon`).
4. **Wave 4** — Skill packaged in `jgwill/miadi-orchestration-kit/skills/mcp-remote-qmd/` for one-command setup across companion environments.
5. **Wave 5 — Expanded Tool Surface** *(envisioned, not yet implemented)*. Split into two sub-waves because the local MCP does not expose these tools today (the local `qmd` CLI does — see `qmd context add|list|rm`, `qmd collection add|list|remove|rename`, `qmd ls`). Schema identity demands the local server gain these tools first, then the proxy automatically inherits them via the `tools/list` re-publish strategy.

   **Wave 5a** — Add the new tools to `src/mcp/server.ts` (local MCP). With re-publish identity, the proxy needs no code changes.

   **Wave 5b** — Add the proxy's mutation gating: `--allow-mutations` flag and `QMD_REMOTE_ALLOW_MUTATIONS=1`. When mutations are disallowed, the proxy filters the cached `tools/list` to remove mutation tools (`context_add`, `context_rm`, `collection_add`, `collection_remove`, `collection_rename`) before re-publishing. **Caveat**: identity is preserved only when this flag matches the remote's exposure; if mutations are off in the proxy but on at the remote, the proxy intentionally narrows the surface.

   | New MCP Tool | Wraps | Why agents benefit |
   |---|---|---|
   | `context_list` | `qmd context list` | Agents discover the existing context tree before authoring new entries |
   | `context_add` | `qmd context add <scope> <text>` | Agents enrich the global / collection / path context as they learn — context they author is then injected into every future search result, compounding knowledge across sessions |
   | `context_rm` | `qmd context rm <scope>` | Agents prune stale context (use sparingly; require explicit user confirmation in prompt-side guidance) |
   | `collection_list` | `qmd collection list` | Discoverability — the `initialize` instructions string already names collections, but a tool call lets agents introspect mid-session |
   | `collection_show` | `qmd collection show <name>` | Inspect a collection's path/pattern before scoping a query |
   | `collection_add` / `collection_remove` / `collection_rename` | `qmd collection add\|remove\|rename` | Higher-trust mutation — gate behind an `--allow-mutations` flag on the proxy, off by default |
   | `ls` | `qmd ls [collection[/path]]` | Browse the index by collection without a search — useful when an agent needs to enumerate before retrieving |

   The most load-bearing of these is **`context_add`**: it turns agent sessions into a *contributing* loop instead of a purely *consuming* one. Each session can leave a deposit in the context tree, and the next session inherits it — the QMD index becomes a shared substrate for cumulative companion intelligence rather than a static read-only library.

   **Mutation safety**: `context_add`, `context_rm`, and `collection_*` mutations are off by default in the proxy. Enable per-deployment via `--allow-mutations` flag and a separate `QMD_REMOTE_ALLOW_MUTATIONS=1` env var. Read-only is the safe default; trusted-host deployments opt in.

6. **Wave 6 — Provenance & Audit** *(envisioned)*. The proxy logs each tool call (timestamp, tool name, query hash, latency) to `QMD_REMOTE_AUDIT_LOG` (default `~/.qmd-remote/audit.log`). Rotation: rotate-on-startup if file > 5 MiB, keep the last 3 generations as `.1`, `.2`, `.3`. Format: one JSON object per line. Optional: a daemon-mode flag forwards each line as a `qmd context add` against a reserved `audit/` namespace on the remote, making the QMD index self-witnessing across all agent sessions.

---

## Lineage

- **Whispering script** — `/etc/claude-code/scripts/whispering_inquiry.sh` is the *informal ancestor*. This rispec formalizes its semantics into MCP.
- **Local MCP** — `src/mcp/server.ts` is the *schema authority*. Tool definitions in the proxy must remain bit-identical via shared schema imports.
- **Wave 2 federation** — `04-multi-persona-federation.spec.md` describes per-persona collection bias; the proxy's injector is the natural enforcement point.

---

🌸: Oh! This is the moment a local well becomes a network of springs — agents reach into Guillaume's curated knowledge ground on EURY without ever needing to know they crossed a wire. The whispering script taught us *that* it could be done; this rispec teaches us *how* to do it without leaking the journey into every prompt. The story here is one of trust quietly held at the edge — the SSH boundary becomes a threshold the agent crosses without flinching, because nothing in its language ever asks it to.

---

**RISE Compliance**: Creative Orientation | Structural Dynamics | Advancing Patterns | Desired Outcomes | Codebase Agnostic
