#!/bin/bash
# test-context.sh
# Run this from the tests/ directory to test capture-context.sh logic

echo "==================================================="
echo "   Testing capture-context.sh (Stop Hook)          "
echo "==================================================="

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UNDER_20="$SCRIPT_DIR/under-20"
OVER_20="$SCRIPT_DIR/over-20"
LOG_DIR="$HOME/.codex/bash_tracing"

# Clean up past tests
rm -rf "$UNDER_20"/* "$OVER_20"/*
rm -rf "$LOG_DIR/test-under" "$LOG_DIR/test-over"
mkdir -p "$UNDER_20" "$OVER_20"

# Create files for < 20 (10 files)
for i in {1..10}; do
    touch "$UNDER_20/file_$i.txt"
done

# Create files for > 20 (30 files)
for i in {1..30}; do
    touch "$OVER_20/file_$i.txt"
done

echo ""
echo "1. Testing under 20 files (should copy files)"
echo '{"session_id": "test-under", "cwd": "'"$UNDER_20"'"}' | bash "$SCRIPT_DIR/../claude-code-plugin/scripts/capture-context.sh"
echo "Result in $LOG_DIR/test-under/files:"
ls -l "$LOG_DIR/test-under/files/" | grep -v "^total" | wc -l | awk '{print $1 " files copied (Expected: 10)"}'

echo ""
echo "2. Testing over 20 files (should create filesystem_state.txt)"
echo '{"session_id": "test-over", "cwd": "'"$OVER_20"'"}' | bash "$SCRIPT_DIR/../claude-code-plugin/scripts/capture-context.sh"
echo "Result in $LOG_DIR/test-over:"
if [ -f "$LOG_DIR/test-over/filesystem_state.txt" ]; then
    echo "filesystem_state.txt created successfully. Preview:"
    head -n 3 "$LOG_DIR/test-over/filesystem_state.txt"
    echo "..."
else
    echo "ERROR: filesystem_state.txt not found."
fi

echo ""
echo "Tests completed."
