#!/usr/bin/env bash

set -euo pipefail
source "$(dirname "$0")/_qmd-lib.sh"

qmd_rebuild \
    "mia-code-rispecs-md" \
    "/src/mia-code/rispecs" \
    '**/*.md'
