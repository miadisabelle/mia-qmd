#!/usr/bin/env bash
# Rebuild the /workspace/repos/miadisabelle/mia-awesome-copilot/plugins/SKILLS markdown files collection.
set -euo pipefail
source "$(dirname "$0")/_qmd-lib.sh"

qmd_rebuild \
    "mia-awesome-copilot-plugin-skills-md" \
    "/workspace/repos/miadisabelle/mia-awesome-copilot/plugins" \
    '**/skills/**/*.md'
