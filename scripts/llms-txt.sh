#!/usr/bin/env bash
# Rebuild the llms-txt collection (root-level llms-*.{md,txt} files).
set -euo pipefail
source "$(dirname "$0")/_qmd-lib.sh"

qmd_rebuild "llms-txt" "/workspace/repos/jgwill/llms-txt" 'llms-*.{md,txt}'
