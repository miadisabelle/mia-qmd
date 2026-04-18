#!/usr/bin/env bash
set -euo pipefail
# Rebuild the tushellplatform RISE framework specs collection
# Ignore patterns are read from /src/tushellplatform/.qmdignore
QMD_COLLECTION_PATH="/src/tushellplatform/rispecs"
OMD_COLLECTION_NAME="tushellplatform-md"
QMD_MASK='*.md'
QMD_IGNORE_PATH="$QMD_COLLECTION_PATH/.qmdignore"
if [ ! -e "$QMD_IGNORE_PATH" ];then
    echo "__.md" 
fi

bun src/cli/qmd.ts collection remove $OMD_COLLECTION_NAME 2>/dev/null || true
bun src/cli/qmd.ts collection add $QMD_COLLECTION_PATH --name $OMD_COLLECTION_NAME --mask "'"$QMD_MASK"'"
bun src/cli/qmd.ts embed
