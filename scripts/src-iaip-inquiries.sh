#!/usr/bin/env bash
set -euo pipefail
# Rebuild the IAIP artefacts collection
# Ignore patterns are read from /src/IAIP/prototypes/artefacts/.qmdignore
QMD_COLLECTION_PATH="/src/IAIP/prototypes/artefacts"
OMD_COLLECTION_NAME="iaip-artefacts-md"
QMD_MASK='*.md'
QMD_IGNORE_PATH="/src/IAIP/prototypes/artefacts/.qmdignore"
if [ ! -e "/src/IAIP/prototypes/artefacts/.qmdignore" ];then
    echo "__.md" 
bun src/cli/qmd.ts collection remove iaip-artefacts-md 2>/dev/null || true
bun src/cli/qmd.ts collection add $QMD_COLLECTION_PATH --name $OMD_COLLECTION_NAME --mask "'"$QMD_MASK"'"
bun src/cli/qmd.ts embed
