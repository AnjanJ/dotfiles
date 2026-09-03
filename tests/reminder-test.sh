#!/usr/bin/env bash

# ============================================
# REMINDER TEST SUITE
# ============================================
# bin/dotfiles-reminder: the launchd agent it writes, scheduling through
# a launchctl stub, show/clear, the --fire path that launchd runs
# (notification via an osascript stub, self-removal, unload), and
# validation. HOME is a sandbox, so ~/Library/LaunchAgents is too.
#
# Usage: tests/run reminder   (or /opt/homebrew/bin/bash tests/reminder-test.sh)
# ============================================

set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

R="$ROOT/bin/dotfiles-reminder"
AGENTS="$HOME/Library/LaunchAgents"
STUB="$TEST_TMP/stub"
LOG="$TEST_TMP/calls.log"
mkdir -p "$STUB"
: > "$LOG"
printf '#!/bin/bash\necho "launchctl $*" >> "%s"\n' "$LOG" > "$STUB/launchctl"
# The message reaches osascript through the environment; log it too
# shellcheck disable=SC2016  # the stub expands these when it runs
printf '#!/bin/bash\necho "osascript $* msg=${DOTFILES_REMINDER_MSG:-}" >> "%s"\n' "$LOG" > "$STUB/osascript"
chmod +x "$STUB/launchctl" "$STUB/osascript"
export PATH="$STUB:$PATH"
UID_NUM="$(id -u)"

plist_of() { local f; for f in "$AGENTS"/com.dotfiles.reminder.*.plist; do [[ -f "$f" ]] && { echo "$f"; return 0; }; done; return 0; }
plist_count() { local f n=0; for f in "$AGENTS"/com.dotfiles.reminder.*.plist; do [[ -f "$f" ]] && n=$((n + 1)); done; echo "$n"; }
pget() { /usr/libexec/PlistBuddy -c "Print $2" "$1"; }

echo ""
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║   Reminder Tests                                          ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""

section "Test 1: Set a reminder"
set +e; out=$("$R" 15 "Tea is ready" 2>&1); rc=$?; set -e
assert_eq "$rc" "0" "exits 0"
assert_contains "$out" "Reminder set: Tea is ready in 15 minute(s) (at " "confirms message, minutes and time"
P="$(plist_of)"
assert_file_exists "$P" "agent plist written under ~/Library/LaunchAgents"
assert_succeeds "plist is valid" plutil -lint -s "$P"
assert_matches "$(basename "$P")" '^com\.dotfiles\.reminder\.[0-9][0-9]*-15m\.plist$' "label carries the set time and minutes"
assert_eq "$(pget "$P" Label)" "$(basename "$P" .plist)" "Label matches the filename"
assert_eq "$(pget "$P" StartInterval)" "900" "StartInterval is minutes*60"
assert_eq "$(pget "$P" DotfilesMessage)" "Tea is ready" "message recorded"
assert_eq "$(pget "$P" 'ProgramArguments:1')" "$(readlink -f "$R")" "program is this script"
assert_eq "$(pget "$P" 'ProgramArguments:2')" "--fire" "run with --fire"
assert_eq "$(pget "$P" 'ProgramArguments:3')" "Tea is ready" "message passed as an argument"
assert_eq "$(pget "$P" 'ProgramArguments:4')" "$P" "plist path passed so the job can remove itself"
assert_eq "$(pget "$P" 'ProgramArguments:5')" "$(basename "$P" .plist)" "label passed so the job can unload itself"
at="$(pget "$P" DotfilesAt)"
delta=$((at - $(date +%s)))
if [[ $delta -ge 890 && $delta -le 900 ]]; then pass "fires about 15 minutes from now"; else fail "fires about 15 minutes from now" "delta=$delta"; fi
assert_file_contains "$LOG" "^launchctl bootstrap gui/$UID_NUM $P$" "agent bootstrapped into the user domain"
echo ""

section "Test 2: Default message, XML escaping"
"$R" 3 >/dev/null
P2="$(echo "$AGENTS"/com.dotfiles.reminder.*-3m.plist)"
assert_eq "$(pget "$P2" DotfilesMessage)" "Your 3 minutes are up" "default message"
"$R" 4 'Call "Bob" & <Ann>' >/dev/null
P3="$(echo "$AGENTS"/com.dotfiles.reminder.*-4m.plist)"
assert_succeeds "plist with quotes and angle brackets is valid" plutil -lint -s "$P3"
assert_eq "$(pget "$P3" DotfilesMessage)" 'Call "Bob" & <Ann>' "message survives XML escaping"
echo ""

section "Test 3: show"
out="$("$R" show)"
assert_contains "$out" "Tea is ready" "lists the first reminder"
assert_contains "$out" "Your 3 minutes are up" "lists the second"
# 14m 5Xs a moment after setting, or exactly 15m within the same second
assert_matches "$out" 'Tea is ready  *in 1[45]m\( [0-9][0-9]*s\)\{0,1\} ([0-9][0-9]:[0-9][0-9])' "shows remaining time and clock time"
echo ""

section "Test 4: --fire posts the notification and cleans up"
: > "$LOG"
label="$(basename "$P" .plist)"
set +e; "$R" --fire "Tea is ready" "$P" "$label"; rc=$?; set -e
assert_eq "$rc" "0" "--fire exits 0"
assert_file_not_exists "$P" "plist removed by the job"
assert_file_contains "$LOG" "display notification" "notification posted via osascript"
assert_file_contains "$LOG" "msg=Tea is ready" "message delivered through the environment"
assert_file_contains "$LOG" "^launchctl bootout gui/$UID_NUM/$label$" "job unloads itself"
assert_not_contains "$("$R" show)" "Tea is ready" "fired reminder no longer listed"
echo ""

section "Test 5: clear"
: > "$LOG"
out="$("$R" clear)"
assert_contains "$out" "Cleared 2 reminder(s)" "reports the count"
assert_eq "$(plist_count)" "0" "all plists removed"
assert_eq "$(grep -c '^launchctl bootout ' "$LOG")" "2" "each agent unloaded"
assert_eq "$("$R" show)" "No reminders pending" "nothing left"
echo ""

section "Test 6: Validation"
set +e; "$R" 0 >/dev/null 2>&1; rc=$?; set -e
assert_eq "$rc" "1" "0 minutes rejected"
set +e; "$R" soon >/dev/null 2>&1; rc=$?; set -e
assert_eq "$rc" "1" "non-numeric minutes rejected"
set +e; out=$("$R" 2>&1); rc=$?; set -e
assert_eq "$rc" "1" "no arguments shows usage"
assert_contains "$out" "Usage: dotfiles reminder" "usage text"
echo ""

section "Test 7: A stale plist (never fired) is not shown"
"$R" 1 stale >/dev/null
PS="$(plist_of)"
/usr/libexec/PlistBuddy -c "Set DotfilesAt $(( $(date +%s) - 60 ))" "$PS"
assert_eq "$("$R" show)" "No reminders pending" "past reminder skipped"
"$R" clear >/dev/null
echo ""

section "Test 8: Runs under /bin/bash 3.2"
set +e; /bin/bash "$R" 2 bash32 >/dev/null; rc=$?; set -e
assert_eq "$rc" "0" "sets a reminder under /bin/bash"
assert_contains "$(/bin/bash "$R" show)" "bash32" "shows it under /bin/bash"
/bin/bash "$R" clear >/dev/null
echo ""
