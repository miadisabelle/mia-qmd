#!/usr/bin/env bash
# Rebuild the /workspace/repos/miadisabelle/mia-awesome-copilot/agents RISE framework specs collection.
# Ignore patterns read from /workspace/repos/miadisabelle/mia-awesome-copilot/agents/.qmdignore (if present).
set -euo pipefail
source "$(dirname "$0")/_qmd-lib.sh"

qmd_rebuild \
    "mia-awesome-copilot-agents-md" \
    "/workspace/repos/miadisabelle/mia-awesome-copilot/agents" \
    '**/*.md'
