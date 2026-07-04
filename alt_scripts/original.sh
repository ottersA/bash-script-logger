#!/bin/sh
# Original command from Codex trace
start=$(date +%s%N)
pwd; ls -la; find . -maxdepth 2 -type f | sed 's#^./##' | sort
end=$(date +%s%N)
echo "SCRIPT_TIME_MS=$(( (end - start) / 1000000 ))" >&2
