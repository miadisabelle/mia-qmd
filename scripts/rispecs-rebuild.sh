#!/usr/bin/env bash
set -euo pipefail
# Rebuild the rispecs collection
# Ignore patterns are read from /workspace/.qmdignore
bun src/cli/qmd.ts collection remove rispecs 2>/dev/null || true
bun src/cli/qmd.ts collection add /workspace --name rispecs --mask '**/rispecs/**/*.md'
bun src/cli/qmd.ts embed
