#!/usr/bin/env bash
# 43-qmd-dev-setup.sh — Set up QMD development environment from source
# Prerequisites: 00-nodejs-install.sh, 40-bun-install.sh, 41-sqlite-dev-install.sh
# Use this instead of 42-qmd-install.sh if developing/contributing to QMD
# Source repo: /workspace/repos/miadisabelle/mia-qmd
set -euo pipefail

QMD_REPO="/workspace/repos/miadisabelle/mia-qmd"

echo "=== Setting up QMD Development Environment ==="

# -------------------------------------------------------------------
# 1. Verify prerequisites
# -------------------------------------------------------------------
MISSING=()

if ! command -v node &>/dev/null; then
    MISSING+=("node >= 22 (run 00-nodejs-install.sh)")
fi

if ! command -v bun &>/dev/null; then
    MISSING+=("bun (run 40-bun-install.sh)")
fi

if ! dpkg -s build-essential &>/dev/null 2>&1; then
    MISSING+=("build-essential (sudo apt install build-essential)")
fi

if ! dpkg -s libsqlite3-dev &>/dev/null 2>&1; then
    MISSING+=("libsqlite3-dev (run 41-sqlite-dev-install.sh)")
fi

if [ ${#MISSING[@]} -gt 0 ]; then
    echo "❌ Missing prerequisites:"
    for m in "${MISSING[@]}"; do
        echo "   - $m"
    done
    exit 1
fi

# -------------------------------------------------------------------
# 2. Check repo exists
# -------------------------------------------------------------------
if [ ! -d "$QMD_REPO" ]; then
    echo "❌ QMD repo not found at $QMD_REPO"
    echo "   Clone it first or adjust QMD_REPO variable"
    exit 1
fi

cd "$QMD_REPO"
echo "Working in: $(pwd)"

# -------------------------------------------------------------------
# 3. Install dependencies
# -------------------------------------------------------------------
echo ""
echo "Installing dependencies with bun..."
bun install

# -------------------------------------------------------------------
# 4. Build TypeScript
# -------------------------------------------------------------------
echo ""
echo "Building TypeScript..."
npm run build

# -------------------------------------------------------------------
# 5. Link globally for development
# -------------------------------------------------------------------
echo ""
echo "Linking qmd globally..."
bun link 2>/dev/null || npm link

# -------------------------------------------------------------------
# 6. Verify
# -------------------------------------------------------------------
echo ""
if command -v qmd &>/dev/null; then
    echo "✅ QMD dev environment ready"
    echo ""
    echo "Development commands:"
    echo "   bun src/cli/qmd.ts <command>   # Run from source"
    echo "   npx vitest run test/           # Run tests"
    echo "   npm run build                  # Rebuild TypeScript"
else
    echo "⚠️  qmd not found in PATH — try: npm link"
fi

echo ""
echo "=== QMD Dev Setup Complete ==="
