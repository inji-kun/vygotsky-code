#!/usr/bin/env bash
# caveman-reinject.sh — UserPromptSubmit hook that re-injects the caveman
# response-style block on every turn.
#
# Why re-inject: long sessions drift; without this, the model reverts to
# default verbosity around turn 5–10 as the SessionStart context ages.
# This is a no-op when the active level is "off".

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"

# Drain stdin (Claude Code provides the prompt JSON here, but we don't use it).
# Reading prevents the writing process from blocking on a full pipe.
cat > /dev/null

# shellcheck source=./caveman.sh
. "${SCRIPT_DIR}/caveman.sh"

BLOCK="$(emit_response_style_block)"

# No block → no output → no additional context. Hook exits silently.
if [[ -z "${BLOCK// }" ]]; then
  exit 0
fi

# Emit additionalContext JSON. Use node for safe JSON encoding of arbitrary text.
CAVEMAN_BLOCK="$BLOCK" node -e "
const block = process.env.CAVEMAN_BLOCK || '';
process.stdout.write(JSON.stringify({
  hookSpecificOutput: {
    hookEventName: 'UserPromptSubmit',
    additionalContext: block
  }
}));
"
exit 0
