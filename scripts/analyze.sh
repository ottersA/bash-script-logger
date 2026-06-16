#!/bin/bash

LOG_FILE="$HOME/.bash-script-logger/telemetry.jsonl"

if [ ! -f "$LOG_FILE" ]; then
    echo "No telemetry data found at $LOG_FILE"
    exit 1
fi

echo "==================================================="
echo "      Bash Script Logger Telemetry Analysis        "
echo "==================================================="
echo ""

# Count total commands
TOTAL_COMMANDS=$(wc -l < "$LOG_FILE" | tr -d ' ')
echo "Total logged commands: $TOTAL_COMMANDS"

# Count successes (exit_code == 0) and failures
SUCCESS_COUNT=$(jq -c 'select(.exit_code == 0)' "$LOG_FILE" 2>/dev/null | wc -l | tr -d ' ')
FAILURE_COUNT=$(jq -c 'select(.exit_code != 0)' "$LOG_FILE" 2>/dev/null | wc -l | tr -d ' ')

echo "Successes (Exit 0):    $SUCCESS_COUNT"
echo "Failures:              $FAILURE_COUNT"
echo ""

# Most frequently used tools (Extract the first word of the bash_command)
echo "Most frequent command types:"
jq -r '.bash_command' "$LOG_FILE" 2>/dev/null | awk '{print $1}' | sort | uniq -c | sort -nr | head -n 5
echo ""

