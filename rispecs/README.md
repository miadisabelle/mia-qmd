# RISE Specifications — mia-qmd

> On-device hybrid search engine for the Mia Platform creative workspace.

**Version**: 0.1.0
**Framework**: RISE v1.2 (Reverse-engineer → Intent-extract → Specify → Export)
**Date**: 2026-03-10
**PDE Reference**: `.pde/aeed00b4-5293-4ca6-bb53-c8c2b33d230e.md`
**Upstream**: Fork of [@tobilu/qmd](https://github.com/tobi/qmd) v2.0.0

---

## Vision

**mia-qmd** is the search and indexing layer for the Mia Platform creative workspace. It enables companion agents (Mia 🧠, Miette 🌸, Ava 💕, Tushell 🌊) and human creators to find, retrieve, and contextually search documents across the entire workspace topology — rispecs, llms/ knowledge base, .pde/ decompositions, source code, and narrative content.

### Desired Outcome

Any agent or human in the Mia Platform can search the complete workspace knowledge graph using natural language, with results enriched by hierarchical context and ranked by a local LLM — all on-device, no cloud dependency.

### Current Reality

- QMD v2.0.0 provides BM25 + vector + LLM reranking search with MCP server
- The workspace has rich documentation scattered across 10+ repos, rispecs/, llms/, .pde/
- No unified search layer connects these knowledge sources to companion agents

### Structural Tension

Rich knowledge exists across the workspace topology without a unified discovery layer. mia-qmd naturally resolves this tension — the search engine already works, it needs only to be mapped to the workspace's collection topology and exposed to companion agents via MCP.

---

## Specification Index

| # | Spec | Description |
|---|------|-------------|
| 01 | [01-search-engine-core.spec.md](./01-search-engine-core.spec.md) | Hybrid search architecture: BM25 + vector + LLM reranking |
| 02 | [02-mcp-server-integration.spec.md](./02-mcp-server-integration.spec.md) | MCP tools for companion agent integration |
| 03 | [03-workspace-collection-model.spec.md](./03-workspace-collection-model.spec.md) | Collection topology mapping the Mia Platform workspace |
| 04 | [04-multi-persona-federation.spec.md](./04-multi-persona-federation.spec.md) | Per-persona containerized indexes addressable as a routing ontology |

---

## Dependency Graph

```
mia-qmd (THIS — search/indexing layer)
  ├── upstream: @tobilu/qmd v2.0.0 (fork base)
  │     └── SQLite FTS5 + sqlite-vec + node-llama-cpp
  ├── federation: Multi-Persona (spec 04)
  │     ├── jgi-qmd / mia-qmd / ava-qmd / tushell-qmd containers
  │     └── scripts/fn_qmd_client.sh — query router (bash)
  ├── consumed by: Mia Platform web shell (jgwill/workspace rispecs/)
  │     └── Companion agents use MCP tools for document retrieval
  ├── indexes: workspace topology (per-persona curation)
  │     ├── rispecs/ across all repos
  │     ├── llms/ knowledge base
  │     ├── .pde/ decompositions
  │     └── source code and documentation
  └── integrates with: mia-code-server (IDE search)
        └── repos/miadisabelle/mia-code-server/
```

**Key principle**: mia-qmd is a service layer — it indexes and searches but does not modify content. Companion agents query it; they do not write through it.

---

## Cross-Cutting Concerns

All specs follow:
- **RISE Framework** v1.2 — Creative Orientation, Structural Tension, Advancing Patterns
- **SpecLang Syntax** — Behavior sections, backtick cross-references
- **On-Device** — All search, embedding, and reranking runs locally via node-llama-cpp
- **Upstream Compatibility** — Specifications extend @tobilu/qmd, they do not diverge from its core architecture

---

**RISE Compliance**: Creative Orientation | Structural Dynamics | Advancing Patterns | Desired Outcomes | Codebase Agnostic
