#!/bin/bash

# Detect which agent is calling us:
# Claude Code sets CLAUDE_PLUGIN_ROOT; Codex does not.
if [ -n "$CLAUDE_PLUGIN_ROOT" ]; then
    LOG_DIR="$HOME/.claude/bash_tracing"
else
    LOG_DIR="$HOME/.codex/bash_tracing"
fi
mkdir -p "$LOG_DIR"

# Check if plugin is disabled (persists across sessions)
if [ -f "$LOG_DIR/.disabled" ]; then
    exit 0
fi

# Claude Code pipes the event data into our script's stdin as JSON.
INPUT=$(cat)

# Extract the user's prompt text using jq.
PROMPT=$(echo "$INPUT" | jq -r '.prompt // .user_prompt // ""' 2>/dev/null)

# Extract the session ID so we can group prompts by session.
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"' 2>/dev/null)

# Check for [norecord] prefix — user opts out of logging this prompt
if echo "$PROMPT" | grep -qi '^\[norecord\]'; then
    touch "$LOG_DIR/.norecord"
    exit 0
fi

# Clear any previous norecord flag
rm -f "$LOG_DIR/.norecord"

# Only write if we actually got a prompt (not empty)
if [ -n "$PROMPT" ] && [ "$PROMPT" != "null" ]; then
    # Write the prompt and session ID to a temp file as JSON.
    jq -n \
        --arg prompt "$PROMPT" \
        --arg session_id "$SESSION_ID" \
        --arg timestamp "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
        '{
            prompt: $prompt,
            session_id: $session_id,
            timestamp: $timestamp
        }' > "$LOG_DIR/.last_prompt"
fi

# Always exit 0 to not block the user's prompt.
exit 0
