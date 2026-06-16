# Bash Script Logger — Agent Tool-use Logging & Analysis System

**Bash Script Logger** silently instruments the bash commands that AI coding agents generate and run. It captures the command text, output, exit codes, and the user's original prompt — then writes structured telemetry to a JSONL log file for later analysis.

## Why?

Both Claude Code and Codex generate raw shell commands on the fly. Neither agent optimizes the scripts it produces. Bash Script Logger collects the data to **prove** this is a problem and **measure** it.

## Quick Start (Claude Code)

### Prerequisites

- [Claude Code](https://code.claude.com) installed
- `jq` installed (`brew install jq` on macOS)

### Install & Test

```bash
# Load the plugin directly from this directory
claude --plugin-dir ./claude-code-plugin
```

That's it. Bash Script Logger will silently log every bash command Claude runs.

### Check your logs

```bash
# View the last 5 logged commands
tail -5 ~/.bash-script-logger/telemetry.jsonl | jq .

# Or use the built-in skill inside Claude Code
/bash-script-logger:report
```

### View raw telemetry

```bash
# Count total commands logged
wc -l ~/.bash-script-logger/telemetry.jsonl

# See all failed commands
jq 'select(.exit_code != 0)' ~/.bash-script-logger/telemetry.jsonl

# See commands from a specific session
jq 'select(.session_id == "YOUR_SESSION_ID")' ~/.bash-script-logger/telemetry.jsonl
```

## How It Works

Bash Script Logger uses two hooks that fire during Claude Code's lifecycle:

| Hook | Event | Script | Purpose |
|:-----|:------|:-------|:--------|
| `UserPromptSubmit` | User types a message | `capture-prompt.sh` | Saves the user's prompt to `~/.bash-script-logger/.last_prompt` |
| `PostToolUse` (Bash) | Claude finishes a bash command | `log-bash.sh` | Logs the command + output + prompt to `~/.bash-script-logger/telemetry.jsonl` |


### Log entry format (JSONL)

Each line in `~/.bash-script-logger/telemetry.jsonl` is a JSON object:

```json
{
  "timestamp": "2026-06-11T20:00:00Z",
  "agent": "claude-code",
  "session_id": "abc-123",
  "user_prompt": "Find all Python files that import os",
  "prompt_timestamp": "2026-06-11T19:59:55Z",
  "bash_command": "find . -name '*.py' | xargs grep 'import os'",
  "exit_code": 0,
  "stdout_preview": "src/main.py:import os...",
  "stderr_preview": "",
  "category": "",
  "summary": ""
}
```

