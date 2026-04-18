#!/usr/bin/env bash
# Rebuild the IAIP artefacts collection.
# Ignore patterns read from /src/IAIP/prototypes/artefacts/.qmdignore (if present).
set -euo pipefail
source "$(dirname "$0")/_qmd-lib.sh"

qmd_rebuild \
    "iaip-artefacts-md" \
    "/src/IAIP/prototypes/artefacts" \
    '**/*.md'
