#!/usr/bin/env bash
set -euo pipefail
# Rebuild the /workspace/repos/miadisabelle/workspace-openclaw collection
# Ignore patterns are read from /workspace/repos/miadisabelle/workspace-openclaw/.qmdignore
bun src/cli/qmd.ts collection remove workspace-openclaw 2>/dev/null || true
bun src/cli/qmd.ts collection add /workspace/repos/miadisabelle/workspace-openclaw --name workspace-openclaw --mask '**/*.md'
bun src/cli/qmd.ts embed

