# 04 — Multi-Persona QMD Federation

> Each companion (Mia 🧠, Miette 🌸, Ava 💕, Tushell 🌊, JGI) operates an isolated QMD index inside their own containerized workspace. A bash client turns these private indexes into addressable endpoints the orchestrator — or any agent — can query by persona name. The federation is what transforms a single search engine into a *routing ontology*.

---

## Desired Outcome

Any consumer — human, companion agent, or higher-order orchestrator — can address an inquiry to a named persona and receive an answer shaped by that persona's curated knowledge. Routing becomes intentional ("ask Mia for structure, Ava for meaning, reconcile"), not accidental. Each persona's index is isolated from the others; fan-out and reconciliation across personas is a first-class capability, not a workaround.

## Current Reality

- `mia-qmd` provides a single-user search engine (specs `01-search-engine-core`, `02-mcp-server-integration`, `03-workspace-collection-model`).
- The host machine has GPU instability that destabilizes long-running QMD processes.
- Four docker user contexts exist (`docker/jgi/`, `docker/mia/`, `docker/ava/`, `docker/tushell/`), each producing a container named `<persona>-qmd` from the root `Dockerfile` which creates the four system users.
- Each persona has curated a distinct indexing recipe via `scripts/src-*.sh` (e.g., `src-mia-code-rispecs.sh`, `src-miadi.sh`, `src-iaip-inquiries.sh`, `src-tushellplatform.sh`, `pde-src-miadi.sh`). Running these inside each container yields four non-overlapping index identities.
- There is no unified client that lets a consumer say "search Ava" vs "search Mia" — each persona must be queried through manual `docker exec` invocations.

## Structural Tension

Isolated persona indexes exist and are rich with distinct knowledge, but they are not *addressable as a set*. The tension between their individual curation (each persona has chosen what belongs in their index) and the natural desire for orchestrated multi-perspective inquiry drives the federation.

When a consumer asks a structural question, Mia's index should answer. When they ask a ceremonial question, Ava's should. When they ask for distilled wisdom, Tushell's should. Without a routing layer, the consumer must know the container topology; with one, they only need to know the persona.

---

## Architecture

```
                    ┌──────────────────────────────┐
                    │   Consumer (agent / human /  │
                    │   orchestrator / MCP client) │
                    └──────────────┬───────────────┘
                                   │  persona-addressed query
                                   ▼
                    ┌──────────────────────────────┐
                    │   scripts/fn_qmd_client.sh   │
                    │   (query router / federation │
                    │    surface — bash functions) │
                    └──────────────┬───────────────┘
                                   │
              ┌────────────────────┼────────────────────┐
              │          │         │         │          │
              ▼          ▼         ▼         ▼          ▼
         ┌────────┐ ┌────────┐ ┌────────┐ ┌──────────┐
         │jgi-qmd │ │mia-qmd │ │ava-qmd │ │tushell-  │
         │        │ │        │ │        │ │   qmd    │
         │ JGI    │ │ Mia 🧠 │ │ Ava 💕 │ │Tushell 🌊│
         │        │ │        │ │        │ │          │
         │ opera- │ │struct- │ │ cere-  │ │ wisdom / │
         │ tions  │ │ ural / │ │ monial │ │ echoes   │
         │ / host │ │ code   │ │        │ │          │
         │ bridge │ │        │ │        │ │          │
         └────┬───┘ └────┬───┘ └────┬───┘ └────┬─────┘
              │          │         │          │
              ▼          ▼         ▼          ▼
         isolated    isolated   isolated    isolated
         QMD index   QMD index  QMD index   QMD index
         (~/.cache/qmd/index.sqlite per user home)
```

Each box is a docker container running as its persona's user. The bash client is the *only* surface a consumer touches; persona selection is positional (`qmd_search mia "..."`), environmental (`QMD_PERSONA=ava`), or fan-out (`qmd_all`).

---

## Behaviors

### Addressability

- Personas are the atomic unit of routing. The set is defined by `$QMD_PERSONAS` (default: `jgi mia ava tushell`).
- A persona name maps deterministically to a container: `<persona>$QMD_CONTAINER_SUFFIX` (default suffix `-qmd`).
- `docker exec` inherits the container's default `USER`, so commands always run as the persona whose index is being queried — the OS-level identity is never spoofed.

### Routing Surface

The federation exposes these functions; each resolves to a `qmd` invocation inside the target persona's container:

| Function | QMD command | Purpose |
|----------|-------------|---------|
| `qmd_search` | `qmd search` | BM25 keyword search against persona's index |
| `qmd_query` | `qmd query` | Hybrid search with expansion + rerank |
| `qmd_vsearch` | `qmd vsearch` | Vector similarity only |
| `qmd_get` | `qmd get` | Retrieve document by path or `#docid` |
| `qmd_multi_get` | `qmd multi-get` | Batch retrieval |
| `qmd_ls` | `qmd ls` | List collections / paths within persona |
| `qmd_status` | `qmd status` | Index health for persona |
| `qmd_collections` | `qmd collection list` | Enumerate persona's collections |
| `qmd_personas` | *(local)* | List personas and container up/down status |
| `qmd_exec` | `qmd <any>` | Escape hatch for uncovered subcommands |
| `qmd_all` | `qmd <sub>` ×N | Fan out one subcommand across all running personas |

### Persona Resolution Modes

Routing ambiguity is resolved by strictness mode, chosen per function based on whether the first positional arg could legitimately be something other than a persona:

- **strict** (`qmd_status`, `qmd_collections`) — first arg must be a valid persona if present. A persona-shaped token that isn't in the valid set is rejected as a typo.
- **query** (`qmd_search`, `qmd_query`, `qmd_vsearch`, `qmd_get`, `qmd_multi_get`) — persona is consumed only when followed by a query argument. Single-arg calls route to the default persona and treat the arg as a query. Typos are only rejected when a trailing query makes intent unambiguous.
- **loose** (`qmd_ls`) — first arg may legitimately be a collection name; the picker consumes it as a persona only if explicitly valid, never errors on mismatch.

The persona-shaped heuristic: a token matching `^[a-z]+$` that isn't in `$QMD_PERSONAS` is treated as a probable typo rather than silently falling through to the default persona.

### Exit Semantics

- `0` — command succeeded (inside container).
- `2` — routing error: unknown persona or persona-shaped typo.
- `3` — target container is not running.
- Other codes are forwarded verbatim from `qmd` / `docker exec`.

### Fan-Out and Reconciliation

`qmd_all <subcommand> <args>` runs the same subcommand against every running persona, emitting `=== <persona> ===` headers so downstream consumers can parse per-persona sections. Reconciliation (merging, deduplication, voting, relevance weighting) is *not* performed by the federation — that belongs to the consuming orchestrator.

### Environment Overrides

| Variable | Default | Purpose |
|----------|---------|---------|
| `QMD_PERSONAS` | `jgi mia ava tushell` | Whitelisted persona set |
| `QMD_PERSONA` | `mia` | Default persona when none specified |
| `QMD_DOCKER` | `docker` | Allows `sudo docker`, a remote host via `docker -H`, or a drop-in shim |
| `QMD_CONTAINER_SUFFIX` | `-qmd` | Container naming convention suffix |

---

## Emergent Capability: Routing Ontology

The federation's value is not the wrapping — it is that persona names become a *typed address space* for knowledge. This enables patterns that were previously implicit:

### Two-Eyed Seeing as Protocol

```sh
qmd_query mia "structural tension in the auth refactor" -n 5
qmd_query ava "what does this refactor mean for us" -n 5
# Consumer reconciles: structure + story → unified understanding
```

What was previously a narrative aspiration (🧠 + 🌸 = structure + story) becomes an executable protocol.

### Persona-Typed Prompts

An orchestrator can compose: *"Ask Tushell for echoes of prior decisions on X, then ask Mia whether the current structure honors them."* The federation makes each of these a concrete function call, not a prompt-engineering hope.

### Fan-Out for Council

```sh
qmd_all query "decolonize software methodology"
```

Each persona responds from their own curated ground. This *is* a multi-agent talking circle at the data layer — each voice distinct, none averaged into consensus prematurely.

### Persona as Curation Signature

Because each persona indexes via their own `scripts/src-*.sh`, the *choice of what to include* is itself a knowledge claim. Asking Mia vs Ava is not just asking different indexes — it is asking different editorial sensibilities about what matters.

---

## Integration with Existing Specifications

- Extends `01-search-engine-core` — each persona runs the full hybrid search stack; the federation does not modify retrieval, only addresses it.
- Complements `02-mcp-server-integration` — a future MCP tool layer can expose each persona as a named MCP resource (`mcp://qmd/mia`, `mcp://qmd/ava`, …), with this bash client as the reference implementation of routing semantics.
- Specializes `03-workspace-collection-model` — each persona curates their own collections via `scripts/src-*.sh`, so the workspace collection model applies *per-persona*, not globally. Collections with the same name in different personas are separate knowledge bodies.

---

## Constraints

- **GPU isolation** — the host GPU is unstable for direct QMD workloads. Containerization is not optional; it is the reason the federation exists at this layer rather than as a multi-index extension to a single QMD process.
- **No cross-container reads** — one persona's container cannot read another's index. All cross-persona queries go through the federation client.
- **Container lifecycle is external** — the federation does not start, stop, build, or configure containers. The `docker/<persona>/` wrappers own that lifecycle.
- **Index curation is sovereign** — each persona decides what to index. The federation surfaces results; it does not mandate content.

---

## Non-Goals

- Cross-persona result reconciliation (orchestrator's responsibility).
- Container orchestration or health management (docker wrappers handle this).
- Authentication or access control between personas (OS user separation is sufficient at this tier).
- Persona-to-persona direct communication (federation is a query surface, not a messaging fabric).

---

**RISE Compliance**: Creative Orientation | Structural Dynamics | Advancing Patterns | Desired Outcomes | Codebase Agnostic
