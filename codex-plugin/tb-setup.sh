#!/bin/bash
# tb-setup.sh — One-shot setup for running Terminal Bench tasks with
#               Codex CLI and Bash Script Logger inside Docker containers.

# Usage (inside a Docker container):
#   bash /plugin/codex-plugin/tb-setup.sh
# Prerequisites (Docker mount flags):
#   -v ~/ATLAS/bash-script-logger:/plugin
#   -v ~/ATLAS/tb_traces:/root/.codex/bash_tracing
#   -v ~/.codex/auth.json:/root/.codex/auth.json:ro   (optional, for auto-login)

set -e

PLUGIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$PLUGIN_DIR")"

echo "  Terminal Bench — Full Environment Setup"

# 1. Install prerequisites (curl, jq, nodejs) if missing 
echo "Step 1: Checking prerequisites..."

NEED_APT_UPDATE=false

if ! command -v curl &>/dev/null; then
    echo "curl not found, will install"
    NEED_APT_UPDATE=true
else
    echo "curl already installed"
fi

if ! command -v jq &>/dev/null; then
    echo "jq not found, will install"
    NEED_APT_UPDATE=true
else
    echo "jq already installed"
fi

# if ! command -v node &>/dev/null; then
#     echo "nodejs not found, will install"
#     NEED_APT_UPDATE=true
# else
#     echo "nodejs $(node --version) already installed"
# fi

if [ "$NEED_APT_UPDATE" = true ]; then
    echo "Installing missing prerequisites..."
    apt-get update -qq 2>/dev/null
    command -v curl &>/dev/null || apt-get install -y -qq curl >/dev/null 2>&1
    command -v jq   &>/dev/null || apt-get install -y -qq jq   >/dev/null 2>&1
    # if ! command -v node &>/dev/null; then
    #     curl -fsSL https://deb.nodesource.com/setup_22.x | bash - >/dev/null 2>&1
    #     apt-get install -y -qq nodejs >/dev/null 2>&1
    # fi
    echo "Prerequisites installed"
fi

# 2. Install Codex CLI if not found 
echo "Step 2: Installing Codex CLI..."

# Ensure PATH includes ~/.local/bin (where the installer puts codex)
export PATH="$HOME/.local/bin:$PATH"

if command -v codex &>/dev/null; then
    echo "Codex CLI already installed: $(codex --version 2>/dev/null || echo 'ok')"
else
    echo "Downloading Codex CLI..."
    echo "N" | curl -fsSL https://chatgpt.com/codex/install.sh | sh 2>&1 | tail -3
    export PATH="$HOME/.local/bin:$PATH"
    if command -v codex &>/dev/null; then
        echo "Codex CLI installed"
    else
        echo "WARNING: Codex install has failed."
        echo "Try manually: curl -fsSL https://chatgpt.com/codex/install.sh | sh"
    fi
fi

# Persist PATH so 'codex' works after this script exits
if ! grep -q '\.local/bin' "$HOME/.bashrc" 2>/dev/null; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
fi

# 3. Check authentication
echo "Step 3: Checking authentication..."

AUTH_FILE="$HOME/.codex/auth.json"
if [ -f "$AUTH_FILE" ] && [ -s "$AUTH_FILE" ]; then
    echo "Authenticated (auth.json found via mount)"
else
    echo "No auth.json found."
    echo "Mount it when starting the container:"
    echo "-v ~/.codex/auth.json:/root/.codex/auth.json:ro"
    echo "Or run 'codex' and follow the browser login flow."
fi

# 4. Install BSL hooks (delegates to the standard installer)
echo "Step 4: Installing Bash Script Logger hooks..."
bash "$PLUGIN_DIR/install-codex.sh"
echo "Setup complete!"
echo ""
echo "Run Codex:"
echo "codex"
echo "Or with auto-approve (for benchmarks):"
echo "codex --dangerously-bypass-approvals-and-sandbox"

