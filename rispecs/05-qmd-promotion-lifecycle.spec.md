# 05 — QMD Promotion Lifecycle

> Promotion is the path by which research becomes stable, retrievable knowledge. QMD does not perform promotion; it indexes the markdown that humans or agents have already promoted into a durable home.

---

## Desired Outcome

Wave-1 deep-search artefacts remain intact as research provenance, while wave-2 documents in `rispecs/` and other curated markdown collections carry the stable decisions that should be routed and retrieved through QMD federation.

## Current Reality

- Wave-1 outputs exist as research provenance rather than implementation-owned documents.
- `rispecs/` already acts as the normative specification layer for mia-qmd.
- `scripts/fn_qmd_client.sh` gives consumers a stable way to query promoted knowledge by persona.
- There is no explicit lifecycle describing when a finding should stay in provenance, become a spec, or become wiki-style knowledge.

## Structural Tension

Research artefacts are rich, exploratory, and often verbose. Implementation and retrieval layers need the opposite: compact, stable documents with clear ownership and purpose. The promotion lifecycle resolves this tension by letting provenance stay raw while promoted documents become progressively more intentional.

---

## Promotion States

| State | Home | Purpose | Mutability |
|------|------|---------|------------|
| Provenance | deep-search artefact folders, loop state, orchestration outputs | Preserve original research and reasoning trail | Append-only or tiny handoff note only |
| Distillation Note | compact markdown note near the implementation layer | Record what was adopted, what stayed ambiguous, and where the provenance lives | Editable |
| Normative Spec | `rispecs/*.spec.md` | Define required behavior, ontology, and boundaries | Editable, authoritative |
| Wiki Knowledge | concept-oriented markdown in indexed collections | Explain terms, relationships, examples, and working vocabulary | Editable, explanatory |
| Indexed View | per-persona QMD index and context tree | Make promoted documents semantically retrievable | Rebuilt projection, never authoritative |

---

## Behaviors

### Promotion Is Explicit

- A document is promoted only when someone authors it into a durable home such as `rispecs/` or a curated knowledge collection.
- Re-indexing is downstream of promotion, not the promotion act itself.
- The federation router never upgrades research into specs; it only routes queries to what already exists.

### Provenance Stays Upstream

- Wave-1 deep-search artefacts stay in their artefact folder as research provenance, not as the implementation home.
- Later specs must not rewrite the provenance so it appears to have made decisions it did not make.
- If provenance is unavailable in the current checkout, the ambiguity is recorded in a short note rather than guessed away.

### Promotion Targets Are Chosen by Function

- **Normative behavior** goes to `rispecs/`.
- **Conceptual or explanatory knowledge** goes to wiki-style markdown.
- **Unresolved ambiguity** goes to a compact handoff or ambiguity note.

### Retrieval Aligns to Existing Federation

- `qmd_query` is the default discovery path for promoted knowledge.
- `qmd_get` and `qmd_multi_get` provide exact recall once the relevant document is known.
- Persona routing stays in `scripts/fn_qmd_client.sh`; no additional wrapper is required for promotion-aware retrieval.

---

## Promotion Checks

Before promoting a research finding:

1. Decide whether the result is **normative**, **conceptual**, or still **provisional**.
2. Preserve a backlink to provenance by direct path when available, or by an ambiguity note when it is not.
3. Place the promoted document in a collection that can already be indexed by the existing QMD workflow.

---

## Integration with Existing Specifications

- Extends `04-multi-persona-federation` by defining what kinds of documents the federation is expected to route.
- Complements `03-workspace-collection-model` by distinguishing authoring homes from indexed projections.
- Leads into `06-wiki-knowledge-handling`, which defines the document shape for promoted conceptual knowledge.

---

**RISE Compliance**: Creative Orientation | Structural Dynamics | Advancing Patterns | Desired Outcomes | Codebase Agnostic
