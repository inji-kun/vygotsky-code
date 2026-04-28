#!/usr/bin/env bash

set -u
set -o pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/caveman-tests.XXXXXX")"
PASS_COUNT=0
FAIL_COUNT=0

cleanup() {
  rm -rf "$TMP_ROOT"
}
trap cleanup EXIT

pass() {
  PASS_COUNT=$((PASS_COUNT + 1))
  printf 'PASS %s\n' "$1"
}

fail() {
  FAIL_COUNT=$((FAIL_COUNT + 1))
  printf 'FAIL %s\n' "$1"
  printf '  %s\n' "$2"
}

assert_eq() {
  local expected="$1"
  local actual="$2"
  local message="$3"
  if [[ "$actual" == "$expected" ]]; then
    return 0
  fi
  printf 'expected: [%s]\nactual:   [%s]\n' "$expected" "$actual" >&2
  return 1
}

assert_file_equals_string() {
  local file_path="$1"
  local actual="$2"
  local expected
  expected="$(cat "$file_path")"
  [[ "$actual" == "$expected" ]]
}

make_home() {
  local home_dir
  home_dir="$(mktemp -d "$TMP_ROOT/home.XXXXXX")"
  mkdir -p "$home_dir/.vygotsky"
  printf '%s\n' "$home_dir"
}

json_get() {
  local json_file="$1"
  local path_expr="$2"
  node -e "
const fs = require('fs');
const obj = JSON.parse(fs.readFileSync(process.argv[1], 'utf8'));
const path = process.argv[2].split('.');
let cur = obj;
for (const part of path) {
  cur = cur?.[part];
}
if (cur === undefined) process.exit(2);
process.stdout.write(String(cur));
" "$json_file" "$path_expr"
}

run_get_caveman_level() {
  local home_dir="$1"
  local env_level="${2-__UNSET__}"
  local command='. "'"$REPO_ROOT"'/scripts/caveman.sh"; get_caveman_level'
  if [[ "$env_level" == "__UNSET__" ]]; then
    HOME="$home_dir" bash -lc "$command"
  else
    HOME="$home_dir" VYGOTSKY_CAVEMAN="$env_level" bash -lc "$command"
  fi
}

run_emit_response_style_block() {
  local home_dir="$1"
  local env_level="${2-__UNSET__}"
  local command='. "'"$REPO_ROOT"'/scripts/caveman.sh"; emit_response_style_block'
  if [[ "$env_level" == "__UNSET__" ]]; then
    HOME="$home_dir" bash -lc "$command"
  else
    HOME="$home_dir" VYGOTSKY_CAVEMAN="$env_level" bash -lc "$command"
  fi
}

run_session_start() {
  local home_dir="$1"
  local output_file="$2"
  local env_level="${3-__UNSET__}"
  if [[ "$env_level" == "__UNSET__" ]]; then
    printf '%s' '{"session_id":"sess-1","type":"startup"}' | \
      HOME="$home_dir" CLAUDE_PLUGIN_ROOT="$REPO_ROOT" "$REPO_ROOT/scripts/session-start.sh" \
      >"$output_file"
  else
    printf '%s' '{"session_id":"sess-1","type":"startup"}' | \
      HOME="$home_dir" CLAUDE_PLUGIN_ROOT="$REPO_ROOT" VYGOTSKY_CAVEMAN="$env_level" \
      "$REPO_ROOT/scripts/session-start.sh" >"$output_file"
  fi
}

run_caveman_reinject() {
  local home_dir="$1"
  local output_file="$2"
  local env_level="${3-__UNSET__}"
  if [[ "$env_level" == "__UNSET__" ]]; then
    printf '%s' '{"prompt":"check hook"}' | \
      HOME="$home_dir" CLAUDE_PLUGIN_ROOT="$REPO_ROOT" "$REPO_ROOT/scripts/caveman-reinject.sh" \
      >"$output_file"
  else
    printf '%s' '{"prompt":"check hook"}' | \
      HOME="$home_dir" CLAUDE_PLUGIN_ROOT="$REPO_ROOT" VYGOTSKY_CAVEMAN="$env_level" \
      "$REPO_ROOT/scripts/caveman-reinject.sh" >"$output_file"
  fi
}

extract_command_bash() {
  awk '
    /^```bash$/ { in_block = 1; next }
    /^```$/ && in_block { exit }
    in_block { print }
  ' "$REPO_ROOT/commands/caveman.md"
}

run_caveman_command() {
  local home_dir="$1"
  local arguments="$2"
  local output_file="$3"
  local status_file="$4"
  local script
  script="$(extract_command_bash)"
  (
    HOME="$home_dir" ARGUMENTS="$arguments" bash -lc "$script"
  ) >"$output_file" 2>&1
  printf '%s' "$?" >"$status_file"
}

test_default_level_is_off() {
  local home_dir actual
  home_dir="$(make_home)"
  actual="$(run_get_caveman_level "$home_dir")" || return 1
  assert_eq "off" "$actual" "default level should be off"
}

test_env_var_level_is_used() {
  local home_dir actual
  home_dir="$(make_home)"
  actual="$(run_get_caveman_level "$home_dir" "lite")" || return 1
  assert_eq "lite" "$actual" "env var should set level"
}

test_state_file_beats_env_var() {
  local home_dir actual
  home_dir="$(make_home)"
  printf 'full\n' >"$home_dir/.vygotsky/caveman_state"
  actual="$(run_get_caveman_level "$home_dir" "lite")" || return 1
  assert_eq "full" "$actual" "state file should beat env var"
}

test_invalid_state_file_falls_back_to_off_even_if_env_is_valid() {
  local home_dir actual
  home_dir="$(make_home)"
  printf 'bogus\n' >"$home_dir/.vygotsky/caveman_state"
  actual="$(run_get_caveman_level "$home_dir" "full")" || return 1
  assert_eq "off" "$actual" "invalid state should fall back to off"
}

test_off_emits_no_block() {
  local home_dir actual
  home_dir="$(make_home)"
  actual="$(run_emit_response_style_block "$home_dir")" || return 1
  assert_eq "" "$actual" "off should emit no block"
}

test_lite_emits_exact_lite_block() {
  local home_dir actual
  home_dir="$(make_home)"
  actual="$(run_emit_response_style_block "$home_dir" "lite")" || return 1
  assert_file_equals_string "$REPO_ROOT/scripts/caveman-lite.txt" "$actual"
}

test_full_emits_exact_full_block() {
  local home_dir actual
  home_dir="$(make_home)"
  actual="$(run_emit_response_style_block "$home_dir" "full")" || return 1
  assert_file_equals_string "$REPO_ROOT/scripts/caveman-full.txt" "$actual"
}

test_session_start_off_has_no_response_style_block() {
  local home_dir output_file context
  home_dir="$(make_home)"
  output_file="$TMP_ROOT/session-start-off.json"
  run_session_start "$home_dir" "$output_file" || return 1
  context="$(json_get "$output_file" "hookSpecificOutput.additionalContext")" || return 1
  [[ "$context" != *"<RESPONSE-STYLE"* ]]
}

test_session_start_lite_includes_exact_lite_block() {
  local home_dir output_file context expected
  home_dir="$(make_home)"
  output_file="$TMP_ROOT/session-start-lite.json"
  run_session_start "$home_dir" "$output_file" "lite" || return 1
  context="$(json_get "$output_file" "hookSpecificOutput.additionalContext")" || return 1
  expected="$(cat "$REPO_ROOT/scripts/caveman-lite.txt")"
  [[ "$context" == *"$expected"* ]]
}

test_session_start_full_includes_exact_full_block() {
  local home_dir output_file context expected
  home_dir="$(make_home)"
  output_file="$TMP_ROOT/session-start-full.json"
  run_session_start "$home_dir" "$output_file" "full" || return 1
  context="$(json_get "$output_file" "hookSpecificOutput.additionalContext")" || return 1
  expected="$(cat "$REPO_ROOT/scripts/caveman-full.txt")"
  [[ "$context" == *"$expected"* ]]
}

test_reinject_off_emits_nothing() {
  local home_dir output_file
  home_dir="$(make_home)"
  output_file="$TMP_ROOT/reinject-off.json"
  run_caveman_reinject "$home_dir" "$output_file" || return 1
  [[ ! -s "$output_file" ]]
}

test_reinject_lite_emits_exact_lite_block() {
  local home_dir output_file actual
  home_dir="$(make_home)"
  output_file="$TMP_ROOT/reinject-lite.json"
  run_caveman_reinject "$home_dir" "$output_file" "lite" || return 1
  actual="$(json_get "$output_file" "hookSpecificOutput.additionalContext")" || return 1
  assert_file_equals_string "$REPO_ROOT/scripts/caveman-lite.txt" "$actual"
}

test_reinject_full_emits_exact_full_block() {
  local home_dir output_file actual
  home_dir="$(make_home)"
  output_file="$TMP_ROOT/reinject-full.json"
  run_caveman_reinject "$home_dir" "$output_file" "full" || return 1
  actual="$(json_get "$output_file" "hookSpecificOutput.additionalContext")" || return 1
  assert_file_equals_string "$REPO_ROOT/scripts/caveman-full.txt" "$actual"
}

test_command_lite_writes_state_file() {
  local home_dir output_file status_file actual
  home_dir="$(make_home)"
  output_file="$TMP_ROOT/command-lite.out"
  status_file="$TMP_ROOT/command-lite.status"
  run_caveman_command "$home_dir" "lite" "$output_file" "$status_file" || return 1
  actual="$(cat "$home_dir/.vygotsky/caveman_state")" || return 1
  assert_eq "0" "$(cat "$status_file")" "command should succeed" || return 1
  assert_eq "lite" "$(printf '%s' "$actual" | tr -d '[:space:]')" "command should write lite"
}

test_command_status_reports_current_level() {
  local home_dir output_file status_file actual
  home_dir="$(make_home)"
  printf 'full\n' >"$home_dir/.vygotsky/caveman_state"
  output_file="$TMP_ROOT/command-status.out"
  status_file="$TMP_ROOT/command-status.status"
  run_caveman_command "$home_dir" "status" "$output_file" "$status_file" || return 1
  actual="$(cat "$output_file")" || return 1
  assert_eq "0" "$(cat "$status_file")" "status command should succeed" || return 1
  [[ "$actual" == *"caveman: full"* ]]
}

test_command_bogus_exits_nonzero_with_usage() {
  local home_dir output_file status_file actual
  home_dir="$(make_home)"
  output_file="$TMP_ROOT/command-bogus.out"
  status_file="$TMP_ROOT/command-bogus.status"
  run_caveman_command "$home_dir" "bogus" "$output_file" "$status_file" || return 1
  actual="$(cat "$output_file")" || return 1
  [[ "$(cat "$status_file")" != "0" ]] || return 1
  [[ "$actual" == *"usage: /caveman [off|lite|full|status]"* ]]
}

test_hooks_json_registers_caveman_reinject_hook() {
  node - "$REPO_ROOT/hooks/hooks.json" <<'NODE'
const fs = require('fs');
const hooks = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
const entries = hooks.hooks.UserPromptSubmit?.[0]?.hooks || [];
const expected = "'${CLAUDE_PLUGIN_ROOT}/scripts/caveman-reinject.sh'";
const match = entries.some((entry) => entry.command === expected);
process.exit(match ? 0 : 1);
NODE
}

run_test() {
  local name="$1"
  shift
  if "$@"; then
    pass "$name"
  else
    fail "$name" "assertion failed"
  fi
}

run_test "default level is off" test_default_level_is_off
run_test "env var level is used" test_env_var_level_is_used
run_test "state file beats env var" test_state_file_beats_env_var
run_test "invalid state falls back to off" test_invalid_state_file_falls_back_to_off_even_if_env_is_valid
run_test "off emits no block" test_off_emits_no_block
run_test "lite emits exact lite block" test_lite_emits_exact_lite_block
run_test "full emits exact full block" test_full_emits_exact_full_block
run_test "SessionStart off emits no response-style block" test_session_start_off_has_no_response_style_block
run_test "SessionStart lite includes exact lite block" test_session_start_lite_includes_exact_lite_block
run_test "SessionStart full includes exact full block" test_session_start_full_includes_exact_full_block
run_test "reinject off emits nothing" test_reinject_off_emits_nothing
run_test "reinject lite emits exact lite block" test_reinject_lite_emits_exact_lite_block
run_test "reinject full emits exact full block" test_reinject_full_emits_exact_full_block
run_test "command lite writes state file" test_command_lite_writes_state_file
run_test "command status reports current level" test_command_status_reports_current_level
run_test "command bogus exits non-zero with usage" test_command_bogus_exits_nonzero_with_usage
run_test "hooks.json registers caveman reinject hook" test_hooks_json_registers_caveman_reinject_hook

printf '\nSummary: %d passed, %d failed\n' "$PASS_COUNT" "$FAIL_COUNT"

if (( FAIL_COUNT > 0 )); then
  exit 1
fi
