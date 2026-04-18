#!/usr/bin/env bash
# Rebuild the rispecs collection (any rispecs/ folder anywhere under /workspace).
set -euo pipefail
source "$(dirname "$0")/_qmd-lib.sh"

qmd_rebuild "rispecs" "/workspace" '**/rispecs/**/*.md'
