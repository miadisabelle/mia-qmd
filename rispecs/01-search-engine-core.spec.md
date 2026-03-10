# 01 — Search Engine Core

> Hybrid search architecture combining BM25, vector similarity, and LLM reranking — all on-device.

---

## Desired Outcome

A search engine that accepts natural language queries and returns the most relevant documents from indexed markdown collections, using three complementary retrieval signals fused via Reciprocal Rank Fusion (RRF) and refined by LLM reranking.

## Current Reality

QMD v2.0.0 implements:
- **SQLite FTS5** for BM25 full-text keyword search
- **sqlite-vec** for vector similarity search using embeddinggemma-300M
- **node-llama-cpp** for embeddings, reranking (Qwen3-Reranker-0.6B), and query expansion (qmd-query-expansion-1.7B)
- **Smart chunking**: 900 tokens/chunk with 15% overlap, markdown heading boundaries
- **Reciprocal Rank Fusion** combining results from multiple retrieval signals

## Structural Tension

Three retrieval methods exist independently. The tension between their individual strengths (keyword precision, semantic understanding, contextual ranking) and the natural desire for unified relevance drives the hybrid architecture.

---

## Architecture

```
User Query
  │
  ├─→ Query Expansion (LLM) ─→ typed sub-queries (lex/vec/hyde)
  │
  ├─→ BM25 Search (FTS5) ───→ keyword-matched results
  │
  ├─→ Vector Search (sqlite-vec) ─→ semantically similar results
  │
  └─→ Reciprocal Rank Fusion ─→ merged candidates
       │
       └─→ LLM Reranking (Qwen3) ─→ final ranked results
```

---

## Behaviors

### Search Modes

- **`search`** — BM25 keyword search only. Fast, no LLM dependency.
- **`vsearch`** — Vector similarity search only. Requires embeddings.
- **`query`** — Full hybrid: query expansion + multi-signal retrieval + RRF + LLM reranking. Recommended for quality.

### Query Expansion

- Accepts a natural language query string
- LLM expands into typed sub-queries: `lex` (keyword), `vec` (semantic), `hyde` (hypothetical document)
- Each sub-query is routed to the appropriate search backend
- Optional `intent` parameter steers expansion toward a domain

### Smart Chunking

- Documents are split into chunks of ~900 tokens
- 15% overlap between adjacent chunks preserves context
- Markdown headings are preferred as chunk boundaries
- Each chunk retains its parent document metadata and hierarchical context

### Document IDs

- Each document has a unique `docid` — first 6 characters of its content hash
- Docids are stable across re-indexing (content-addressable)
- Usable in `get` and `multi-get` commands: `qmd get #abc123`

### SDK Interface

```typescript
const store = await createStore({ dbPath: './index.sqlite' })
const results = await store.search({ query: "authentication flow" })
const doc = await store.get("docs/api.md")
await store.close()
```

---

## Models

| Role | Model | Size | Source |
|------|-------|------|--------|
| Embedding | embeddinggemma-300M | ~300MB | huggingface.co/ggml-org |
| Reranking | Qwen3-Reranker-0.6B | ~600MB | huggingface.co/ggml-org |
| Query Expansion | qmd-query-expansion-1.7B | ~1.7GB | huggingface.co/tobil |

All models run locally via node-llama-cpp GGUF format. No cloud API calls.

---

## Storage

- **Index database**: `~/.cache/qmd/index.sqlite`
- **Schema**: SQLite FTS5 virtual tables + sqlite-vec for vector storage
- **Content-addressable**: Documents tracked by content hash, enabling incremental re-indexing

---

**RISE Compliance**: Creative Orientation | Structural Dynamics | Advancing Patterns | Desired Outcomes | Codebase Agnostic
