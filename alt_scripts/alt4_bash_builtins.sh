#!/usr/bin/env bash
# Alt 4: Bash version using builtins where possible
start=$(date +%s%N)
printf '%s\n' "$PWD"
ls -la
find . -maxdepth 2 -type f -printf '%P\n' | LC_ALL=C sort
end=$(date +%s%N)
echo "SCRIPT_TIME_MS=$(( (end - start) / 1000000 ))" >&2
