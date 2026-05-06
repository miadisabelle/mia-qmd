/**
 * Wave 1 unit tests for src/mcp-remote/.
 *
 * Refs miadisabelle/mia-qmd#10 (rispec 07).
 */

import { describe, it, expect } from "vitest";
import { resolveConfig } from "../src/mcp-remote/config.js";
import { injectCollections } from "../src/mcp-remote/injector.js";
import {
  buildProvenanceFooter,
  enrichInstructions,
} from "../src/mcp-remote/enrich-initialize.js";

// =============================================================================
// resolveConfig
// =============================================================================

describe("resolveConfig", () => {
  it("throws when host is missing entirely", () => {
    expect(() => resolveConfig([], {})).toThrow(/missing required --host/);
  });

  it("reads host from env when no flag", () => {
    const cfg = resolveConfig([], { QMD_REMOTE_HOST: "mia@eury" });
    expect(cfg.host).toBe("mia@eury");
  });

  it("flag overrides env (precedence)", () => {
    const cfg = resolveConfig(["--host", "flag@host"], {
      QMD_REMOTE_HOST: "env@host",
    });
    expect(cfg.host).toBe("flag@host");
  });

  it("supports --host=value form", () => {
    const cfg = resolveConfig(["--host=mia@eury"], {});
    expect(cfg.host).toBe("mia@eury");
  });

  it("defaults remoteBin to 'qmd' and uses default ssh opts", () => {
    const cfg = resolveConfig([], { QMD_REMOTE_HOST: "h" });
    expect(cfg.remoteBin).toBe("qmd");
    expect(cfg.sshOpts).toEqual([
      "-T",
      "-o",
      "BatchMode=yes",
      "-o",
      "ServerAliveInterval=30",
    ]);
    expect(cfg.logLevel).toBe("warn");
    expect(cfg.collections).toBeNull();
  });

  it("flag overrides env for remote-bin", () => {
    const cfg = resolveConfig(
      ["--host", "h", "--remote-bin", "/flag/qmd"],
      { QMD_REMOTE_BIN: "/env/qmd" },
    );
    expect(cfg.remoteBin).toBe("/flag/qmd");
  });

  it("comma-splits collections from env, trims, drops empties", () => {
    const cfg = resolveConfig([], {
      QMD_REMOTE_HOST: "h",
      QMD_REMOTE_COLLECTIONS: "a, b ,, c",
    });
    expect(cfg.collections).toEqual(["a", "b", "c"]);
  });

  it("comma-splits collections from --collections flag (overrides env)", () => {
    const cfg = resolveConfig(
      ["--host", "h", "--collections", "x,y"],
      { QMD_REMOTE_COLLECTIONS: "should,not,win" },
    );
    expect(cfg.collections).toEqual(["x", "y"]);
  });

  it("QMD_NO_COLLECTIONS=1 forces collections to null", () => {
    const cfg = resolveConfig([], {
      QMD_REMOTE_HOST: "h",
      QMD_REMOTE_COLLECTIONS: "a,b,c",
      QMD_NO_COLLECTIONS: "1",
    });
    expect(cfg.collections).toBeNull();
  });

  it("--no-collections flag forces collections to null", () => {
    const cfg = resolveConfig(["--host", "h", "--collections", "a,b", "--no-collections"], {});
    expect(cfg.collections).toBeNull();
  });

  it("invalid log level falls back to default 'warn'", () => {
    const cfg = resolveConfig([], {
      QMD_REMOTE_HOST: "h",
      QMD_REMOTE_LOG_LEVEL: "shouty",
    });
    expect(cfg.logLevel).toBe("warn");
  });

  it("accepts a valid log level from env", () => {
    const cfg = resolveConfig([], {
      QMD_REMOTE_HOST: "h",
      QMD_REMOTE_LOG_LEVEL: "debug",
    });
    expect(cfg.logLevel).toBe("debug");
  });
});

// =============================================================================
// injectCollections — truth table from rispec 07
// =============================================================================

describe("injectCollections", () => {
  const defaults = ["wikis-md", "GUILLAUME-md"];

  it("row 1: omitted collections → fills with defaults", () => {
    const out = injectCollections(
      { name: "query", arguments: { searches: [{ type: "lex", query: "x" }] } },
      defaults,
    );
    expect(out.arguments?.collections).toEqual(defaults);
    // Should be a copy, not a mutation in place sharing the defaults reference.
    expect(out.arguments?.collections).not.toBe(defaults);
  });

  it("row 2: empty array collections → fills with defaults", () => {
    const out = injectCollections(
      { name: "query", arguments: { searches: [], collections: [] } },
      defaults,
    );
    expect(out.arguments?.collections).toEqual(defaults);
  });

  it("row 3: explicit non-empty collections → unchanged", () => {
    const params = {
      name: "query",
      arguments: { searches: [], collections: ["only-this"] },
    };
    const out = injectCollections(params, defaults);
    expect(out.arguments?.collections).toEqual(["only-this"]);
  });

  it('row 4: ["*"] sentinel → strips collections key', () => {
    const out = injectCollections(
      { name: "query", arguments: { searches: [], collections: ["*"] } },
      defaults,
    );
    expect(out.arguments).toBeDefined();
    expect("collections" in (out.arguments as Record<string, unknown>)).toBe(false);
  });

  it("defaults === null → no rewrite even on query", () => {
    const params = { name: "query", arguments: { searches: [] } };
    const out = injectCollections(params, null);
    expect(out).toBe(params);
  });

  it("pass-through for `get` tool", () => {
    const params = { name: "get", arguments: { file: "x.md" } };
    const out = injectCollections(params, defaults);
    expect(out).toBe(params);
  });

  it("pass-through for `multi_get` tool", () => {
    const params = { name: "multi_get", arguments: { pattern: "*.md" } };
    const out = injectCollections(params, defaults);
    expect(out).toBe(params);
  });

  it("pass-through for `status` tool", () => {
    const params = { name: "status", arguments: {} };
    const out = injectCollections(params, defaults);
    expect(out).toBe(params);
  });

  it("pass-through for any future tool name", () => {
    const params = { name: "context_add", arguments: { scope: "/", text: "hi" } };
    const out = injectCollections(params, defaults);
    expect(out).toBe(params);
  });

  it("handles missing arguments object on query", () => {
    const out = injectCollections({ name: "query" }, defaults);
    expect(out.arguments?.collections).toEqual(defaults);
  });
});

// =============================================================================
// enrichInstructions
// =============================================================================

describe("enrichInstructions", () => {
  it("appends footer with two leading newlines when upstream has instructions", () => {
    const out = enrichInstructions("Hello world.", "mia@eury", ["a", "b"]);
    expect(out).toBe(
      "Hello world.\n\n— Served by qmd-remote (host: mia@eury, collections: a,b)",
    );
  });

  it("null collections renders as 'all'", () => {
    const out = enrichInstructions("up", "h", null);
    expect(out).toBe("up\n\n— Served by qmd-remote (host: h, collections: all)");
  });

  it("empty array collections renders as 'all'", () => {
    const out = enrichInstructions("up", "h", []);
    expect(out).toBe("up\n\n— Served by qmd-remote (host: h, collections: all)");
  });

  it("missing upstream instructions → footer-only (no leading newlines)", () => {
    const out = enrichInstructions(undefined, "h", ["a"]);
    expect(out).toBe("— Served by qmd-remote (host: h, collections: a)");
  });

  it("buildProvenanceFooter is the canonical footer string", () => {
    expect(buildProvenanceFooter("h", null)).toBe(
      "— Served by qmd-remote (host: h, collections: all)",
    );
    expect(buildProvenanceFooter("mia@eury", ["x", "y", "z"])).toBe(
      "— Served by qmd-remote (host: mia@eury, collections: x,y,z)",
    );
  });
});
