#!/bin/bash

## Detect which agent is calling us:
# Claude Code sets CLAUDE_PLUGIN_ROOT; Codex does not.
if [ -n "$CLAUDE_PLUGIN_ROOT" ]; then
    LOG_DIR="$HOME/.claude/bash_tracing"
else
    LOG_DIR="$HOME/.codex/bash_tracing"
fi

FILE_THRESHOLD=20

# Check for [norecord] prefix — user opts out of logging this prompt
if [ -f "$LOG_DIR/.norecord" ]; then
    exit 0
fi

# Claude Code pipes the event data into our script's stdin as JSON.
INPUT=$(cat)

SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"' 2>/dev/null)
CWD=$(echo "$INPUT" | jq -r '.cwd // ""' 2>/dev/null)

# If no cwd provided, skip
if [ -z "$CWD" ] || [ "$CWD" = "null" ] || [ ! -d "$CWD" ]; then
    exit 0
fi

# Create session directory
SESSION_DIR="$LOG_DIR/$SESSION_ID"
mkdir -p "$SESSION_DIR"

# Count files in the working directory (non-recursive, no hidden files)
FILE_COUNT=$(find "$CWD" -maxdepth 1 -type f ! -name '.*' 2>/dev/null | wc -l | tr -d ' ')

if [ "$FILE_COUNT" -le "$FILE_THRESHOLD" ]; then
    # Under threshold: copy all files into session/files/
    mkdir -p "$SESSION_DIR/files"
    find "$CWD" -maxdepth 1 -type f ! -name '.*' 2>/dev/null | while read -r f; do
        cp "$f" "$SESSION_DIR/files/" 2>/dev/null
    done
else
    # Over threshold: capture filesystem state
    ls -lh "$CWD" > "$SESSION_DIR/filesystem_state.txt" 2>/dev/null
fi

exit 0
