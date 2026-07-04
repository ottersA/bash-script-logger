#!/bin/sh
# Alt 3: More portable fallback — keeps sed but adds LC_ALL=C to sort
start=$(date +%s%N)
pwd
ls -la
find . -maxdepth 2 -type f | LC_ALL=C sort | sed 's#^./##'
end=$(date +%s%N)
echo "SCRIPT_TIME_MS=$(( (end - start) / 1000000 ))" >&2
