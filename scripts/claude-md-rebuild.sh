#!/usr/bin/env bash
set -euo pipefail
# Rebuild the CLAUDE-md collection
# Ignore patterns are read from /workspace/.qmdignore
bun src/cli/qmd.ts collection remove CLAUDE-md 2>/dev/null || true
bun src/cli/qmd.ts collection add /workspace --name CLAUDE-md --mask '**/CLAUDE.md'
bun src/cli/qmd.ts embed
