/**
 * Wire-level rewrite of `tools/call` params for the `query` tool.
 *
 * Truth table (rispec 07 — Default-Collection Injection):
 *   defaults === null            → no rewrite (any tool)
 *   tool !== "query"             → pass-through
 *   args.collections === ["*"]   → strip `collections` key (search all)
 *   args.collections missing     → fill with defaults
 *   args.collections === []      → fill with defaults
 *   args.collections non-empty   → unchanged
 *
 * No Zod, no schema validation — surgical JSON-object rewrite only.
 *
 * Refs miadisabelle/mia-qmd#10 (Wave 1, rispec 07).
 */

export type CallToolParams = {
  name: string;
  arguments?: Record<string, unknown>;
  // Forward-compat: meta + other fields preserved untouched.
  [k: string]: unknown;
};

export function injectCollections(
  params: CallToolParams,
  defaults: string[] | null,
): CallToolParams {
  if (defaults === null) return params;
  if (params.name !== "query") return params;

  const args = (params.arguments && typeof params.arguments === "object")
    ? { ...params.arguments }
    : {};

  const cur = args.collections;

  // Override sentinel: ["*"] → search all, strip the key.
  if (Array.isArray(cur) && cur.length === 1 && cur[0] === "*") {
    delete args.collections;
    return { ...params, arguments: args };
  }

  // Missing or empty → fill with defaults.
  const missing = cur === undefined;
  const empty = Array.isArray(cur) && cur.length === 0;
  if (missing || empty) {
    args.collections = [...defaults];
    return { ...params, arguments: args };
  }

  // Explicit non-empty → unchanged.
  return params;
}
