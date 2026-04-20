#!/usr/bin/env bash
# Rebuild the tushellplatform RISE framework specs collection.
# Ignore patterns read from /src/Miadi-18/rispecs/.qmdignore (if present).
set -euo pipefail
source "$(dirname "$0")/_qmd-lib.sh"

qmd_rebuild \
    "miadi-md" \
    "/src/Miadi/rispecs" \
    '**/*.md'
