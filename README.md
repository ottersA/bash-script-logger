# Bash Script Logger — Agent Tool-use Logging & Analysis System

**Bash Script Logger** silently instruments the bash commands that AI coding agents (Claude Code and Codex) generate and run. It captures the command text, output, the user's original prompt, and file context—then writes structured telemetry for later analysis.

## Why?

Both Claude Code and Codex generate raw shell commands on the fly. Neither agent optimizes the scripts it produces. Bash Script Logger collects the data to **prove** this is a problem and **measure** it.

## Features

- **Multi-Agent Support:** Works natively with both Claude Code and OpenAI Codex CLI.
- **Opt-out prefix:** Prefix any prompt with `[norecord]` to skip tracking for that turn.
- **File Context Capture:** Automatically saves copies of working files (if ≤20 files) or `ls -lh` filesystem state (if >20 files) at the end of each session.
- **Session Grouping:** Logs are organized into agent-specific directories (`~/.claude/bash_tracing/` and `~/.codex/bash_tracing/`) with dedicated subdirectories per session.

## Installation

### Claude Code

```bash
# Load the plugin directly from this directory
claude --plugin-dir ./bash-script-logger/claude-code-plugin
```

### OpenAI Codex CLI

Run the included installer to merge the hooks into your Codex configuration:

```bash
bash ./bash-script-logger/codex-plugin/install-codex.sh
```

## How It Works

Bash Script Logger uses three lifecycle hooks:

| Hook | Script | Purpose |
|:-----|:-------|:--------|
| `UserPromptSubmit` | `capture-prompt.sh` | Saves the user's prompt (or skips if `[norecord]` is used). |
| `PostToolUse` (Bash)| `log-bash.sh` | Logs the command + output + prompt to `telemetry.jsonl`. |
| `Stop` | `capture-context.sh`| Captures file state or copies files into the session directory. |

### Telemetry Format (JSONL)

```json
{
  "timestamp": "2026-06-23T10:00:00Z",
  "agent": "codex",
  "session_id": "abc-123",
  "user_prompt": "Find all Python files",
  "prompt_timestamp": "2026-06-23T09:59:55Z",
  "bash_command": "find . -name '*.py'",
  "exit_code": null,
  "stdout_preview": null,
  "stderr_preview": null,
  "tool_response": "src/main.py...",
  "category": "",
  "summary": ""
}
```
*(Note: Codex groups output into `tool_response`, whereas Claude Code provides structured `exit_code`, `stdout_preview`, and `stderr_preview`.)*

## Analysis

Use the included analysis script to generate a report from both Claude Code and Codex logs:

```bash
bash ./bash-script-logger/scripts/analyze.sh
```
