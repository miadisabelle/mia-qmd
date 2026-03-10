# 03 — Workspace Collection Model

> Collection topology mapping the Mia Platform workspace for unified search and discovery.

---

## Desired Outcome

The Mia Platform workspace (`jgwill/workspace` and its sub-repos) is organized into meaningful mia-qmd collections with hierarchical context, enabling companion agents to search across rispecs, llms/ knowledge, .pde/ decompositions, and source documentation as a unified knowledge graph.

## Current Reality

- The workspace spans 10+ repositories under `/workspace/repos/`
- Rich documentation exists: rispecs/ (80+ specs), llms/ (50+ documents), .pde/ (active decompositions)
- No collections are configured — mia-qmd index is empty
- Each knowledge source has distinct semantics and search patterns

## Structural Tension

Knowledge is scattered across a rich topology. The tension between this distributed wisdom and the natural desire for unified discoverability drives the collection model.

---

## Collection Topology

### Recommended Collections

| Collection | Path | Pattern | Context |
|-----------|------|---------|---------|
| `rispecs` | `/workspace/rispecs/` | `**/*.md` | Platform-level RISE specifications for the Mia web shell |
| `llms` | `/workspace/llms/` | `llms-*.{txt,md}` | RISE framework methodology, creative orientation, structural thinking guides |
| `pde` | `/workspace/.pde/` | `**/*.md` | Prompt decomposition results and session work artifacts |
| `mia-code-server-specs` | `/workspace/repos/miadisabelle/mia-code-server/rispecs/` | `**/*.md` | 71 technical specifications across 9 modules for the IDE |
| `mia-qmd-specs` | `/workspace/repos/miadisabelle/mia-qmd/rispecs/` | `**/*.md` | Search engine specifications (this repo) |
| `medicine-wheel` | `/workspace/repos/jgwill/medicine-wheel/rispecs/` | `**/*.md` | Ceremonial infrastructure specifications |
| `workspace-docs` | `/workspace/` | `*.md` | Top-level workspace documents: JGWILL.md, MIAMIETTE.md, TUSHELL.md |

### Context Tree

```
/ (global)
  "Mia Platform creative development workspace — circular development
   using RISE framework, companion agents, and Medicine Wheel methodology"

qmd://rispecs/
  "Platform-level RISE specifications defining the web shell architecture
   that consumes mia-code-server, Miadi, and Tushell"

qmd://llms/
  "Knowledge base documents covering RISE framework, creative orientation,
   structural tension, narrative beats, and development methodology"

qmd://pde/
  "Prompt Decomposition Engine outputs — session intents decomposed into
   Four Directions action stacks"

qmd://mia-code-server-specs/
  "Technical specifications for the mia-code-server VSCode fork —
   71 specs across server core, MCP, Three Universe, agentic IDE,
   narrative intelligence, and more"

qmd://medicine-wheel/
  "Ceremonial infrastructure specifications — ontology, ceremony protocol,
   narrative engine, graph visualization, relational query"
```

---

## Behaviors

### Collection Registration

Collections are registered via CLI commands — never auto-created:

```sh
qmd collection add /workspace/rispecs --name rispecs --mask '**/*.md'
qmd collection add /workspace/llms --name llms --mask 'llms-*.{txt,md}'
qmd collection add /workspace/.pde --name pde --mask '**/*.md'
```

### Context Assignment

Context enriches search results with workspace topology understanding:

```sh
qmd context add qmd://rispecs "Platform-level RISE specifications..."
qmd context add qmd://llms "Knowledge base: RISE framework, creative orientation..."
qmd context add / "Mia Platform creative development workspace..."
```

### Cross-Collection Search

Companion agents search across all collections by default. The `--collection` flag restricts to a single collection when specificity is needed:

```sh
qmd query "structural tension"              # searches everything
qmd query "Three Universe lens" -c rispecs  # specs only
qmd search "ceremony protocol" -c medicine-wheel  # ceremony only
```

### Incremental Updates

When workspace content changes, collections are re-indexed:

```sh
qmd update        # re-index all collections
qmd update --pull # git pull first, then re-index
```

Content-addressable hashing ensures only changed documents are reprocessed.

---

## Integration with Workspace Topology

```
/workspace/ (jgwill/workspace)
  ├── rispecs/          → collection: rispecs
  ├── llms/             → collection: llms
  ├── .pde/             → collection: pde
  ├── *.md              → collection: workspace-docs
  └── repos/
      ├── miadisabelle/
      │   ├── mia-code-server/rispecs/ → collection: mia-code-server-specs
      │   └── mia-qmd/rispecs/        → collection: mia-qmd-specs
      └── jgwill/
          └── medicine-wheel/rispecs/  → collection: medicine-wheel
```

Each collection maps to a meaningful knowledge domain. The collection topology mirrors the workspace topology documented in `JGWILL.md`.

---

**RISE Compliance**: Creative Orientation | Structural Dynamics | Advancing Patterns | Desired Outcomes | Codebase Agnostic
