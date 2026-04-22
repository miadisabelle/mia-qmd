# fn_qmd_client.sh — Multi-persona QMD federation client
#
# Source this file to get bash functions that route `qmd` commands into each
# persona's docker container. Each persona has an isolated QMD index built
# from their own curated sources (see scripts/src-*.sh).
#
#   source scripts/fn_qmd_client.sh
#   qmd_search mia "structural tension"
#   qmd_query ava "ceremony protocol"
#   QMD_PERSONA=tushell qmd_get "#abc123"
#   qmd_personas
#   qmd_exec mia status
#
# Personas: jgi | mia | ava | tushell
# Container naming convention: <persona>-qmd (see docker/<persona>/_env.sh)

# ---- config -----------------------------------------------------------------

: "${QMD_PERSONAS:=jgi mia ava tushell}"
: "${QMD_PERSONA:=mia}"                 # default persona when none given
: "${QMD_DOCKER:=docker}"               # override to e.g. `sudo docker`
: "${QMD_CONTAINER_SUFFIX:=-qmd}"       # container = <persona><suffix>

# ---- internals --------------------------------------------------------------

_qmd_container() { printf '%s%s' "$1" "$QMD_CONTAINER_SUFFIX"; }

_qmd_is_persona() {
    local p
    for p in $QMD_PERSONAS; do [ "$p" = "$1" ] && return 0; done
    return 1
}

# A token is "persona-shaped" if it looks like it was meant as a persona name:
# a single lowercase word, no spaces/slashes/hashes/quotes/hyphens. Used to
# distinguish a typo'd persona from a genuine search term.
_qmd_persona_shaped() {
    case "$1" in
        *[!a-z]*|'') return 1 ;;
        *) return 0 ;;
    esac
}

# Three picker modes populate $_QMD_PICKED (persona) and $_QMD_REST (remaining args).
# Caller pattern: `_qmd_pick_<mode> "$@" || return $?; set -- "${_QMD_REST[@]}"`.

# Strict: $1 must be a valid persona if present. Errors on persona-shaped typo.
# Used by: qmd_status, qmd_collections (first arg is never a query, always a persona).
_qmd_pick_strict() {
    _QMD_PICKED="$QMD_PERSONA"
    _QMD_REST=("$@")
    if [ $# -gt 0 ]; then
        if _qmd_is_persona "$1"; then
            _QMD_PICKED="$1"; shift; _QMD_REST=("$@")
        elif _qmd_persona_shaped "$1"; then
            echo "qmd-client: '$1' is not a valid persona (valid: $QMD_PERSONAS)" >&2
            return 2
        fi
    fi
    return 0
}

# Query: require >=2 args to consume persona; errors on persona-shaped typo only
# when there's a trailing query. Single-arg calls treat $1 as query.
# Used by: qmd_search, qmd_query, qmd_vsearch, qmd_get, qmd_multi_get.
_qmd_pick_query() {
    _QMD_PICKED="$QMD_PERSONA"
    _QMD_REST=("$@")
    if [ $# -ge 2 ]; then
        if _qmd_is_persona "$1"; then
            _QMD_PICKED="$1"; shift; _QMD_REST=("$@")
        elif _qmd_persona_shaped "$1"; then
            echo "qmd-client: '$1' looks like a persona but is not one of: $QMD_PERSONAS" >&2
            echo "qmd-client: quote multi-word queries, or prefix with a valid persona" >&2
            return 2
        fi
    fi
    return 0
}

# Loose: consume valid persona only; never errors (first arg may legitimately
# be a collection name). Used by: qmd_ls.
_qmd_pick_loose() {
    _QMD_PICKED="$QMD_PERSONA"
    _QMD_REST=("$@")
    if [ $# -gt 0 ] && _qmd_is_persona "$1"; then
        _QMD_PICKED="$1"; shift; _QMD_REST=("$@")
    fi
    return 0
}

# Resolve persona from first arg if valid, else use $QMD_PERSONA.
# Echoes: "<persona> <remaining-args-shell-quoted>"
_qmd_resolve() {
    local persona
    if [ $# -gt 0 ] && _qmd_is_persona "$1"; then
        persona="$1"; shift
    else
        persona="$QMD_PERSONA"
    fi
    printf '%s\n' "$persona"
    printf '%s\0' "$@"
}

_qmd_container_running() {
    local name; name="$(_qmd_container "$1")"
    $QMD_DOCKER ps --format '{{.Names}}' 2>/dev/null | grep -Fxq "$name"
}

# Run `qmd <args...>` inside the persona's container as that persona's user.
# `docker exec` inherits the container's default USER, which is the persona.
_qmd_run() {
    local persona="$1"; shift
    if ! _qmd_is_persona "$persona"; then
        echo "qmd-client: unknown persona '$persona' (valid: $QMD_PERSONAS)" >&2
        return 2
    fi
    if ! _qmd_container_running "$persona"; then
        echo "qmd-client: container $(_qmd_container "$persona") is not running" >&2
        return 3
    fi
    local flags=(exec -i)
    [ -t 0 ] && [ -t 1 ] && flags=(exec -it)
    $QMD_DOCKER "${flags[@]}" "$(_qmd_container "$persona")" qmd "$@"
}

# ---- public functions -------------------------------------------------------

# List known personas and container status.
qmd_personas() {
    local p name status
    for p in $QMD_PERSONAS; do
        name="$(_qmd_container "$p")"
        if _qmd_container_running "$p"; then status="up"; else status="down"; fi
        printf '%-10s %-20s %s\n' "$p" "$name" "$status"
    done
}

# Run arbitrary qmd subcommand against a persona:
#   qmd_exec mia status
#   qmd_exec ava collection list
qmd_exec() {
    local persona="$1"; shift || true
    if ! _qmd_is_persona "$persona"; then
        # allow `qmd_exec status` to use default persona
        set -- "$persona" "$@"
        persona="$QMD_PERSONA"
    fi
    _qmd_run "$persona" "$@"
}

# qmd_search [persona] <query...>  — BM25 keyword search
qmd_search() {
    _qmd_pick_query "$@" || return $?
    set -- "${_QMD_REST[@]}"
    _qmd_run "$_QMD_PICKED" search "$@"
}

# qmd_query [persona] <query...>   — Hybrid search w/ expansion + rerank
qmd_query() {
    _qmd_pick_query "$@" || return $?
    set -- "${_QMD_REST[@]}"
    _qmd_run "$_QMD_PICKED" query "$@"
}

# qmd_vsearch [persona] <query...> — Vector similarity only
qmd_vsearch() {
    _qmd_pick_query "$@" || return $?
    set -- "${_QMD_REST[@]}"
    _qmd_run "$_QMD_PICKED" vsearch "$@"
}

# qmd_get [persona] <file|#docid>  — Fetch single document
qmd_get() {
    _qmd_pick_query "$@" || return $?
    set -- "${_QMD_REST[@]}"
    _qmd_run "$_QMD_PICKED" get "$@"
}

# qmd_multi_get [persona] <pattern|csv>
qmd_multi_get() {
    _qmd_pick_query "$@" || return $?
    set -- "${_QMD_REST[@]}"
    _qmd_run "$_QMD_PICKED" multi-get "$@"
}

# qmd_ls [persona] [collection[/path]]
qmd_ls() {
    _qmd_pick_loose "$@" || return $?
    set -- "${_QMD_REST[@]}"
    _qmd_run "$_QMD_PICKED" ls "$@"
}

# qmd_status [persona]
qmd_status() {
    _qmd_pick_strict "$@" || return $?
    set -- "${_QMD_REST[@]}"
    _qmd_run "$_QMD_PICKED" status "$@"
}

# qmd_collections [persona]  — list collections indexed in persona's QMD
qmd_collections() {
    _qmd_pick_strict "$@" || return $?
    set -- "${_QMD_REST[@]}"
    _qmd_run "$_QMD_PICKED" collection list "$@"
}

# Fan-out: run the same search across every running persona, labeled.
# qmd_all <subcommand> <args...>   e.g. qmd_all search "ceremony"
qmd_all() {
    local sub="$1"; shift
    local p
    for p in $QMD_PERSONAS; do
        if _qmd_container_running "$p"; then
            printf '\n=== %s ===\n' "$p"
            _qmd_run "$p" "$sub" "$@"
        fi
    done
}
