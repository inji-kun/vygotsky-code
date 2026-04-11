#!/usr/bin/env bash
# Engagement signal logger. Runs on UserPromptSubmit.
# Writes one JSON line per prompt to ~/.vygotsky/engagement.json
# Outputs system-reminder context when passive alarm triggers.

INPUT=$(cat)

# Per-plugin state directory (engagement is plugin-specific)
PLUGIN_NAME=$(basename "${CLAUDE_PLUGIN_ROOT:-vygotsky-code}")
STATE_DIR="$HOME/.vygotsky/plugins/$PLUGIN_NAME"
mkdir -p "$STATE_DIR"

echo "$INPUT" | VYGOTSKY_STATE_DIR="$STATE_DIR" node -e "
const fs = require('fs');
const path = require('path');
const os = require('os');
const stateDir = process.env.VYGOTSKY_STATE_DIR;

let data = '';
process.stdin.on('data', c => data += c);
process.stdin.on('end', () => {
  const input = JSON.parse(data);
  const prompt = input.prompt || '';
  const normalized = prompt.trim().toLowerCase().replace(/[.,!?]+$/, '');

  const passivePatterns = new Set([
    'y','yes','ok','okay','lgtm','sure','fine','go ahead',
    'do it','yep','yeah','k','sounds good','proceed','continue',
    'approved','approve','ack','roger',
    'ship it','merge it','+1','no changes needed','looks good',
  ]);

  const deflectionPatterns = new Set([
    'idk',\"i don't know\",'i dont know','no idea','just do it',
    'whatever','you decide','skip',\"doesn't matter\",'dont care',
    \"i don't care\",'not sure',
  ]);

  const passive = passivePatterns.has(normalized) || deflectionPatterns.has(normalized);
  const deflection = deflectionPatterns.has(normalized);

  // Append signal to log
  const logPath = path.join(stateDir, 'engagement.json');
  const entry = JSON.stringify({
    timestamp: new Date().toISOString().replace(/\.\d+Z$/, 'Z'),
    passive,
    deflection,
    prompt,
  });

  fs.appendFileSync(logPath, entry + '\n');

  // Count consecutive passive from end of log
  let consecutive = 0;
  try {
    const lines = fs.readFileSync(logPath, 'utf8').trim().split('\n').filter(Boolean);
    for (let i = lines.length - 1; i >= 0; i--) {
      try {
        const e = JSON.parse(lines[i]);
        if (e.passive) consecutive++;
        else break;
      } catch { break; }
    }
  } catch {}

  const contextParts = [];

  // Burst nudge from previous turn (written by stop-hook.sh)
  // Only inject if this prompt is ALSO passive
  const nudgePath = path.join(stateDir, 'pending_nudge');
  try {
    const burstCount = fs.readFileSync(nudgePath, 'utf8').trim();
    fs.unlinkSync(nudgePath);
    if (passive) {
      contextParts.push(
        'Burst complete: ' + burstCount + ' write operation(s) last turn, ' +
        'previous response was passive. Before starting the next burst, ' +
        'consider whether a theory check is warranted — your quadrant read ' +
        'and the diary should guide whether to ask or proceed.'
      );
    }
  } catch {}

  // Passive alarm
  if (consecutive >= 3) {
    contextParts.push(
      'ENGAGEMENT ALERT: ' + consecutive + ' consecutive passive responses. ' +
      'The user may be rubber-stamping. Before proceeding with any ' +
      'mutating operation, re-engage: surface a trade-off, ask about ' +
      'their mental model, or explain why the next step matters.'
    );
  }

  if (contextParts.length) {
    const combined = '<system-reminder>' + contextParts.join(' | ') + '</system-reminder>';
    console.log(JSON.stringify({ additionalContext: combined }));
  }
});
" || exit 1
