#!/usr/bin/env bash
# 40-bun-install.sh — Install Bun JavaScript runtime
# Prerequisites: None (standalone installer)
# Used by: mia-qmd (QMD search engine)
set -euo pipefail

echo "=== Installing Bun JavaScript Runtime ==="

if command -v bun &>/dev/null; then
    echo "Bun already installed: $(bun --version)"
    read -rp "Reinstall/upgrade? [y/N] " reply
    if [[ ! "$reply" =~ ^[Yy]$ ]]; then
        echo "Skipping Bun installation."
        exit 0
    fi
fi

# Official Bun installer
curl -fsSL https://bun.sh/install | bash

# Source bun into current shell
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# Verify installation
if command -v bun &>/dev/null; then
    echo "✅ Bun installed successfully: $(bun --version)"
else
    echo "❌ Bun installation failed"
    exit 1
fi

# Add to shell profile if not already there
for rcfile in "$HOME/.bashrc" "$HOME/.zshrc"; do
    if [ -f "$rcfile" ]; then
        if ! grep -q 'BUN_INSTALL' "$rcfile" 2>/dev/null; then
            echo "" >> "$rcfile"
            echo '# Bun' >> "$rcfile"
            echo 'export BUN_INSTALL="$HOME/.bun"' >> "$rcfile"
            echo 'export PATH="$BUN_INSTALL/bin:$PATH"' >> "$rcfile"
            echo "  Added Bun to $rcfile"
        fi
    fi
done

echo "=== Bun installation complete ==="
