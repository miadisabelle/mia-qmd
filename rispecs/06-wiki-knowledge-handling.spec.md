# 06 — Wiki-Style Knowledge Handling

> Wiki-style knowledge in mia-qmd is concept-first markdown authored for semantic retrieval. It is not raw transcript storage and it is not a substitute for specs; it is the explanatory layer between provenance and implementation.

---

## Desired Outcome

A persona can ask QMD for a concept, term, protocol, or relationship and retrieve compact pages that explain the idea, name its aliases, point to the governing specs, and preserve links back to provenance when needed.

## Current Reality

- QMD already indexes markdown well and enriches results with collection and path context.
- `rispecs/` defines normative behavior, but conceptual knowledge is still spread across research notes, `llms-*` texts, and ad hoc markdown.
- There is no shared document shape for long-lived wiki-style knowledge pages that should retrieve cleanly via `qmd_query`.

## Structural Tension

Semantic search is strongest when the indexed documents have stable conceptual boundaries. Research notes are often too diffuse, while specs are intentionally normative. Wiki-style handling resolves this by giving concepts a compact explanatory home without collapsing them into either raw provenance or implementation requirements.

---

## Document Shape

Each wiki-style page should prefer:

- **One concept per page** with a stable title.
- **A summary-first opening** that defines the concept in plain language.
- **Aliases or neighboring terms** near the top so semantic and keyword retrieval converge.
- **Related specs** pointing at the normative home.
- **Provenance links** when the concept was promoted from a research artefact.

Recommended section pattern:

```markdown
# Canonical Concept Name

Short definition paragraph.

## Aliases

## Meaning

## Boundaries

## Related Specs

## Provenance
```

---

## Behaviors

### Concepts Stay Compact

- Prefer short, focused pages over long essays so QMD chunking keeps the core meaning intact.
- Split overloaded topics into multiple pages instead of forcing one document to answer unrelated questions.
- Keep filenames and top-level headings stable so docids and backlinks remain meaningful across edits.

### Wiki Pages Are Explanatory, Not Normative

- A wiki page explains *what a thing is* and *how it relates*.
- A spec defines *what must happen*.
- When a wiki page starts making requirements, those requirements should move into `rispecs/` with the wiki page linking outward.

### Retrieval Uses Existing QMD Semantics

- `qmd_query` is the preferred entrypoint for concept discovery.
- `qmd_search` is useful when the caller knows an exact term or alias.
- `qmd_get` is used once the page path or `#docid` is known.
- Collection and path context should carry domain cues rather than duplicating the page body.

### Federation Does Not Rewrite Concepts

- Persona routing changes which curated index is searched, not the meaning of a page.
- Different personas may curate the same concept differently by selection and context, but the router itself remains content-agnostic.

---

## Non-Goals

- Storing raw transcripts or full session logs as if they were wiki pages.
- Replacing `rispecs/` as the normative layer.
- Introducing a new storage engine or wrapper beyond the existing QMD workflow.

---

## Integration with Existing Specifications

- Depends on `05-qmd-promotion-lifecycle` for the transition from research to curated concept pages.
- Complements `04-multi-persona-federation` by clarifying what kinds of documents `qmd_query` is expected to surface.
- Reuses `03-workspace-collection-model` for where these pages live and how they are contextualized.

---

**RISE Compliance**: Creative Orientation | Structural Dynamics | Advancing Patterns | Desired Outcomes | Codebase Agnostic
