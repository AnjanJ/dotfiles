#!/usr/bin/env bash

# ============================================
# CLAUDE SETTINGS TEST SUITE
# ============================================
# scripts/claude-settings.sh against a fake repo: the live settings.json is
# generated from the tracked settings.base.json, Claude Code's own edits
# are adopted into the base, a base pulled from elsewhere is not undone by
# a stale live file, and machine-local keys (autoMode) never reach the
# base. Also guards the real tracked base: no local keys, no /Users/ paths.
# Usage: tests/run claude-settings   (or /opt/homebrew/bin/bash tests/claude-settings-test.sh)
# ============================================
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

require_command jq

S="$ROOT/scripts/claude-settings.sh"
export DOTFILES_DIR="$TEST_TMP/repo"
export DOTFILES_STATE_DIR="$TEST_TMP/state"
D="$DOTFILES_DIR/.config/claude"
mkdir -p "$D"

render() { /bin/bash "$S" --quiet; }
val() { jq -c "$2" "$1"; }

echo ""
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║   Claude Settings Tests                                   ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""

section "Test 1: First render"
echo '{"model":"opus","idleCompaction":false,"permissions":{"defaultMode":"auto"}}' > "$D/settings.base.json"
render
assert_file_exists "$D/settings.json" "the live file is created from the base"
assert_eq "$(val "$D/settings.json" .model)" '"opus"' "with the base's values"
assert_eq "$(val "$D/settings.json" .idleCompaction)" "false" "false values survive"
touch -t 202001010000 "$D/settings.base.json" "$D/settings.json"
out=$(/bin/bash "$S")
assert_eq "$out" "" "a second render reports nothing"
assert_eq "$(find "$D" -name 'settings*.json' -newer "$TEST_TMP" | wc -l | tr -d ' ')" "0" "and rewrites neither file"
echo ""

section "Test 2: Claude Code edits are adopted, local keys are not"
jq '.model = "fable" | .effortLevel = "high" | .autoMode = {"environment":["/Users/someone/private-project"]}' "$D/settings.json" > "$TEST_TMP/l" && cat "$TEST_TMP/l" > "$D/settings.json"
render
assert_eq "$(val "$D/settings.base.json" .model)" '"fable"' "a changed key is adopted"
assert_eq "$(val "$D/settings.base.json" .effortLevel)" '"high"' "a new key is adopted"
assert_eq "$(val "$D/settings.base.json" 'has("autoMode")')" "false" "autoMode never reaches the base"
assert_file_not_contains "$D/settings.base.json" "/Users/" "nor its paths"
assert_eq "$(val "$D/settings.json" '.autoMode.environment[0]')" '"/Users/someone/private-project"' "the live file keeps autoMode"
jq 'del(.effortLevel)' "$D/settings.json" > "$TEST_TMP/l" && cat "$TEST_TMP/l" > "$D/settings.json"
render
assert_eq "$(val "$D/settings.base.json" 'has("effortLevel")')" "false" "a key deleted in Claude Code is dropped from the base"
echo ""

section "Test 3: A pulled base wins over an unchanged live file"
jq '.model = "sonnet" | .newShared = 1' "$D/settings.base.json" > "$TEST_TMP/b" && cat "$TEST_TMP/b" > "$D/settings.base.json"
render
assert_eq "$(val "$D/settings.json" .model)" '"sonnet"' "the pulled value reaches the live file"
assert_eq "$(val "$D/settings.base.json" .model)" '"sonnet"' "and is not reverted in the base"
assert_eq "$(val "$D/settings.json" .newShared)" "1" "a pulled new key arrives"
assert_eq "$(val "$D/settings.json" '.autoMode | type')" '"object"' "autoMode survives a pull"
echo ""

section "Test 4: Both sides changed"
jq '.model = "opus"' "$D/settings.base.json" > "$TEST_TMP/b" && cat "$TEST_TMP/b" > "$D/settings.base.json"
jq '.tui = "fullscreen"' "$D/settings.json" > "$TEST_TMP/l" && cat "$TEST_TMP/l" > "$D/settings.json"
render
assert_eq "$(val "$D/settings.json" .model)" '"opus"' "the base's change to one key arrives"
assert_eq "$(val "$D/settings.base.json" .tui)" '"fullscreen"' "Claude Code's change to another is adopted"
echo ""

section "Test 5: Bad input is left alone"
cp "$D/settings.json" "$TEST_TMP/good"
echo '{ not json' > "$D/settings.json"
cp "$D/settings.base.json" "$TEST_TMP/base-before"
render 2>/dev/null
assert_eq "$(cat "$D/settings.json")" "{ not json" "invalid live JSON is not overwritten"
assert_succeeds "the base is untouched" cmp -s "$TEST_TMP/base-before" "$D/settings.base.json"
cp "$TEST_TMP/good" "$D/settings.json"
echo ""

section "Test 6: The tracked base in this repo"
REAL="$ROOT/.config/claude/settings.base.json"
assert_file_exists "$REAL" "the repo tracks settings.base.json"
assert_eq "$(jq 'has("autoMode")' "$REAL")" "false" "it carries no autoMode"
assert_file_not_contains "$REAL" "/Users/" "and no local paths"
assert_eq "$(jq '.idleCompaction' "$REAL")" "false" "idleCompaction stays false"
assert_eq "$(cd "$ROOT" && git check-ignore -q .config/claude/settings.json && echo ignored)" "ignored" "the generated settings.json is gitignored"
echo ""
