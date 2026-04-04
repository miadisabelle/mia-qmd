#!/usr/bin/env bash
# 41-sqlite-dev-install.sh — Install SQLite with development headers and extension support
# Prerequisites: None
# Used by: mia-qmd (sqlite-vec requires loadable extension support)
set -euo pipefail

echo "=== Installing SQLite with Development Headers ==="

sudo apt-get update

# Install SQLite and development libraries (needed for better-sqlite3 and sqlite-vec)
sudo apt-get install -y \
    sqlite3 \
    libsqlite3-dev \
    libsqlite3-0

# Verify
if command -v sqlite3 &>/dev/null; then
    echo "✅ SQLite installed: $(sqlite3 --version)"
else
    echo "❌ SQLite installation failed"
    exit 1
fi

# Verify dev headers exist
if [ -f /usr/include/sqlite3.h ]; then
    echo "✅ SQLite development headers present"
else
    echo "⚠️  SQLite development headers not found at /usr/include/sqlite3.h"
fi

echo "=== SQLite installation complete ==="
