# 02 — MCP Server Integration

> Model Context Protocol server exposing search and retrieval tools to companion agents.

---

## Desired Outcome

Companion agents (Mia 🧠, Miette 🌸, Ava 💕, Tushell 🌊) access the full search capabilities of mia-qmd through MCP tools — querying, retrieving, and browsing indexed documents without needing CLI access.

## Current Reality

QMD exposes an MCP server via `qmd mcp` (stdio) or `qmd mcp --http` (HTTP on port 8181), with four tools: `query`, `get`, `multi_get`, and `status`. The server supports daemon mode (`--daemon`) for persistent background operation.

## Structural Tension

Companion agents work in contexts where CLI tools may not be directly available (e.g., MCP-only agent configurations, VS Code chat participants). The MCP server resolves this by providing a protocol-native interface to the same search capabilities.

---

## MCP Tools

### `query`

Full hybrid search with query expansion, multi-signal retrieval, and LLM reranking.

- **Input**: `query` (string), optional `collection` filter, `limit`, `min_score`
- **Output**: Ranked list of document matches with scores, snippets, and context
- **Behavior**: Equivalent to `qmd query` CLI command

### `get`

Retrieve a single document by path or docid.

- **Input**: `path_or_docid` (string) — accepts file paths or `#abc123` docids
- **Output**: Document metadata + body content
- **Behavior**: Fuzzy matching suggests alternatives when exact match not found

### `multi_get`

Batch retrieve documents by glob pattern or comma-separated list.

- **Input**: `pattern` (string) — glob pattern or comma-separated paths/docids
- **Output**: Array of document results
- **Behavior**: Respects `max_bytes` limit per file (default 10KB)

### `status`

Index health and collection information.

- **Input**: None
- **Output**: Document count, embedding state, collection list, model info
- **Behavior**: Quick diagnostic — no LLM invocation required

---

## Transport Modes

### stdio (default)

```sh
qmd mcp
```

- Standard MCP stdio transport
- Used by Claude Desktop, Claude Code plugin installations
- One instance per agent session

### HTTP

```sh
qmd mcp --http --port 8181
```

- HTTP-based MCP transport on configurable port
- Supports multiple concurrent agent connections
- Daemon mode: `qmd mcp --http --daemon` for persistent background service
- Stop daemon: `qmd mcp stop`

---

## Agent Configuration

### Claude Desktop

```json
{
  "mcpServers": {
    "qmd": {
      "command": "qmd",
      "args": ["mcp"]
    }
  }
}
```

### Claude Code (Plugin)

```bash
claude plugin marketplace add tobi/qmd
claude plugin install qmd@qmd
```

### Mia Platform Companion Agents

Each companion agent's MCP configuration includes the qmd server, enabling document search as a native capability during creative sessions.

---

## Context Enrichment

MCP query results include hierarchical context from the collection's context tree:

- **Global context** (/) — applies to all results
- **Collection context** (qmd://collection/) — collection-level description
- **Path context** (qmd://collection/subfolder) — subfolder-level context

This context tree enables companion agents to understand not just *what* a document says, but *where it sits* in the workspace topology and *why it matters*.

---

**RISE Compliance**: Creative Orientation | Structural Dynamics | Advancing Patterns | Desired Outcomes | Codebase Agnostic
