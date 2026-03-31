#!/usr/bin/env bash
set -euo pipefail
# Rebuild the GUILLAUME-md collection
# Ignore patterns are read from /workspace/.qmdignore
bun src/cli/qmd.ts collection remove GUILLAUME-md 2>/dev/null || true
bun src/cli/qmd.ts collection add /workspace --name GUILLAUME-md --mask '**/GUILLAUME.md'
bun src/cli/qmd.ts embed
