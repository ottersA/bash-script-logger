#!/bin/bash
# generate_test_env.sh — Creates a realistic "heavy" environment for benchmarking

TARGET_DIR="/tmp/testenv"
NUM_DIRS=100
FILES_PER_DIR=100

echo "Generating $((NUM_DIRS * FILES_PER_DIR)) dummy files in $TARGET_DIR..."

rm -rf "$TARGET_DIR"
mkdir -p "$TARGET_DIR"

for i in $(seq 1 $NUM_DIRS); do
    mkdir -p "$TARGET_DIR/dir$i"
    # Create 100 files per directory
    for j in $(seq 1 $FILES_PER_DIR); do
        touch "$TARGET_DIR/dir$i/file$j.txt"
    done
done

echo "Done! You can now run the benchmarks."
