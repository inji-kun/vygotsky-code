#!/usr/bin/env bash
# PostToolUse: increment burst counter on write operations.
# Resets to 0 each time the Stop hook fires.

PLUGIN_NAME=$(basename "${CLAUDE_PLUGIN_ROOT:-vygotsky-code}")
STATE_DIR="$HOME/.vygotsky/plugins/$PLUGIN_NAME"
mkdir -p "$STATE_DIR"
COUNTER_FILE="$STATE_DIR/burst_counter"

count=$(cat "$COUNTER_FILE" 2>/dev/null || echo 0)
echo $((count + 1)) > "$COUNTER_FILE"

exit 0
