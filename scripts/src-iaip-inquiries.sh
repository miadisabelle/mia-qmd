#!/usr/bin/env bash
# Rebuild the IAIP artefacts collection.
# Seeds <path>/.qmdignore with patterns that crash qmd's handelize() —
# e.g. `__.md` filenames that normalize to an empty slug.
set -euo pipefail
source "$(dirname "$0")/_qmd-lib.sh"

IAIP_PATH="/src/IAIP/prototypes/artefacts"

qmd_ensure_ignore "$IAIP_PATH" \
    '__.md' \
    '**/__.md'

qmd_rebuild \
    "iaip-artefacts-md" \
    "$IAIP_PATH" \
    '**/*.md'
