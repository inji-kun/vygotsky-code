#!/usr/bin/env bash
# Stop hook: check burst size + last engagement signal.
# If writes happened and last response was passive, queue a nudge
# for the next turn via ~/.vygotsky/pending_nudge.

PLUGIN_NAME=$(basename "${CLAUDE_PLUGIN_ROOT:-vygotsky-code}")
STATE_DIR="$HOME/.vygotsky/plugins/$PLUGIN_NAME"
mkdir -p "$STATE_DIR"
COUNTER_FILE="$STATE_DIR/burst_counter"
NUDGE_FILE="$STATE_DIR/pending_nudge"
ENGAGEMENT_FILE="$STATE_DIR/engagement.json"

count=$(cat "$COUNTER_FILE" 2>/dev/null || echo 0)
echo 0 > "$COUNTER_FILE"

# No writes this turn — nothing to nudge about
if [ "$count" -eq 0 ]; then
    exit 0
fi

# Check if last human prompt was passive (using node instead of python3)
last_passive=$(VYGOTSKY_STATE_DIR="$STATE_DIR" node -e "
const fs = require('fs');
const path = require('path');
const os = require('os');
const logPath = process.env.VYGOTSKY_STATE_DIR + '/engagement.json';
try {
  const lines = fs.readFileSync(logPath, 'utf8').trim().split('\n').filter(Boolean);
  if (!lines.length) { console.log('false'); process.exit(); }
  const last = JSON.parse(lines[lines.length - 1]);
  console.log(last.passive ? 'true' : 'false');
} catch { console.log('false'); }
" 2>/dev/null || echo "false")

if [ "$last_passive" = "true" ]; then
    echo "$count" > "$NUDGE_FILE"
fi

exit 0
