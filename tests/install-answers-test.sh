#!/usr/bin/env bash

# ============================================
# INSTALL ANSWERS TEST SUITE
# ============================================
# scripts/install-answers.sh: the JSON answers file install.sh reads
# for unattended runs. Precedence (flags and environment beat the file,
# the file beats defaults), arrays and booleans, unknown-key warnings,
# missing and invalid files, and install.sh's own flag/env/default
# handling of the file path (checked with --help, which exits before
# anything is installed).
#
# Usage: tests/run install-answers   (or /opt/homebrew/bin/bash tests/install-answers-test.sh)
# ============================================

set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

LIB="$ROOT/scripts/install-answers.sh"
# shellcheck source=/dev/null
source "$LIB"

reset_vars() {
    GIT_NAME="" GIT_EMAIL="" GIT_WORK_EMAIL="" WORK_DIR="" SELECTED_THEME="" SSH_MODE="" SELECTED_GROUPS=""
    APPLY_MACOS_DEFAULTS=true INSTALL_RUNTIMES=true
}

FULL="$TEST_TMP/full.json"
cat > "$FULL" <<'EOF'
{
  "name": "Answer Person",
  "email": "answers@example.com",
  "work_email": "work@example.com",
  "work_dir": "~/work/src",
  "theme": "catppuccin-latte",
  "ssh": "skip",
  "groups": ["core", "editors"],
  "macos_defaults": false,
  "runtimes": false
}
EOF

echo ""
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║   Install Answers Tests                                   ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""

section "Test 1: Every key lands in its variable"
reset_vars
set +e; out=$(install_answers_load "$FULL" 2>&1); rc=$?; set -e
reset_vars; install_answers_load "$FULL" >/dev/null 2>&1
assert_eq "$rc" "0" "load exits 0"
assert_eq "$GIT_NAME" "Answer Person" "name"
assert_eq "$GIT_EMAIL" "answers@example.com" "email"
assert_eq "$GIT_WORK_EMAIL" "work@example.com" "work_email"
assert_eq "$WORK_DIR" "~/work/src" "work_dir"
assert_eq "$SELECTED_THEME" "catppuccin-latte" "theme"
assert_eq "$SSH_MODE" "skip" "ssh"
assert_eq "$SELECTED_GROUPS" "core,editors" "groups array joined with commas"
assert_eq "$APPLY_MACOS_DEFAULTS" "false" "macos_defaults false"
assert_eq "$INSTALL_RUNTIMES" "false" "runtimes false"
assert_contains "$out" "Answers from $FULL: name, email, work_email, work_dir, theme, ssh, groups, macos_defaults=false, runtimes=false" "reports what it applied"
echo ""

section "Test 2: Flags and environment win over the file"
reset_vars
GIT_NAME="Flag Person"; SELECTED_THEME="aura"; SELECTED_GROUPS="core"
set +e; out=$(install_answers_load "$FULL" 2>&1); set -e
install_answers_load "$FULL" >/dev/null 2>&1
assert_eq "$GIT_NAME" "Flag Person" "name from the flag kept"
assert_eq "$SELECTED_THEME" "aura" "theme from the flag kept"
assert_eq "$SELECTED_GROUPS" "core" "groups from the flag kept"
assert_eq "$GIT_EMAIL" "answers@example.com" "email still filled from the file"
assert_not_contains "$out" "name," "name not reported as applied"
echo ""

section "Test 3: Partial files, strings for groups, booleans as true"
PART="$TEST_TMP/part.json"
printf '{"email": "only@example.com", "groups": "core,ai", "macos_defaults": true, "runtimes": true}\n' > "$PART"
reset_vars
set +e; out=$(install_answers_load "$PART" 2>&1); set -e
install_answers_load "$PART" >/dev/null 2>&1
assert_eq "$GIT_EMAIL" "only@example.com" "email set"
assert_eq "$GIT_NAME" "" "name left empty"
assert_eq "$SELECTED_GROUPS" "core,ai" "groups as a comma string"
assert_eq "$APPLY_MACOS_DEFAULTS" "true" "macos_defaults true leaves the default"
assert_eq "$INSTALL_RUNTIMES" "true" "runtimes true leaves the default"
EMPTY="$TEST_TMP/empty.json"
echo '{}' > "$EMPTY"
reset_vars
set +e; out=$(install_answers_load "$EMPTY" 2>&1); rc=$?; set -e
assert_eq "$rc" "0" "an empty object is fine"
assert_contains "$out" "nothing new" "…and says nothing was applied"
echo ""

section "Test 4: Unknown keys are warned about, not fatal"
TYPO="$TEST_TMP/typo.json"
printf '{"nmae": "x", "email": "t@example.com"}\n' > "$TYPO"
reset_vars
set +e; out=$(install_answers_load "$TYPO" 2>&1); rc=$?; set -e
assert_eq "$rc" "0" "load still exits 0"
assert_contains "$out" "Warning: unknown key 'nmae'" "typo named"
assert_contains "$out" "known: name email" "known keys listed"
echo ""

section "Test 5: Missing or invalid file fails"
reset_vars
set +e; out=$(install_answers_load "$TEST_TMP/nope.json" 2>&1); rc=$?; set -e
assert_eq "$rc" "1" "missing file fails"
assert_contains "$out" "Answers file not found" "…and says so"
BAD="$TEST_TMP/bad.json"
echo '{"name": ' > "$BAD"
set +e; out=$(install_answers_load "$BAD" 2>&1); rc=$?; set -e
assert_eq "$rc" "1" "invalid JSON fails"
assert_contains "$out" "not valid JSON" "…and says so"
echo ""

section "Test 6: install.sh reads the file from --answers, DOTFILES_ANSWERS or ~/.dotfiles-answers.json"
# --help exits after argument parsing, before the answers file is read,
# so a bad --answers must not matter there; a real run reads it before
# touching the machine. Use the bootstrap check: install.sh with a
# missing --answers file must fail at that step with its message.
set +e; out=$(/bin/bash "$ROOT/install.sh" --help 2>&1); rc=$?; set -e
assert_eq "$rc" "0" "--help exits 0"
assert_contains "$out" "--answers <file>" "help documents --answers"
assert_contains "$out" "DOTFILES_ANSWERS" "help documents the env var"
set +e; out=$(DOTFILES_NO_SUDO=1 /bin/bash "$ROOT/install.sh" --answers "$TEST_TMP/nope.json" 2>&1); rc=$?; set -e
assert_eq "$rc" "1" "a missing --answers file stops the install"
assert_contains "$out" "Answers file not found" "…with the loader's message"
set +e; out=$(DOTFILES_NO_SUDO=1 DOTFILES_ANSWERS="$BAD" /bin/bash "$ROOT/install.sh" 2>&1); rc=$?; set -e
assert_eq "$rc" "1" "an invalid DOTFILES_ANSWERS file stops the install"
cp "$BAD" "$HOME/.dotfiles-answers.json"
set +e; out=$(DOTFILES_NO_SUDO=1 /bin/bash "$ROOT/install.sh" 2>&1); rc=$?; set -e
assert_eq "$rc" "1" "an invalid ~/.dotfiles-answers.json stops the install"
assert_contains "$out" "not valid JSON: $HOME/.dotfiles-answers.json" "…naming the default path"
rm -f "$HOME/.dotfiles-answers.json"
echo ""

section "Test 7: Runs under /bin/bash 3.2"
set +e; out=$(/bin/bash -c 'source "$1"; GIT_NAME=""; SELECTED_GROUPS=""; APPLY_MACOS_DEFAULTS=true; INSTALL_RUNTIMES=true; install_answers_load "$2" >/dev/null && echo "$GIT_NAME|$SELECTED_GROUPS|$INSTALL_RUNTIMES"' _ "$LIB" "$FULL" 2>&1); rc=$?; set -e
assert_eq "$rc" "0" "loads under /bin/bash"
assert_eq "$out" "Answer Person|core,editors|false" "values intact under /bin/bash"
echo ""
