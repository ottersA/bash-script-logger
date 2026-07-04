#!/bin/bash
# pre-tool-use.sh — Records the nanosecond timestamp just before a tool call runs.
# This is used by log-bash.sh (PostToolUse) to compute the actual tool execution time.

if [ -n "$CLAUDE_PLUGIN_ROOT" ]; then
    LOG_DIR="$HOME/.claude/bash_tracing"
else
    LOG_DIR="$HOME/.codex/bash_tracing"
fi
mkdir -p "$LOG_DIR"

if [ -f "$LOG_DIR/.disabled" ]; then
    exit 0
fi

INPUT=$(cat)

SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"' 2>/dev/null)

# Record start time in nanoseconds (falls back to seconds if %N not supported)
START_NS=$(date +%s%N 2>/dev/null)

# Write to a session-scoped temp file so parallel sessions don't collide
echo "$START_NS" > "$LOG_DIR/.tool_start_ns_${SESSION_ID}"

exit 0
