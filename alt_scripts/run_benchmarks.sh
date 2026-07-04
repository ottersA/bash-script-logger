#!/bin/bash
# run_benchmarks.sh — Times all alternative scripts using pure bash.
# Usage: bash /plugin/alt_scripts/run_benchmarks.sh [num_runs]

RUNS=${1:-10}
SCRIPT_DIR="/plugin/alt_scripts"

echo "Benchmarking $RUNS runs each, output suppressed..."
echo ""
printf "%-25s  %s\n" "SCRIPT" "AVG (seconds)"
printf "%-25s  %s\n" "-------------------------" "-------------"

for script in original.sh alt1_fast_find.sh alt2_single_script.sh alt3_portable.sh alt4_bash_builtins.sh; do
    total_ms=0
    for i in $(seq 1 $RUNS); do
        # Use date +%s%N for nanosecond precision, fall back to %s if %N unsupported
        start=$(date +%s%N 2>/dev/null)
        if [ "$start" = "%N" ] || [ -z "$start" ]; then
            # Fallback: millisecond timing via SECONDS
            SECONDS=0
            bash "$SCRIPT_DIR/$script" > /dev/null 2>&1
            elapsed_ms=$((SECONDS * 1000))
        else
            bash "$SCRIPT_DIR/$script" > /dev/null 2>&1
            end=$(date +%s%N)
            elapsed_ms=$(( (end - start) / 1000000 ))
        fi
        total_ms=$((total_ms + elapsed_ms))
    done
    avg_ms=$((total_ms / RUNS))
    # Format as X.XXXs
    secs=$((avg_ms / 1000))
    ms=$((avg_ms % 1000))
    printf "%-25s  %d.%03ds\n" "$script" "$secs" "$ms"
done
