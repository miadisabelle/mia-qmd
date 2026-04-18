#!/usr/bin/env bash
# Rebuild the GUILLAUME-md collection (every GUILLAUME.md under /workspace).
set -euo pipefail
source "$(dirname "$0")/_qmd-lib.sh"

qmd_rebuild "GUILLAUME-md" "/workspace" '**/GUILLAUME.md'
