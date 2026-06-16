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
if [ -f "$EXISTING_HOOKS" ]; then
    # Check if our hooks are already installed (avoid duplicates on re-run)
    if grep -q "capture-prompt.sh" "$EXISTING_HOOKS" && grep -q "log-bash.sh" "$EXISTING_HOOKS"; then
        echo "~/.codex/hooks.json already contains Bash Script Logger hooks."
    else
        # for each event type in our hooks, append our entries to the existing array.
        MERGED=$(jq --slurpfile new "$NEW_HOOKS" '
            reduce ($new[0].hooks | keys[]) as $event (.;
                .hooks[$event] = ((.hooks[$event] // []) + $new[0].hooks[$event])
            )
        ' "$EXISTING_HOOKS")
        echo "$MERGED" > "$EXISTING_HOOKS"
        echo "Merged Bash Script Logger hooks into existing ~/.codex/hooks.json."
    fi
else
    cp "$NEW_HOOKS" "$EXISTING_HOOKS"
    echo "Created ~/.codex/hooks.json."
fi


# 3. Install the hook scripts
# - uses the same scripts as the Claude Code plugin.
cp "$ROOT_DIR/claude-code-plugin/scripts/capture-prompt.sh" "$HOOKS_DIR/"
cp "$ROOT_DIR/claude-code-plugin/scripts/log-bash.sh" "$HOOKS_DIR/"

# Ensure they are executable
chmod +x "$HOOKS_DIR/capture-prompt.sh"
chmod +x "$HOOKS_DIR/log-bash.sh"

echo "Installed hook scripts to ~/.codex/hooks/."

echo "Installation complete! Bash Script Logger is now monitoring Codex CLI."
