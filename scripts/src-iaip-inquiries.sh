#!/usr/bin/env bash
set -euo pipefail
# Rebuild the IAIP artefacts collection
# Ignore patterns are read from /workspace/.qmdignore
bun src/cli/qmd.ts collection remove iaip-artefacts-md 2>/dev/null || true
bun src/cli/qmd.ts collection add /a/src/IAIP/prototypes/artefacts --name iaip-artefacts-md --mask '**/.md'
bun src/cli/qmd.ts embed
