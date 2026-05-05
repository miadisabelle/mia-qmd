/**
 * Append a provenance footer to the upstream initialize response.
 *
 * Format (exact, per rispec 07):
 *   \n\n— Served by qmd-remote (host: <HOST>, collections: <CSV-or-"all">)
 *
 * If the remote returned no instructions, the footer is emitted without the
 * leading blank line. If `collections` is null (no injection configured) the
 * footer reads `collections: all`.
 *
 * Refs miadisabelle/mia-qmd#10 (Wave 1, rispec 07).
 */

export function buildProvenanceFooter(host: string, collections: string[] | null): string {
  const csv = collections && collections.length > 0 ? collections.join(",") : "all";
  return `— Served by qmd-remote (host: ${host}, collections: ${csv})`;
}

export function enrichInstructions(
  upstreamInstructions: string | undefined,
  host: string,
  collections: string[] | null,
): string {
  const footer = buildProvenanceFooter(host, collections);
  if (!upstreamInstructions) return footer;
  return `${upstreamInstructions}\n\n${footer}`;
}
