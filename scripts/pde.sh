#!/usr/bin/env bash
# Rebuild the dotpde collection (every .md file at any depth inside any .pde/ folder).
set -euo pipefail
source "$(dirname "$0")/_qmd-lib.sh"

qmd_rebuild "dotpde" "/workspace" '**/.pde/**/*.md'
