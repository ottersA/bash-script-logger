#!/bin/sh
# Alt 1: Faster find pipeline — uses -printf to skip sed, LC_ALL=C for faster sort
start=$(date +%s%N)
pwd
ls -la
find . -maxdepth 2 -type f -printf '%P\n' | LC_ALL=C sort
end=$(date +%s%N)
echo "SCRIPT_TIME_MS=$(( (end - start) / 1000000 ))" >&2
