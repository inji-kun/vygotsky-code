#!/usr/bin/env bash
# SessionStart hook for Vygotsky plugin.
# Injects three blocks at session start (once — nothing mid-session):
#   1. SKILL.md  — Claude's operating posture
#   2. Session brief — developer model snapshot (generated from diary files)
#   3. Active plan  — .claude/plans/index.json if present in project dir
#
# On compaction: injects a lightweight state-reload instruction instead.
# Uses Node.js (guaranteed by Claude Code) — no Python dependency.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
PLUGIN_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# --- Ensure state directories exist (first run on clean machine) ---
PLUGIN_NAME=$(basename "${CLAUDE_PLUGIN_ROOT:-vygotsky-code}")
STATE_DIR="$HOME/.vygotsky/plugins/$PLUGIN_NAME"
SESSIONS_DIR="$HOME/.vygotsky/sessions"
mkdir -p "$SESSIONS_DIR"
mkdir -p "$STATE_DIR"
mkdir -p "$HOME/.vygotsky/diary"
mkdir -p "$HOME/.vygotsky/summaries/$PLUGIN_NAME"

# --- Clear turn-level state from prior session ---
echo 0 > "$STATE_DIR/burst_counter"
rm -f "$STATE_DIR/pending_nudge"

INPUT=$(cat)
SKILL_PATH="${PLUGIN_ROOT}/skills/vygotsky/SKILL.md"

# --- Use node for all JSON/file processing ---
VYGOTSKY_PLUGIN_NAME="$PLUGIN_NAME" node -e "
const fs = require('fs');
const path = require('path');
const os = require('os');

const input = JSON.parse(process.argv[1]);
const skillPath = process.argv[2];
const pluginRoot = process.argv[3];
const cwd = process.cwd();

const VYGOTSKY_DIR = path.join(os.homedir(), '.vygotsky');
const DIARY_DIR = path.join(VYGOTSKY_DIR, 'diary');
const PLUGIN_NAME = process.env.VYGOTSKY_PLUGIN_NAME || 'vygotsky-code';
const SUMMARIES_DIR = path.join(VYGOTSKY_DIR, 'summaries', PLUGIN_NAME);
const PLUGIN_STATE = path.join(VYGOTSKY_DIR, 'plugins', PLUGIN_NAME);
const ENGAGEMENT_PATH = path.join(PLUGIN_STATE, 'engagement.json');
const SESSIONS_DIR = path.join(VYGOTSKY_DIR, 'sessions');

const MASTERY_TYPES = new Set(['prediction', 'explanation', 'transfer', 'directive', 'design_decision', 'disagreement']);
const GAP_TYPES = new Set(['gap', 'correction']);
const LINK_RE = /\[\[([^\]]+)\]\]/g;
const ENTRY_RE = /### (\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z) \[(\w+)\]\n/;

// --- Write session marker ---
const sessionId = input.session_id || 'unknown';
const timestamp = new Date().toISOString().replace(/\.\d+Z$/, 'Z');
const marker = JSON.stringify({
  session_id: sessionId,
  started_at: timestamp,
  cwd: cwd,
  plugin_name: PLUGIN_NAME,
  plugin_version: '0.4.0',
  vygotsky_active: true
}, null, 2);
const safeTs = timestamp.replace(/:/g, '-');
fs.writeFileSync(path.join(SESSIONS_DIR, safeTs + '_' + sessionId + '.json'), marker);

// --- Detect event type ---
const eventType = input.type || 'startup';

if (eventType === 'compact') {
  const msg = 'Vygotsky session resumed after compaction. ' +
    'Read the diary files in ~/.vygotsky/diary/ to re-orient on the developer model. ' +
    'Then check .claude/plans/index.json if a plan is active.';
  const wrapper = '<EXTREMELY_IMPORTANT>\\n' + msg + '\\n</EXTREMELY_IMPORTANT>';
  console.log(JSON.stringify({hookSpecificOutput: {hookEventName: 'SessionStart', additionalContext: wrapper}}));
  process.exit(0);
}

// --- Helpers ---
function slugify(concept) {
  return concept.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '');
}

function readSummary(concept) {
  const p = path.join(SUMMARIES_DIR, slugify(concept) + '.md');
  try { return fs.readFileSync(p, 'utf8').trim(); } catch { return null; }
}

function parseEntries(filePath) {
  let content;
  try { content = fs.readFileSync(filePath, 'utf8'); } catch { return []; }
  const parts = content.split(/### (\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z) \[(\w+)\](?: \(([^)]+)\))?[^\n]*\n/);
  const entries = [];
  for (let i = 1; i + 3 < parts.length; i += 4) {
    const tag = parts[i+2] || null; // plugin tag, e.g. 'vygotsky-code'
    // Only include entries tagged for this plugin
    if (tag !== PLUGIN_NAME) continue;
    entries.push({ timestamp: parts[i], evidence_type: parts[i+1], observation: parts[i+3].trim() });
  }
  return entries;
}

function extractLinksFromEntries(entries) {
  const links = new Set();
  const re = /\[\[([^\]]+)\]\]/g;
  for (const e of entries) {
    let m;
    while ((m = re.exec(e.observation)) !== null) {
      links.add(slugify(m[1]));
    }
  }
  return links;
}

// --- Block 1: SKILL.md ---
const skill = fs.readFileSync(skillPath, 'utf8');

// --- Block 2: Generate session brief ---
const lines = ['## Developer Session Brief'];

// List concepts sorted by mtime
let conceptFiles = [];
try {
  conceptFiles = fs.readdirSync(DIARY_DIR)
    .filter(f => f.endsWith('.md'))
    .map(f => ({ name: f, stem: f.replace('.md', ''), full: path.join(DIARY_DIR, f), mtime: fs.statSync(path.join(DIARY_DIR, f)).mtimeMs }))
    .sort((a, b) => b.mtime - a.mtime);
} catch {}

// Developer summary
const devSummary = readSummary('developer');
if (devSummary) lines.push('\\n**Developer model:** ' + devSummary.slice(0, 200));

// Strong areas
const strong = [];
for (const cf of conceptFiles) {
  const entries = parseEntries(cf.full);
  if (!entries.length) continue;
  const types = new Set(entries.map(e => e.evidence_type));
  const signalTypes = new Set([...types].filter(t => t !== 'calibration' && t !== 'acknowledgment'));
  const hasMastery = [...signalTypes].some(t => MASTERY_TYPES.has(t));
  if (hasMastery) {
    for (const t of ['transfer', 'directive', 'design_decision', 'prediction', 'explanation', 'disagreement']) {
      if (signalTypes.has(t)) {
        strong.push({ concept: cf.stem, count: entries.length, strongest: t, full: cf.full });
        break;
      }
    }
  }
}

if (strong.length) {
  lines.push('\\n**Strong areas** (demonstrated understanding):');
  for (const s of strong.slice(0, 5)) {
    const summary = readSummary(s.concept);
    if (summary) {
      lines.push('  - **' + s.concept + '**: ' + summary.slice(0, 120));
    } else {
      lines.push('  - ' + s.concept + ' (' + s.count + ' entries, strongest: ' + s.strongest + ')');
    }
    const linked = extractLinksFromEntries(parseEntries(s.full));
    linked.delete(s.concept);
    if (linked.size) {
      lines.push('    -> linked to: ' + [...linked].slice(0, 3).join(', '));
    }
  }
} else {
  lines.push('\\n**Strong areas:** None recorded yet.');
}

// ZPD boundaries
const zpd = [];
for (const cf of conceptFiles) {
  const entries = parseEntries(cf.full);
  if (!entries.length) continue;
  const types = new Set(entries.map(e => e.evidence_type));
  if ([...types].some(t => GAP_TYPES.has(t))) {
    zpd.push({ concept: cf.stem, count: entries.length });
  }
}

if (zpd.length) {
  lines.push('\\n**ZPD boundaries** (gaps or struggles observed):');
  for (const z of zpd.slice(0, 4)) {
    lines.push('  - ' + z.concept + ' (' + z.count + ' entries)');
  }
} else {
  lines.push('\\n**ZPD boundaries:** None flagged yet.');
}

// Engagement signals
lines.push('\\n**Engagement:**');
let consecutivePassive = 0;
let recentSignals = [];
try {
  const raw = fs.readFileSync(ENGAGEMENT_PATH, 'utf8').trim().split('\\n').filter(Boolean);
  for (const line of raw) {
    try { recentSignals.push(JSON.parse(line)); } catch {}
  }
  for (let i = recentSignals.length - 1; i >= 0; i--) {
    if (recentSignals[i].passive) consecutivePassive++;
    else break;
  }
} catch {}

if (consecutivePassive >= 3) {
  lines.push('  Warning: ' + consecutivePassive + ' consecutive passive responses. Recalibrate before proceeding.');
} else if (consecutivePassive > 0) {
  lines.push('  ' + consecutivePassive + ' consecutive passive responses — monitor.');
} else {
  lines.push('  No passive alarm.');
}

if (recentSignals.length) {
  const lastN = recentSignals.slice(-10);
  const passiveCount = lastN.filter(s => s.passive).length;
  lines.push('  Recent: ' + passiveCount + '/' + lastN.length + ' passive in last ' + lastN.length + ' signals.');
}

// Calibration history
const calibrationNotes = [];
for (const cf of conceptFiles) {
  for (const e of parseEntries(cf.full)) {
    if (e.evidence_type === 'calibration') calibrationNotes.push(e.observation.slice(0, 120));
  }
}
if (calibrationNotes.length) {
  lines.push('\\n**Strategy history** (your prior calibrations):');
  for (const note of calibrationNotes.slice(-2)) {
    lines.push('  - ' + note);
  }
}

// Concept topology summary
let edgeCount = 0;
for (const cf of conceptFiles) {
  const entries = parseEntries(cf.full);
  if (!entries.length) continue;
  const linked = extractLinksFromEntries(entries);
  linked.delete(cf.stem);
  edgeCount += linked.size;
}

if (!conceptFiles.length) {
  lines.push('\\n_New developer — no observations yet. Start in senior_peer posture._');
} else if (edgeCount > 0) {
  lines.push('\\n_' + edgeCount + ' concept associations tracked across ' + conceptFiles.length + ' concepts._');
}

const brief = lines.join('\\n');

// --- Block 3: Active plan index ---
let planBlock = '';
const planPath = path.join(cwd, '.claude', 'plans', 'index.json');
try {
  const planRaw = fs.readFileSync(planPath, 'utf8');
  planBlock = '## Active Plan Index\\n\`\`\`json\\n' + planRaw + '\\n\`\`\`';
} catch {}

// --- Assemble ---
const parts = ['You are Vygotsky — a theory-building coding partner.\\n', skill, '\\n---\\n', brief];
if (planBlock) { parts.push('\\n---\\n'); parts.push(planBlock); }
const context = parts.join('\\n');
const wrapper = '<EXTREMELY_IMPORTANT>\\n' + context + '\\n</EXTREMELY_IMPORTANT>';
console.log(JSON.stringify({hookSpecificOutput: {hookEventName: 'SessionStart', additionalContext: wrapper}}));
" "$INPUT" "$SKILL_PATH" "$PLUGIN_ROOT"

exit 0
