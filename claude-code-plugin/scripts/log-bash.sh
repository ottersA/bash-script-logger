#!/bin/bash

# Claude Code sets CLAUDE_PLUGIN_ROOT; Codex does not.
# This determines both the log directory and the JSON schema we use.
if [ -n "$CLAUDE_PLUGIN_ROOT" ]; then
    AGENT="claude-code"
    LOG_DIR="$HOME/.claude/bash_tracing"
else
    AGENT="codex"
    LOG_DIR="$HOME/.codex/bash_tracing"
fi

LOG_FILE="$LOG_DIR/telemetry.jsonl"
LAST_PROMPT_FILE="$LOG_DIR/.last_prompt"
MAX_OUTPUT_CHARS=500  # Truncate stdout/stderr to this many characters

# Create the log directory if it doesn't exist
mkdir -p "$LOG_DIR"

# Check if plugin is disabled (persists across sessions)
if [ -f "$LOG_DIR/.disabled" ]; then
    exit 0
fi

# Check for [norecord] prefix — user opts out of logging this prompt
if [ -f "$LOG_DIR/.norecord" ]; then
    exit 0
fi

# Read input from stdin
INPUT=$(cat)

# The session ID groups all commands from one conversation together.
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"' 2>/dev/null)

# Compute tool execution duration using the timestamp written by pre-tool-use.sh
START_NS_FILE="$LOG_DIR/.tool_start_ns_${SESSION_ID}"
DURATION_MS="null"
CMD_START_TIMESTAMP="null"
if [ -f "$START_NS_FILE" ]; then
    START_NS=$(cat "$START_NS_FILE")
    END_NS=$(date +%s%N 2>/dev/null)
    # Only compute if we actually got nanoseconds (not the literal "%N")
    if [ -n "$START_NS" ] && [ "$START_NS" != "%N" ] && [ -n "$END_NS" ] && [ "$END_NS" != "%N" ]; then
        DURATION_MS=$(( (END_NS - START_NS) / 1000000 ))
        # Convert START_NS epoch-ns to an ISO timestamp
        START_S=$(( START_NS / 1000000000 ))
        CMD_START_TIMESTAMP=$(date -u -d "@$START_S" +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date -u -r "$START_S" +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || echo "null")
    fi
    rm -f "$START_NS_FILE"
fi

# The actual bash command that Claude generated and ran.
CMD_TEXT=$(echo "$INPUT" | jq -r '.tool_input.command // ""' 2>/dev/null)

# Only log if we actually got a command
if [ -z "$CMD_TEXT" ] || [ "$CMD_TEXT" = "null" ]; then
    exit 0
fi

# Read the last user prompt
USER_PROMPT=""
PROMPT_TIMESTAMP=""
if [ -f "$LAST_PROMPT_FILE" ]; then
    USER_PROMPT=$(jq -r '.prompt // ""' "$LAST_PROMPT_FILE" 2>/dev/null)
    PROMPT_TIMESTAMP=$(jq -r '.timestamp // ""' "$LAST_PROMPT_FILE" 2>/dev/null)
fi

# Generate timestamp
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Create session subdirectory
mkdir -p "$LOG_DIR/$SESSION_ID"

# Build agent-specific log entry
if [ "$AGENT" = "codex" ]; then
    # Codex sends tool_response (single string), no structured exit_code/stdout/stderr
    TOOL_RESPONSE=$(echo "$INPUT" | jq -r '.tool_response // ""' 2>/dev/null | head -c "$MAX_OUTPUT_CHARS")

    LOG_ENTRY=$(jq -cn \
        --arg timestamp "$TIMESTAMP" \
        --arg agent "$AGENT" \
        --arg session_id "$SESSION_ID" \
        --arg user_prompt "$USER_PROMPT" \
        --arg prompt_timestamp "$PROMPT_TIMESTAMP" \
        --arg bash_command "$CMD_TEXT" \
        --arg tool_response "$TOOL_RESPONSE" \
        --arg cmd_start_timestamp "$CMD_START_TIMESTAMP" \
        --argjson duration_ms "$DURATION_MS" \
        '{
            timestamp: $timestamp,
            cmd_start_timestamp: (if $cmd_start_timestamp == "null" then null else $cmd_start_timestamp end),
            duration_ms: $duration_ms,
            agent: $agent,
            session_id: $session_id,
            user_prompt: $user_prompt,
            prompt_timestamp: $prompt_timestamp,
            bash_command: $bash_command,
            exit_code: null,
            stdout_preview: null,
            stderr_preview: null,
            tool_response: $tool_response,
            category: "",
            summary: ""
        }')
else
    # Claude Code sends structured tool_output with exit_code, stdout, stderr
    EXIT_CODE=$(echo "$INPUT" | jq -r '.tool_output.exit_code // .tool_output.exitCode // "null"' 2>/dev/null)
    STDOUT_PREVIEW=$(echo "$INPUT" | jq -r '.tool_output.stdout // .tool_output.output // ""' 2>/dev/null | head -c "$MAX_OUTPUT_CHARS")
    STDERR_PREVIEW=$(echo "$INPUT" | jq -r '.tool_output.stderr // ""' 2>/dev/null | head -c "$MAX_OUTPUT_CHARS")

    LOG_ENTRY=$(jq -cn \
        --arg timestamp "$TIMESTAMP" \
        --arg agent "$AGENT" \
        --arg session_id "$SESSION_ID" \
        --arg user_prompt "$USER_PROMPT" \
        --arg prompt_timestamp "$PROMPT_TIMESTAMP" \
        --arg bash_command "$CMD_TEXT" \
        --arg exit_code "$EXIT_CODE" \
        --arg stdout_preview "$STDOUT_PREVIEW" \
        --arg stderr_preview "$STDERR_PREVIEW" \
        --arg cmd_start_timestamp "$CMD_START_TIMESTAMP" \
        --argjson duration_ms "$DURATION_MS" \
        '{
            timestamp: $timestamp,
            cmd_start_timestamp: (if $cmd_start_timestamp == "null" then null else $cmd_start_timestamp end),
            duration_ms: $duration_ms,
            agent: $agent,
            session_id: $session_id,
            user_prompt: $user_prompt,
            prompt_timestamp: $prompt_timestamp,
            bash_command: $bash_command,
            exit_code: ($exit_code | if . == "null" then null else (tonumber? // .) end),
            stdout_preview: $stdout_preview,
            stderr_preview: $stderr_preview,
            tool_response: null,
            category: "",
            summary: ""
        }')
fi

# Append to log file
echo "$LOG_ENTRY" >> "$LOG_FILE"

# Exit 0 to not block the agent
exit 0