#!/bin/bash

CODEX_LOG="$HOME/.codex/bash_tracing/telemetry.jsonl"
CLAUDE_LOG="$HOME/.claude/bash_tracing/telemetry.jsonl"
COMBINED="/tmp/bash_tracing_combined.jsonl"

# Combine available log files
> "$COMBINED"
[ -f "$CODEX_LOG" ] && cat "$CODEX_LOG" >> "$COMBINED"
[ -f "$CLAUDE_LOG" ] && cat "$CLAUDE_LOG" >> "$COMBINED"

if [ ! -s "$COMBINED" ]; then
    echo "No telemetry data found."
    echo "  Codex:      $CODEX_LOG"
    echo "  Claude Code: $CLAUDE_LOG"
    exit 1
fi

echo "==================================================="
echo "      Bash Script Logger Telemetry Analysis        "
echo "==================================================="
echo ""

TOTAL=$(wc -l < "$COMBINED" | tr -d ' ')
echo "Total logged commands: $TOTAL"

# Per-agent breakdown
CODEX_COUNT=$(jq -c 'select(.agent == "codex")' "$COMBINED" 2>/dev/null | wc -l | tr -d ' ')
CLAUDE_COUNT=$(jq -c 'select(.agent == "claude-code")' "$COMBINED" 2>/dev/null | wc -l | tr -d ' ')
echo "  Codex:       $CODEX_COUNT"
echo "  Claude Code: $CLAUDE_COUNT"
echo ""

# Success / failure (Claude Code only — Codex doesn't have structured exit codes)
SUCCESS=$(jq -c 'select(.exit_code == 0)' "$COMBINED" 2>/dev/null | wc -l | tr -d ' ')
FAILURE=$(jq -c 'select(.exit_code != null and .exit_code != 0)' "$COMBINED" 2>/dev/null | wc -l | tr -d ' ')
echo "Successes (exit 0):    $SUCCESS"
echo "Failures:              $FAILURE"
echo ""

# Most frequently used tools (Extract the first word of the bash_command)
echo "Most frequent command types:"
jq -r '.bash_command' "$COMBINED" 2>/dev/null | awk '{print $1}' | sort | uniq -c | sort -nr | head -n 5
echo ""

# Clean up
rm -f "$COMBINED"
