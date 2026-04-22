#!/usr/bin/env bash

set -euo pipefail
source "$(dirname "$0")/_qmd-lib.sh"

qmd_rebuild \
    "pde-miadi-md" \
    "/src/Miadi/.pde" \
    '**/*.md'
