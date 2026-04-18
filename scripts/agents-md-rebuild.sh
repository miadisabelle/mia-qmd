#!/usr/bin/env bash
# Rebuild the AGENTS-md collection (every AGENTS.md under /workspace).
set -euo pipefail
source "$(dirname "$0")/_qmd-lib.sh"

qmd_rebuild "AGENTS-md" "/workspace" '**/AGENTS.md'
