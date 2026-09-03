#!/usr/bin/env bash
# ============================================
# DEBUG SUITE — dotfiles debug
# ============================================
# Runs the real command against the checkout with a sandbox HOME and
# state dir, so the report is about a machine with nothing installed:
# every section must still render, and links must be reported as
# missing rather than crashing the walk.
# ============================================
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

STATE="$TEST_TMP/state"
STUB="$TEST_TMP/stub"
mkdir -p "$STATE" "$STUB"
printf '#!/bin/bash\ncat > "%s/clipboard"\n' "$TEST_TMP" > "$STUB/pbcopy"
chmod +x "$STUB/pbcopy"

run() {
    (PATH="$STUB:$PATH" DOTFILES_STATE_DIR="$STATE" bash "$ROOT/bin/dotfiles-debug" "$@" 2>&1)
}

section "report sections"
out=$(run --print)
for h in Machine Repo Theme Toggles Waiting "Managed links" "Health check" "Last update transcript (tail)"; do
    assert_contains "$out" "=== $h ===" "section: $h"
done
assert_matches "$out" "^  macOS: *[0-9]" "macOS version"
assert_matches "$out" "^  /bin/bash: *GNU bash, version 3.2" "stock bash version"
assert_contains "$out" "revision:  $(git -C "$ROOT" rev-parse --short HEAD)" "repo revision"
assert_matches "$out" "^  commands: *[0-9][0-9]" "command count"
assert_contains "$out" "active:    tokyo-night (mode: ?)" "default theme, no rendered mode, in a fresh HOME"
assert_contains "$out" "themes:    aura" "bundled themes listed"
assert_contains "$out" "migrations: 1788379760-palette-first-theming.sh" "pending migrations listed (fresh state dir)"
assert_contains "$out" "restarts:   none" "no restart markers"
assert_contains "$out" "updates:    not checked yet" "update cache absent"
assert_matches "$out" "^  \.zshrc *MISSING$" "a managed link that is absent is reported as MISSING"
assert_not_contains "$out" $'\033[' "health check output has no colour codes"
assert_contains "$out" "no update has run on this machine yet" "transcript section handles no log"

section "link states"
mkdir -p "$HOME/.config" "$HOME/bin"
ln -s "$ROOT/.zshrc" "$HOME/.zshrc"
ln -s "/nowhere/.gitconfig" "$HOME/.gitconfig"
echo "x" > "$HOME/.rubocop.yml"
out=$(run --print)
assert_matches "$out" "^  \.zshrc *ok$" "correct link is ok"
assert_matches "$out" "^  \.gitconfig *DANGLING -> /nowhere/.gitconfig$" "dangling link named with its target"
assert_matches "$out" "^  \.rubocop\.yml *REAL FILE" "a real file in the way is reported"

section "optional agent links"
assert_not_contains "$out" ".codex/skills" "no Codex link reported when ~/.codex is absent"
mkdir -p "$HOME/.codex"
out=$(run --print)
assert_matches "$out" "agents/skills/dotfiles -> \.codex/skills/dotfiles *MISSING" "Codex skill link appears once ~/.codex exists"

section "file and clipboard"
out=$(run)
assert_file_exists "$STATE/debug.log" "debug.log written"
assert_contains "$out" "Wrote $STATE/debug.log" "names the file"
assert_contains "$out" "Copied to the clipboard" "copies it"
assert_file_contains "$TEST_TMP/clipboard" "=== Machine ===" "clipboard has the report"
assert_file_contains "$STATE/debug.log" "=== Health check ===" "file has the report"
rm -f "$TEST_TMP/clipboard"
out=$(run --no-copy)
assert_not_contains "$out" "Copied" "--no-copy leaves the clipboard alone"
assert_file_not_exists "$TEST_TMP/clipboard" "pbcopy not called"

section "arguments"
set +e; out=$(run --bogus); rc=$?; set -e
assert_eq "$rc" "2" "unknown option exits 2"
out=$(run --help)
assert_contains "$out" "--print" "--help describes the flags"
