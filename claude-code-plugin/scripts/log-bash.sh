#!/bin/bash

LOG_DIR="$HOME/.bash-script-logger"
LOG_FILE="$LOG_DIR/telemetry.jsonl"
LAST_PROMPT_FILE="$LOG_DIR/.last_prompt"
MAX_OUTPUT_CHARS=500  # Truncate stdout/stderr to this many characters

# Create the log directory if it doesn't exist
mkdir -p "$LOG_DIR"

# Read input from stdin
INPUT=$(cat)

# The session ID groups all commands from one conversation together.
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"' 2>/dev/null)

# The actual bash command that Claude generated and ran.
CMD_TEXT=$(echo "$INPUT" | jq -r '.tool_input.command // ""' 2>/dev/null)

# The command's exit code (0 = success, non-zero = error).
EXIT_CODE=$(echo "$INPUT" | jq -r '.tool_output.exit_code // .tool_output.exitCode // "null"' 2>/dev/null)

# The command's stdout output, truncated to keep log files manageable.
STDOUT_PREVIEW=$(echo "$INPUT" | jq -r '.tool_output.stdout // .tool_output.output // ""' 2>/dev/null | head -c "$MAX_OUTPUT_CHARS")

# The command's stderr output (error messages), also truncated.
STDERR_PREVIEW=$(echo "$INPUT" | jq -r '.tool_output.stderr // ""' 2>/dev/null | head -c "$MAX_OUTPUT_CHARS")

USER_PROMPT=""
PROMPT_TIMESTAMP=""
if [ -f "$LAST_PROMPT_FILE" ]; then
    USER_PROMPT=$(jq -r '.prompt // ""' "$LAST_PROMPT_FILE" 2>/dev/null)
    PROMPT_TIMESTAMP=$(jq -r '.timestamp // ""' "$LAST_PROMPT_FILE" 2>/dev/null)
fi

# Only log if we actually got a command (not empty)
if [ -z "$CMD_TEXT" ] || [ "$CMD_TEXT" = "null" ]; then
    exit 0
fi

# Generate timestamp
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")


# Build the log entry as a JSON object
LOG_ENTRY=$(jq -cn \
    --arg timestamp "$TIMESTAMP" \
    --arg agent "claude-code" \
    --arg session_id "$SESSION_ID" \
    --arg user_prompt "$USER_PROMPT" \
    --arg prompt_timestamp "$PROMPT_TIMESTAMP" \
    --arg bash_command "$CMD_TEXT" \
    --arg exit_code "$EXIT_CODE" \
    --arg stdout_preview "$STDOUT_PREVIEW" \
    --arg stderr_preview "$STDERR_PREVIEW" \
    '{
        timestamp: $timestamp,
        agent: $agent,
        session_id: $session_id,
        user_prompt: $user_prompt,
        prompt_timestamp: $prompt_timestamp,
        bash_command: $bash_command,
        exit_code: ($exit_code | if . == "null" then null else (tonumber? // .) end),
        stdout_preview: $stdout_preview,
        stderr_preview: $stderr_preview,
        category: "",
        summary: ""
    }')

# Append to log file
echo "$LOG_ENTRY" >> "$LOG_FILE"

# Exit 0 to not block the agent
exit 0
ok