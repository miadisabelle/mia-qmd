#!/usr/bin/env bash
# setup-terminator-qmd-handler.sh
#
# Interactive setup for qmd:// URL handler in Terminator.
# Installs the plugin, wrapper script, and config updates.
#
# Usage: ./setup-terminator-qmd-handler.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERMINATOR_PLUGINS="${HOME}/.config/terminator/plugins"
TERMINATOR_CONFIG="${HOME}/.config/terminator/config"
BIN_DIR="${HOME}/bin"

# Color codes
BOLD='\033[1m'
GREEN='\033[32m'
BLUE='\033[34m'
RESET='\033[0m'

log_info() {
  echo -e "${BLUE}ℹ${RESET} $*"
}

log_ok() {
  echo -e "${GREEN}✓${RESET} $*"
}

log_header() {
  echo -e "\n${BOLD}$*${RESET}"
}

confirm() {
  local prompt="$1"
  local response
  read -p "$(echo -e ${BLUE})→$(echo -e ${RESET}) $prompt (y/n): " response
  [[ "$response" == "y" || "$response" == "Y" ]]
}

# ─────────────────────────────────────────────────────────────────

log_header "🧠 Terminator qmd:// Handler Setup"

# Check Terminator
if ! command -v terminator &>/dev/null; then
  echo -e "${RED}✗${RESET} Terminator not found. Install it first: apt install terminator"
  exit 1
fi
log_ok "Terminator $(terminator --version 2>&1 | head -1 | awk '{print $NF}')"

# Show what will happen
log_header "What this script does:"
echo "  • Copies ~/bin/qmd-open wrapper script to $BIN_DIR/"
echo "  • Copies qmd_url_handler.py plugin to $TERMINATOR_PLUGINS/"
echo "  • Updates ~/.config/terminator/config to enable the plugin"
echo "  • Validates the setup"

echo ""
log_info "Files to be installed:"
echo "  • $SCRIPT_DIR/qmd-open → $BIN_DIR/qmd-open"
echo "  • $SCRIPT_DIR/qmd_url_handler.py → $TERMINATOR_PLUGINS/qmd_url_handler.py"
echo "  • Config update: ~/.config/terminator/config"

echo ""
log_info "After setup:"
echo "  • Restart Terminator (close all windows, reopen)"
echo "  • Run: scripts/qmd_remote.sh \"your query\""
echo "  • Ctrl-click any qmd:// URI to fetch and open"

# Confirm
echo ""
if ! confirm "Proceed with installation?"; then
  echo "Aborted."
  exit 0
fi

# ─────────────────────────────────────────────────────────────────

log_header "Installing..."

# Create directories
mkdir -p "$BIN_DIR" "$TERMINATOR_PLUGINS"
log_ok "Directories ready: $BIN_DIR, $TERMINATOR_PLUGINS"

# Install wrapper
cp "$SCRIPT_DIR/qmd-open" "$BIN_DIR/qmd-open"
chmod +x "$BIN_DIR/qmd-open"
log_ok "Wrapper installed: $BIN_DIR/qmd-open"

# Install plugin
cp "$SCRIPT_DIR/qmd_url_handler.py" "$TERMINATOR_PLUGINS/qmd_url_handler.py"
log_ok "Plugin installed: $TERMINATOR_PLUGINS/qmd_url_handler.py"

# Update Terminator config
if [ ! -f "$TERMINATOR_CONFIG" ]; then
  log_info "Creating $TERMINATOR_CONFIG..."
  mkdir -p "$(dirname "$TERMINATOR_CONFIG")"
  cat > "$TERMINATOR_CONFIG" <<EOF
[global_config]
  focus = mouse
  enabled_plugins = QmdURLHandler

[keybindings]

[profiles]
  [[default]]

[layouts]
  [[default]]
    [[[window0]]]
      type = Window
      parent = ""
    [[[child1]]]
      type = Terminal
      parent = window0
      profile = default

[plugins]
  [[QmdURLHandler]]
EOF
  log_ok "Created $TERMINATOR_CONFIG"
else
  # Update existing config
  if grep -q "^[[:space:]]*enabled_plugins[[:space:]]*=" "$TERMINATOR_CONFIG"; then
    # enabled_plugins line exists; add QmdURLHandler if not present
    if ! grep -q "QmdURLHandler" "$TERMINATOR_CONFIG"; then
      # Add to the beginning of the list
      sed -i 's/\(enabled_plugins[[:space:]]*=[[:space:]]*\)/\1QmdURLHandler, /' "$TERMINATOR_CONFIG"
      # Clean up potential double commas or trailing commas
      sed -i 's/, , /, /g; s/, ,/, /g; s/,[[:space:]]*$//' "$TERMINATOR_CONFIG"
      log_ok "Updated enabled_plugins in $TERMINATOR_CONFIG"
    else
      log_ok "QmdURLHandler already in enabled_plugins"
    fi
  else
    # Add enabled_plugins line after [global_config]
    sed -i '/\[global_config\]/a\  enabled_plugins = QmdURLHandler' "$TERMINATOR_CONFIG"
    log_ok "Added enabled_plugins to $TERMINATOR_CONFIG"
  fi

  # Add [plugins] section if missing
  if ! grep -q "^\[plugins\]" "$TERMINATOR_CONFIG"; then
    echo -e "\n[plugins]\n  [[QmdURLHandler]]" >> "$TERMINATOR_CONFIG"
    log_ok "Added [plugins] section to $TERMINATOR_CONFIG"
  elif ! grep -q "\[\[QmdURLHandler\]\]" "$TERMINATOR_CONFIG"; then
    # Add under [plugins] section
    sed -i '/^\[plugins\]/a\  [[QmdURLHandler]]' "$TERMINATOR_CONFIG"
    log_ok "Added QmdURLHandler to [plugins] in $TERMINATOR_CONFIG"
  else
    log_ok "QmdURLHandler already configured in [plugins]"
  fi
fi

# ─────────────────────────────────────────────────────────────────

log_header "Configuring Remote Connection"

# Defaults
DEFAULT_REMOTE="mia@eury"
DEFAULT_WORKSPACE="/home/mia/workspace"
DEFAULT_BUN="/home/mia/.bun/bin/bun"

echo -e "The handler needs to fetch knowledge from a remote QMD instance."

# Prompt for Remote Host
read -p "$(echo -e ${BLUE})→$(echo -e ${RESET}) Enter remote SSH host [$DEFAULT_REMOTE]: " REMOTE_HOST
REMOTE_HOST="${REMOTE_HOST:-$DEFAULT_REMOTE}"

# Only prompt for paths if we're NOT using the defaults
REMOTE_WORKSPACE="$DEFAULT_WORKSPACE"
REMOTE_BUN="$DEFAULT_BUN"

if [[ "$REMOTE_HOST" != "$DEFAULT_REMOTE" ]]; then
    read -p "$(echo -e ${BLUE})→$(echo -e ${RESET}) Enter remote workspace path [$DEFAULT_WORKSPACE]: " REMOTE_WORKSPACE
    REMOTE_WORKSPACE="${REMOTE_WORKSPACE:-$DEFAULT_WORKSPACE}"
    
    read -p "$(echo -e ${BLUE})→$(echo -e ${RESET}) Enter remote bun executable path [$DEFAULT_BUN]: " REMOTE_BUN
    REMOTE_BUN="${REMOTE_BUN:-$DEFAULT_BUN}"
fi

REMOTE_QMD_REPO="$REMOTE_WORKSPACE/repos/miadisabelle/mia-qmd"

# Update qmd-open in ~/bin with the chosen values
sed -i "s|REMOTE_HOST=\"\${REMOTE_HOST:-.*}\"|REMOTE_HOST=\"\${REMOTE_HOST:-$REMOTE_HOST}\"|" "$BIN_DIR/qmd-open"
sed -i "s|REMOTE_WORKSPACE=\"\${REMOTE_WORKSPACE:-.*}\"|REMOTE_WORKSPACE=\"\${REMOTE_WORKSPACE:-$REMOTE_WORKSPACE}\"|" "$BIN_DIR/qmd-open"
sed -i "s|REMOTE_BUN=\"\${REMOTE_BUN:-.*}\"|REMOTE_BUN=\"\${REMOTE_BUN:-$REMOTE_BUN}\"|" "$BIN_DIR/qmd-open"
sed -i "s|REMOTE_QMD_REPO=\"\${REMOTE_QMD_REPO:-.*}\"|REMOTE_QMD_REPO=\"\${REMOTE_QMD_REPO:-\$REMOTE_WORKSPACE/repos/miadisabelle/mia-qmd}\"|" "$BIN_DIR/qmd-open"

log_ok "Configuration updated in $BIN_DIR/qmd-open:"
echo "  • REMOTE_HOST: $REMOTE_HOST"
echo "  • REMOTE_WORKSPACE: $REMOTE_WORKSPACE"
echo "  • REMOTE_BUN: $REMOTE_BUN"

if confirm "Test SSH connection to $REMOTE_HOST?"; then
  if ssh -o BatchMode=yes -o ConnectTimeout=5 "$REMOTE_HOST" "ls '$REMOTE_BUN' && ls -d '$REMOTE_QMD_REPO'" &>/dev/null; then
    log_ok "SSH connection and remote paths verified"
  else
    log_info "⚠ SSH connection failed or remote paths not found. Ensure key-based auth and paths are correct."
  fi
fi

# ─────────────────────────────────────────────────────────────────

log_header "Validating..."

# Check wrapper
if [ -x "$BIN_DIR/qmd-open" ]; then
  log_ok "Wrapper executable: $BIN_DIR/qmd-open"
else
  echo "⚠ Wrapper not executable. Run: chmod +x $BIN_DIR/qmd-open"
fi

# Check plugin
if [ -f "$TERMINATOR_PLUGINS/qmd_url_handler.py" ]; then
  log_ok "Plugin installed: $TERMINATOR_PLUGINS/qmd_url_handler.py"
  if python3 -c "import ast; ast.parse(open('$TERMINATOR_PLUGINS/qmd_url_handler.py').read())" 2>/dev/null; then
    log_ok "Plugin syntax valid"
  else
    echo "⚠ Plugin has syntax errors"
  fi
else
  echo "✗ Plugin not found"
fi

# Check config
if grep -q "QmdURLHandler" "$TERMINATOR_CONFIG" 2>/dev/null; then
  log_ok "Plugin configured in $TERMINATOR_CONFIG"
else
  echo "⚠ Plugin not in $TERMINATOR_CONFIG"
fi

# ─────────────────────────────────────────────────────────────────

log_header "Setup complete! 🎉"
echo ""
echo "Next steps:"
echo "  1. ${BOLD}Restart Terminator${RESET} — close all windows, then reopen"
echo "  2. Run: ${BOLD}scripts/qmd_remote.sh \"Your Query\"${RESET}"
echo "  3. ${BOLD}Ctrl-click${RESET} any qmd:// URI to fetch and open"
echo ""
echo "For more info, see: $SCRIPT_DIR/qmd-handler/option-a-terminator-plugin.rispec.md"
echo ""
