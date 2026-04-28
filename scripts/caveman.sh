#!/usr/bin/env bash
# caveman.sh — opt-in brevity dial for vygotsky-code response prose.
#
# Sourceable library. Used by session-start.sh and caveman-reinject.sh.
#
# Resolves the active level (off | lite | full) by precedence:
#   1. ~/.vygotsky/caveman_state (single line, set via /caveman slash command)
#   2. $VYGOTSKY_CAVEMAN environment variable
#   3. Default: off
#
# Invalid values in either source fall back to "off" and write a one-line warning
# to stderr.

# Resolve the directory this file lives in so we can find the .txt blocks
# regardless of how it's sourced.
_caveman_self_dir="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"

get_caveman_level() {
  local state_file="$HOME/.vygotsky/caveman_state"
  local raw

  if [[ -f "$state_file" ]]; then
    raw=$(tr -d '[:space:]' < "$state_file" 2>/dev/null || true)
    case "$raw" in
      off|lite|full) echo "$raw"; return 0 ;;
      "") ;; # empty file — fall through to env var
      *)
        # Invalid content in the state file is a hard fall to off, not a
        # fall-through. The state file is set by an explicit /caveman action;
        # garbage there means something corrupted it, so fail safe rather than
        # silently honoring a stale env var.
        echo "caveman: invalid value '$raw' in $state_file, falling back to off" >&2
        echo "off"
        return 0
        ;;
    esac
  fi

  case "${VYGOTSKY_CAVEMAN:-}" in
    off|lite|full) echo "$VYGOTSKY_CAVEMAN"; return 0 ;;
    "") ;;
    *) echo "caveman: invalid VYGOTSKY_CAVEMAN='$VYGOTSKY_CAVEMAN', falling back to off" >&2 ;;
  esac

  echo "off"
}

# Emit the response-style block for the active level. Outputs nothing when
# level is "off". Reads the .txt files from this script's directory.
emit_response_style_block() {
  local level
  level=$(get_caveman_level)
  case "$level" in
    lite) cat "${_caveman_self_dir}/caveman-lite.txt" ;;
    full) cat "${_caveman_self_dir}/caveman-full.txt" ;;
    off|*) ;; # no output
  esac
}
