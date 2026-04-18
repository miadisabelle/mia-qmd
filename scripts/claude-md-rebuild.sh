#!/usr/bin/env bash
# Rebuild the CLAUDE-md collection (every CLAUDE.md under /workspace).
set -euo pipefail
source "$(dirname "$0")/_qmd-lib.sh"

qmd_rebuild "CLAUDE-md" "/workspace" '**/CLAUDE.md'
