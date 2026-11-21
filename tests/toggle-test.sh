#!/usr/bin/env bash
# doc: Toggles — flag files, `--enabled` exit codes, listing

# ============================================
# TOGGLE TEST SUITE
# ============================================
# Tests bin/dotfiles-toggle: default-on semantics, on/off/toggle/status,
# the --enabled exit code contract scripts rely on, --list, and name
# validation. State is kept under a sandbox DOTFILES_STATE_DIR.
# Usage: tests/run toggle   (or /opt/homebrew/bin/bash tests/toggle-test.sh)
# ============================================

set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

REAL_DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
T="$REAL_DOTFILES_DIR/bin/dotfiles-toggle"

STATE=$(mktemp -d)
export DOTFILES_STATE_DIR="$STATE"

echo ""
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║   Toggle Tests                                            ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""

section "Test 1: Everything is on by default"
set +e; "$T" --enabled startup-apps; rc=$?; set -e
assert_eq "$rc" "0" "--enabled exits 0 for an untouched flag"
assert_eq "$("$T" startup-apps status)" "startup-apps: on" "status reports on"
assert_eq "$("$T" never-seen-before status)" "never-seen-before: on" "unknown flags are on too"
echo ""

section "Test 2: off / on / toggle"
assert_eq "$("$T" borders off)" "borders: off" "off reports off"
if [[ -f "$STATE/toggles/borders.off" ]]; then pass "flag file created"; else fail "flag file missing"; fi
set +e; "$T" --enabled borders; rc=$?; set -e
assert_eq "$rc" "1" "--enabled exits 1 when off"
assert_eq "$("$T" borders on)" "borders: on" "on reports on"
if [[ ! -e "$STATE/toggles/borders.off" ]]; then pass "flag file removed"; else fail "flag file still present"; fi
assert_eq "$("$T" borders)" "borders: off" "bare flag toggles (on → off)"
assert_eq "$("$T" borders)" "borders: on" "bare flag toggles back (off → on)"
assert_eq "$("$T" borders toggle)" "borders: off" "explicit toggle"
assert_eq "$("$T" borders off)" "borders: off" "off is idempotent"
echo ""

section "Test 3: --list"
out=$("$T" --list)
if echo "$out" | /usr/bin/grep -q "borders *off"; then pass "--list shows borders off"; else fail "--list missing borders off"; fi
if echo "$out" | /usr/bin/grep -q "startup-apps *on"; then pass "--list shows startup-apps on"; else fail "--list missing startup-apps"; fi
if echo "$out" | /usr/bin/grep -q "auto-commit *on"; then pass "--list shows auto-commit on"; else fail "--list missing auto-commit"; fi
"$T" custom-thing off --custom >/dev/null
out=$("$T" --list)
if echo "$out" | /usr/bin/grep -q "custom-thing *off"; then pass "--list includes ad-hoc flags that are off"; else fail "--list missing custom-thing"; fi
echo ""

section "Test 4: Validation and usage"
set +e; "$T" "Bad Name" off >/dev/null 2>&1; rc=$?; set -e
assert_eq "$rc" "1" "invalid flag name rejected"
set +e; "$T" >/dev/null 2>&1; rc=$?; set -e
assert_eq "$rc" "1" "no arguments exits 1"
set +e; "$T" --help >/dev/null; rc=$?; set -e
assert_eq "$rc" "0" "--help exits 0"
set +e; "$T" borders sideways >/dev/null 2>&1; rc=$?; set -e
assert_eq "$rc" "1" "unknown action rejected"
set +e; /bin/bash "$T" startup-apps status >/dev/null; rc=$?; set -e
assert_eq "$rc" "0" "runs under /bin/bash 3.2"

section "Test 5: Typos are caught, flags of your own need --custom"
set +e; out=$("$T" autocommit off 2>&1); rc=$?; set -e
assert_eq "$rc" "1" "switching off an unknown name is refused"
assert_contains "$out" "Did you mean 'auto-commit'?" "a hyphen dropped from a known flag is suggested"
assert_contains "$out" "dotfiles toggle autocommit off --custom" "and the --custom form is shown"
assert_file_not_exists "$STATE/toggles/autocommit.off" "nothing is written"
set +e; out=$("$T" border off 2>&1); set -e
assert_contains "$out" "Did you mean 'borders'?" "a known flag that starts with the name is suggested"
set +e; out=$("$T" nothing-like-it off 2>&1); rc=$?; set -e
assert_eq "$rc" "1" "a name close to no known flag is refused too"
assert_not_contains "$out" "Did you mean" "without a guess"
set +e; "$T" autocommit >/dev/null 2>&1; rc=$?; set -e
assert_eq "$rc" "1" "a bare unknown name (which would switch it off) is refused"
assert_eq "$("$T" my-flag off --custom)" "my-flag: off" "--custom switches a flag of your own off"
assert_eq "$("$T" my-flag --custom status)" "my-flag: off" "--custom works in any position"
set +e; "$T" --enabled my-flag; rc=$?; set -e
assert_eq "$rc" "1" "--enabled reads it like any flag"
assert_eq "$("$T" my-flag on)" "my-flag: on" "switching a flag of your own on needs no --custom"
"$T" my-flag off --custom >/dev/null
assert_eq "$("$T" my-flag)" "my-flag: on" "nor does a bare toggle that turns it back on"
assert_eq "$("$T" auto-commit off)" "auto-commit: off" "known flags need no --custom"
"$T" auto-commit on >/dev/null
set +e; /bin/bash "$T" autocommit off >/dev/null 2>&1; rc=$?; set -e
assert_eq "$rc" "1" "the check runs under /bin/bash 3.2"
assert_eq "$(/bin/bash "$T" my-flag off --custom)" "my-flag: off" "and so does --custom"
