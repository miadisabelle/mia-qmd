#!/usr/bin/env bash
set -euo pipefail
# Rebuild the llms-txt collection (root-level files only)
bun src/cli/qmd.ts collection remove llms-txt 2>/dev/null || true
bun src/cli/qmd.ts collection add /workspace/repos/jgwill/llms-txt --name llms-txt --mask 'llms-*.{md,txt}'
bun src/cli/qmd.ts embed
