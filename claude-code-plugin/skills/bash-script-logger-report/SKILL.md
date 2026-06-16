---
description: Generate a summary report of collected telemetry data from ~/.bash-script-logger/telemetry.jsonl. Use when the user wants to see statistics about bash commands that have been logged.
---

# Bash Script Logger Telemetry Report

Read the file `~/.bash-script-logger/telemetry.jsonl`. Each line is a JSON object representing one bash command that was executed during an AI agent session.

## Fields in each entry:
- `timestamp`: when the command ran (UTC)
- `agent`: which agent ran it (e.g., "claude-code")
- `session_id`: groups commands from the same conversation
- `user_prompt`: the user's original question that led to this command
- `bash_command`: the exact bash command that was generated and executed
- `exit_code`: 0 = success, non-zero = failure
- `stdout_preview`: first 500 chars of the command's output
- `stderr_preview`: first 500 chars of error output

## Your task:
1. Count the total number of logged commands
2. Show how many succeeded (exit_code = 0) vs failed (exit_code != 0)
3. List the 5 most common command patterns (e.g., "grep", "find", "git", "npm")
4. Note any commands that appear to be inefficient (e.g., using `find | grep` instead of `rg`, piping where a single command would suffice)
5. Summarize in a brief paragraph what kinds of tasks the agent was working on

If the file doesn't exist or is empty, tell the user no telemetry has been collected yet and suggest they run some tasks first.
