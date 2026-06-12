#!/usr/bin/env bash
# qmd-remote-client.sh - client-side setup helpers for qmd mcp-remote.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd -P)"
CONFIG_PATH="$REPO_ROOT/etc/mcp-config-qmd-remote-eury.json"
SERVER_NAME="qmd-remote"
TRUSTED_FOLDERS="${HOME}/.gemini/trustedFolders.json"
GEMINI_SETTINGS="${HOME}/.gemini/settings.json"

usage() {
    cat <<'EOF'
Usage:
  scripts/qmd-remote-client.sh [--config PATH] [--server NAME] [--repo PATH] <action>

Actions:
  probe             Validate local config and print client setup status.
  claude-add-json   Run: claude mcp add-json <server> '<server-json>'.
  gemini-add-json   Merge the server into ~/.gemini/settings.json.
  gemini-trust      Add this repo to ~/.gemini/trustedFolders.json as TRUST_FOLDER.
  gemini-list       Run: gemini -d mcp list from the trusted repo folder.

Notes:
  - The shared config must contain .mcpServers["qmd-remote"].
  - gemini-add-json and gemini-trust keep timestamped backups before writing.
  - Gemini CLI marks stdio MCP servers Disconnected when the current folder is
    not trusted. gemini-trust updates only this repo entry and keeps a backup.
EOF
}

die() {
    printf 'qmd-remote-client: %s\n' "$*" >&2
    exit 1
}

need_cmd() {
    command -v "$1" >/dev/null 2>&1 || die "missing required command: $1"
}

server_json() {
    need_cmd jq
    [ -f "$CONFIG_PATH" ] || die "config not found: $CONFIG_PATH"
    jq -ce --arg name "$SERVER_NAME" '.mcpServers[$name]' "$CONFIG_PATH" \
        || die "missing .mcpServers[\"$SERVER_NAME\"] in $CONFIG_PATH"
}

canonical_dir() {
    [ -d "$1" ] || die "directory not found: $1"
    (cd "$1" && pwd -P)
}

probe() {
    local json command_value
    json="$(server_json)"
    command_value="$(printf '%s' "$json" | jq -r '.command // ""')"

    printf 'Config: %s\n' "$CONFIG_PATH"
    printf 'Server: %s\n' "$SERVER_NAME"
    printf 'Repo:   %s\n' "$REPO_ROOT"
    printf 'MCP:    %s\n' "$json"

    if [ -n "$command_value" ] && command -v "$command_value" >/dev/null 2>&1; then
        printf 'Command available: %s\n' "$command_value"
    elif [ -n "$command_value" ]; then
        printf 'Command missing from PATH: %s\n' "$command_value"
    fi

    if command -v claude >/dev/null 2>&1; then
        printf 'Claude Code: available\n'
    else
        printf 'Claude Code: not found in PATH\n'
    fi

    if command -v gemini >/dev/null 2>&1; then
        printf 'Gemini CLI: available\n'
    else
        printf 'Gemini CLI: not found in PATH\n'
    fi

    if [ -f "$GEMINI_SETTINGS" ] \
        && jq -e --arg name "$SERVER_NAME" '.mcpServers[$name]' "$GEMINI_SETTINGS" >/dev/null 2>&1; then
        printf 'Gemini MCP config: present\n'
    else
        printf 'Gemini MCP config: missing\n'
    fi

    if [ -f "$TRUSTED_FOLDERS" ] \
        && jq -e --arg repo "$REPO_ROOT" '.[$repo] == "TRUST_FOLDER"' "$TRUSTED_FOLDERS" >/dev/null 2>&1; then
        printf 'Gemini trust: TRUST_FOLDER\n'
    else
        printf 'Gemini trust: not trusted\n'
    fi
}

claude_add_json() {
    need_cmd claude
    local json
    json="$(server_json)"
    claude mcp add-json "$SERVER_NAME" "$json"
}

gemini_add_json() {
    need_cmd jq
    local dir json tmp backup
    dir="$(dirname "$GEMINI_SETTINGS")"
    mkdir -p "$dir"

    if [ ! -f "$GEMINI_SETTINGS" ]; then
        printf '{}\n' > "$GEMINI_SETTINGS"
    fi
    jq -e 'type == "object"' "$GEMINI_SETTINGS" >/dev/null \
        || die "Gemini settings file is not a JSON object: $GEMINI_SETTINGS"

    json="$(server_json)"
    tmp="$(mktemp "${GEMINI_SETTINGS}.tmp.XXXXXX")"
    jq --arg name "$SERVER_NAME" --argjson server "$json" \
        '.mcpServers = ((.mcpServers // {}) + {($name): $server})' \
        "$GEMINI_SETTINGS" > "$tmp"

    if cmp -s "$GEMINI_SETTINGS" "$tmp"; then
        rm -f "$tmp"
        printf 'Already configured for Gemini: %s\n' "$SERVER_NAME"
        return 0
    fi

    backup="${GEMINI_SETTINGS}.bak.$(date +%Y%m%d%H%M%S)"
    cp -p "$GEMINI_SETTINGS" "$backup"
    mv "$tmp" "$GEMINI_SETTINGS"
    printf 'Configured Gemini MCP server: %s\n' "$SERVER_NAME"
    printf 'Settings: %s\n' "$GEMINI_SETTINGS"
    printf 'Backup:   %s\n' "$backup"
}

gemini_trust() {
    need_cmd jq
    local dir tmp backup
    dir="$(dirname "$TRUSTED_FOLDERS")"
    mkdir -p "$dir"

    if [ ! -f "$TRUSTED_FOLDERS" ]; then
        printf '{}\n' > "$TRUSTED_FOLDERS"
    fi
    jq -e 'type == "object"' "$TRUSTED_FOLDERS" >/dev/null \
        || die "trusted folders file is not a JSON object: $TRUSTED_FOLDERS"

    tmp="$(mktemp "${TRUSTED_FOLDERS}.tmp.XXXXXX")"
    jq --arg repo "$REPO_ROOT" '. + {($repo): "TRUST_FOLDER"}' "$TRUSTED_FOLDERS" > "$tmp"

    if cmp -s "$TRUSTED_FOLDERS" "$tmp"; then
        rm -f "$tmp"
        printf 'Already trusted: %s\n' "$REPO_ROOT"
        return 0
    fi

    backup="${TRUSTED_FOLDERS}.bak.$(date +%Y%m%d%H%M%S)"
    cp -p "$TRUSTED_FOLDERS" "$backup"
    mv "$tmp" "$TRUSTED_FOLDERS"
    printf 'Trusted: %s\n' "$REPO_ROOT"
    printf 'Backup:  %s\n' "$backup"
}

gemini_list() {
    need_cmd gemini
    (cd "$REPO_ROOT" && gemini -d mcp list)
}

while [ "$#" -gt 0 ]; do
    case "$1" in
        --config)
            [ "$#" -ge 2 ] || die "--config requires a path"
            CONFIG_PATH="$2"
            shift 2
            ;;
        --server)
            [ "$#" -ge 2 ] || die "--server requires a name"
            SERVER_NAME="$2"
            shift 2
            ;;
        --repo)
            [ "$#" -ge 2 ] || die "--repo requires a path"
            REPO_ROOT="$(canonical_dir "$2")"
            shift 2
            ;;
        -h|--help|help)
            usage
            exit 0
            ;;
        --)
            shift
            break
            ;;
        -*)
            die "unknown option: $1"
            ;;
        *)
            break
            ;;
    esac
done

ACTION="${1:-}"
[ -n "$ACTION" ] || {
    usage
    exit 2
}

case "$ACTION" in
    probe) probe ;;
    claude-add-json) claude_add_json ;;
    gemini-add-json) gemini_add_json ;;
    gemini-trust) gemini_trust ;;
    gemini-list) gemini_list ;;
    *)
        usage >&2
        die "unknown action: $ACTION"
        ;;
esac
