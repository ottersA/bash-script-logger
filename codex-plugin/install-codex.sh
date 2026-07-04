#!/bin/bash

set -e

CODEX_DIR="$HOME/.codex"
HOOKS_DIR="$CODEX_DIR/hooks"
PLUGIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$PLUGIN_DIR")"

echo "Installing Bash Script Logger for OpenAI Codex CLI..."

# Create necessary directories
mkdir -p "$CODEX_DIR"
mkdir -p "$HOOKS_DIR"

# 0. Install Codex CLI if not found
export PATH="$HOME/.local/bin:$PATH"
if command -v codex &>/dev/null; then
    echo "Codex CLI found: $(codex --version 2>/dev/null || echo 'installed')"
else
    echo "Codex CLI not found, installing..."
    if command -v curl &>/dev/null; then
        echo "N" | curl -fsSL https://chatgpt.com/codex/install.sh | sh
        export PATH="$HOME/.local/bin:$PATH"
        if command -v codex &>/dev/null; then
            echo "Codex CLI installed successfully."
        else
            echo "WARNING: Codex CLI install may have failed."
            echo "  Try manually: curl -fsSL https://chatgpt.com/codex/install.sh | sh"
        fi
    else
        echo "WARNING: curl not found, cannot auto-install Codex CLI."
        echo "  Install curl first, or install Codex manually:"
        echo "  curl -fsSL https://chatgpt.com/codex/install.sh | sh"
    fi
fi

# 1. Install config.toml (merge or create)
if [ -f "$CODEX_DIR/config.toml" ]; then
    if ! grep -q "hooks = true" "$CODEX_DIR/config.toml"; then
        echo -e "\n[features]\nhooks = true" >> "$CODEX_DIR/config.toml"
        echo "Updated ~/.codex/config.toml to enable hooks."
    else
        echo "~/.codex/config.toml already has hooks enabled."
    fi
else
    cp "$PLUGIN_DIR/.codex/config.toml" "$CODEX_DIR/config.toml"
    echo "Created ~/.codex/config.toml with hooks enabled."
fi

# 2. Install hooks.json (merge with existing, don't overwrite)
NEW_HOOKS="$PLUGIN_DIR/.codex/hooks.json"
EXISTING_HOOKS="$CODEX_DIR/hooks.json"

# Replace <HOME> placeholder with actual $HOME path
TMP_HOOKS=$(mktemp)
sed "s|<HOME>|$HOME|g" "$NEW_HOOKS" > "$TMP_HOOKS"
if [ -f "$EXISTING_HOOKS" ]; then
    # Check if our hooks are already installed (avoid duplicates on re-run)
    if grep -q "capture-prompt.sh" "$EXISTING_HOOKS" && grep -q "log-bash.sh" "$EXISTING_HOOKS" && grep -q "capture-context.sh" "$EXISTING_HOOKS"; then
        echo "~/.codex/hooks.json already contains Bash Script Logger hooks."
    else
        # for each event type in our hooks, append our entries to the existing array.
        MERGED=$(jq --slurpfile new "$TMP_HOOKS" '
            reduce ($new[0].hooks | keys[]) as $event (.;
                .hooks[$event] = ((.hooks[$event] // []) + $new[0].hooks[$event])
            )
        ' "$EXISTING_HOOKS")
        echo "$MERGED" > "$EXISTING_HOOKS"
        echo "Merged Bash Script Logger hooks into existing ~/.codex/hooks.json."
    fi
else
    cp "$TMP_HOOKS" "$EXISTING_HOOKS"
    echo "Created ~/.codex/hooks.json."
fi

rm -f "$TMP_HOOKS"


# 3. Install the hook scripts
# - uses the same scripts as the Claude Code plugin.
cp "$ROOT_DIR/claude-code-plugin/scripts/capture-prompt.sh" "$HOOKS_DIR/"
cp "$ROOT_DIR/claude-code-plugin/scripts/log-bash.sh" "$HOOKS_DIR/"
cp "$ROOT_DIR/claude-code-plugin/scripts/capture-context.sh" "$HOOKS_DIR/"
cp "$ROOT_DIR/claude-code-plugin/scripts/pre-tool-use.sh" "$HOOKS_DIR/"

# Ensure they are executable
chmod +x "$HOOKS_DIR/capture-prompt.sh"
chmod +x "$HOOKS_DIR/log-bash.sh"
chmod +x "$HOOKS_DIR/capture-context.sh"
chmod +x "$HOOKS_DIR/pre-tool-use.sh"

echo "Installed hook scripts to ~/.codex/hooks/."

echo "Installation complete! Bash Script Logger is now monitoring Codex CLI."
