#!/usr/bin/env bash
set -euo pipefail
# Rebuild the AGENTS-md collection
# Ignore patterns are read from /workspace/.qmdignore
bun src/cli/qmd.ts collection remove AGENTS-md 2>/dev/null || true
bun src/cli/qmd.ts collection add /workspace --name AGENTS-md --mask '**/AGENTS.md'
bun src/cli/qmd.ts embed
