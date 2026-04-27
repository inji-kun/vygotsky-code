---
description: Toggle caveman response brevity (off | lite | full | status)
argument-hint: [off|lite|full|status]
allowed-tools: Bash
---

Read the user's argument: $ARGUMENTS

If the argument is `off`, `lite`, or `full`: write that value to
`~/.vygotsky/caveman_state` (creating the directory if needed) and report the
new level.

If the argument is `status` or empty: read `~/.vygotsky/caveman_state` (or
`$VYGOTSKY_CAVEMAN` env var as fallback) and report the current level.

If the argument is anything else: print `usage: /caveman [off|lite|full|status]`
and exit non-zero.

Run this with Bash:

```bash
ARG="$(printf '%s' "$ARGUMENTS" | tr -d '[:space:]')"
STATE_DIR="$HOME/.vygotsky"
STATE_FILE="$STATE_DIR/caveman_state"
mkdir -p "$STATE_DIR"

case "$ARG" in
  off|lite|full)
    # Atomic write: temp file + mv, so a concurrent caveman.sh read never
    # sees a partial/empty state file mid-write.
    TMP_FILE=$(mktemp "$STATE_DIR/caveman_state.XXXXXX")
    printf '%s\n' "$ARG" > "$TMP_FILE"
    mv "$TMP_FILE" "$STATE_FILE"
    echo "caveman: $ARG (next turn picks this up automatically)"
    ;;
  status|"")
    if [[ -f "$STATE_FILE" ]]; then
      LEVEL=$(tr -d '[:space:]' < "$STATE_FILE")
      echo "caveman: $LEVEL (from $STATE_FILE)"
    elif [[ -n "${VYGOTSKY_CAVEMAN:-}" ]]; then
      echo "caveman: $VYGOTSKY_CAVEMAN (from env var)"
    else
      echo "caveman: off (default)"
    fi
    ;;
  *)
    echo "usage: /caveman [off|lite|full|status]" >&2
    exit 1
    ;;
esac
```
