#!/usr/bin/env bash
# _qmd-lib.sh — shared helpers for QMD collection rebuild scripts.
# Source me, don't execute me.
#
# Usage in a rebuild script:
#   source "$(dirname "$0")/_qmd-lib.sh"
#   qmd_rebuild <name> <path> <mask>          # rebuild one collection
#   qmd_rebuild_many                          # rebuild every queued collection, embed once
#
# The "queue" form lets a single script register multiple collections and
# defer the (expensive) embed step until the end.

set -euo pipefail

QMD_CLI=("bun" "src/cli/qmd.ts")

# Internal queue (parallel arrays).
_QMD_NAMES=()
_QMD_PATHS=()
_QMD_MASKS=()

# qmd_queue NAME PATH MASK
qmd_queue() {
    _QMD_NAMES+=("$1")
    _QMD_PATHS+=("$2")
    _QMD_MASKS+=("$3")
}

# qmd_add NAME PATH MASK  — remove-then-add a single collection (no embed)
qmd_add() {
    local name="$1" path="$2" mask="$3"
    if [ ! -e "$path" ]; then
        echo "⚠️  qmd_add: path does not exist: $path — skipping '$name'" >&2
        return 0
    fi
    "${QMD_CLI[@]}" collection remove "$name" 2>/dev/null || true
    "${QMD_CLI[@]}" collection add "$path" --name "$name" --mask "$mask"
}

# qmd_embed — single embed pass for all pending collections
qmd_embed() {
    "${QMD_CLI[@]}" embed
}

# qmd_rebuild NAME PATH MASK  — add one collection and immediately embed
qmd_rebuild() {
    qmd_add "$1" "$2" "$3"
    qmd_embed
}

# qmd_rebuild_many — drain the queue, then embed once
qmd_rebuild_many() {
    local i
    for i in "${!_QMD_NAMES[@]}"; do
        qmd_add "${_QMD_NAMES[$i]}" "${_QMD_PATHS[$i]}" "${_QMD_MASKS[$i]}"
    done
    qmd_embed
    _QMD_NAMES=(); _QMD_PATHS=(); _QMD_MASKS=()
}
