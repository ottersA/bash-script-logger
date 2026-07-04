#!/bin/sh
# Alt 2: Single shell script — same as alt1 but explicit single-script form
start=$(date +%s%N)
pwd
ls -la
LC_ALL=C find . -maxdepth 2 -type f -printf '%P\n' | sort
end=$(date +%s%N)
echo "SCRIPT_TIME_MS=$(( (end - start) / 1000000 ))" >&2
