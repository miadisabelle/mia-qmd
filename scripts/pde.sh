#!/usr/bin/env bash
set -euo pipefail
# Rebuild the dotpde collection
# Ignore patterns are read from /workspace/.qmdignore
QMD_COLLECTION_PATH="/workspace"
OMD_COLLECTION_NAME="dotpde"
QMD_MASK='**/.pde/*.md' # DONT USE THIS here, add it to the CLI, masking and shitty encapsulation that I dont know about...
QMD_IGNORE_PATH="$QMD_COLLECTION_PATH/.qmdignore"
if [ ! -e "$QMD_IGNORE_PATH" ];then
    echo "__.md" 
fi

bun src/cli/qmd.ts collection remove $OMD_COLLECTION_NAME 2>/dev/null || true
bun src/cli/qmd.ts collection add $QMD_COLLECTION_PATH --name $OMD_COLLECTION_NAME --mask '**/.pde'
bun src/cli/qmd.ts embed
