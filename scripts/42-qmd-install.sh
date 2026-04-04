#!/usr/bin/env bash
# 42-qmd-install.sh — Install QMD (Query Markup Documents) search engine
# Prerequisites: 00-nodejs-install.sh (Node.js >= 22), 40-bun-install.sh, 41-sqlite-dev-install.sh
# Also needs: build-essential, python3 (for node-gyp native compilation)
# Source: https://github.com/tobi/qmd | /workspace/repos/miadisabelle/mia-qmd
set -euo pipefail

echo "=== Installing QMD (Query Markup Documents) ==="

# -------------------------------------------------------------------
# 1. Verify prerequisites
# -------------------------------------------------------------------
MISSING=()

if ! command -v node &>/dev/null; then
    MISSING+=("node (run 00-nodejs-install.sh first)")
else
    NODE_MAJOR=$(node -v | sed 's/v\([0-9]*\).*/\1/')
    if [ "$NODE_MAJOR" -lt 22 ]; then
        MISSING+=("node >= 22 (current: $(node -v), run 00-nodejs-install.sh)")
    fi
fi

if ! command -v python3 &>/dev/null; then
    MISSING+=("python3 (run 01-python.sh or: sudo apt install python3)")
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
    read -rp "Install build-essential + python3 now and continue? [y/N] " reply
    if [[ "$reply" =~ ^[Yy]$ ]]; then
        sudo apt-get update
        sudo apt-get install -y build-essential python3
    else
        echo "Please install prerequisites first."
        exit 1
    fi
fi

# -------------------------------------------------------------------
# 2. Install QMD globally via npm
# -------------------------------------------------------------------
echo ""
echo "Installing @tobilu/qmd globally via npm..."
npm install -g @tobilu/qmd

# Verify
if command -v qmd &>/dev/null; then
    echo "✅ QMD installed successfully"
    qmd status 2>/dev/null || true
else
    echo "⚠️  qmd command not found in PATH after npm install -g"
    echo "    You may need to restart your shell or check npm global bin path"
    echo "    Try: npm config get prefix"
    exit 1
fi

# -------------------------------------------------------------------
# 3. Optional: Also install via bun for bun-based workflows
# -------------------------------------------------------------------
if command -v bun &>/dev/null; then
    read -rp "Also install QMD via bun (for bun-native workflows)? [y/N] " reply
    if [[ "$reply" =~ ^[Yy]$ ]]; then
        bun install -g @tobilu/qmd
        echo "✅ QMD also installed via bun"
    fi
fi

# -------------------------------------------------------------------
# 4. Note about GGUF models
# -------------------------------------------------------------------
echo ""
echo "=== QMD Installation Complete ==="
echo ""
echo "📦 GGUF models (~2GB total) will auto-download on first use:"
echo "   - embeddinggemma-300M-Q8_0     (~300MB) — vector embeddings"
echo "   - qwen3-reranker-0.6b-q8_0     (~640MB) — re-ranking"
echo "   - qmd-query-expansion-1.7B-q4  (~1.1GB) — query expansion"
echo ""
echo "Models cached in: ~/.cache/qmd/models/"
echo "Index stored at:  ~/.cache/qmd/index.sqlite"
echo ""
echo "Quick start:"
echo "   qmd collection add ~/notes --name notes"
echo "   qmd embed"
echo "   qmd query 'your search'"
