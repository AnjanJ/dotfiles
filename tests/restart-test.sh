#!/usr/bin/env bash

# ============================================
# RESTART MARKER TEST SUITE
# ============================================
# bin/dotfiles-restart: restart a component now, mark one for later,
# consume every marker, list them. aerospace/sketchybar/borders/pgrep/
# pkill are stubs that log their arguments; RUNNING says which
# processes the pgrep stub reports as alive.
#
# Usage: tests/run restart   (or /opt/homebrew/bin/bash tests/restart-test.sh)
# ============================================

set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

R="$ROOT/bin/dotfiles-restart"
STATE="$TEST_TMP/state"
export DOTFILES_STATE_DIR="$STATE"

STUB="$TEST_TMP/stub"
LOG="$TEST_TMP/calls.log"
mkdir -p "$STUB"
: > "$LOG"

for cmd in aerospace sketchybar pkill borders; do
    cat > "$STUB/$cmd" <<EOF
#!/bin/bash
echo "$cmd \$*" >> "$LOG"
EOF
    chmod +x "$STUB/$cmd"
done
# pgrep: alive when the last argument names something in RUNNING,
# case-insensitively when -i is among the flags (AeroSpace vs aerospace).
cat > "$STUB/pgrep" <<'EOF'
#!/bin/bash
name="${*: -1}"
flags="${*:1:$#-1}"
for r in ${RUNNING:-}; do
    if [[ "$flags" == *i* ]]; then
        [[ "$(echo "$r" | tr '[:upper:]' '[:lower:]')" == "$(echo "$name" | tr '[:upper:]' '[:lower:]')" ]] && exit 0
    else
        [[ "$r" == "$name" ]] && exit 0
    fi
done
exit 1
EOF
chmod +x "$STUB/pgrep"
export PATH="$STUB:$PATH"

marker() { echo "$STATE/restart-$1-required"; }
reset() { rm -rf "$STATE"; : > "$LOG"; }
# The borders relaunch is backgrounded; give it up to 5s to reach the log
# rather than a fixed sleep (0.5s was not enough on a busy laptop).
wait_for_log() {
    local i=0
    while [[ $i -lt 50 ]] && ! grep -q "$1" "$LOG"; do sleep 0.1; i=$((i + 1)); done
}

echo ""
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║   Restart Marker Tests                                    ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""

section "Test 1: Markers"
reset
set +e; "$R" --list >/dev/null; rc=$?; set -e
assert_eq "$rc" "1" "--list exits 1 with nothing pending"
"$R" --later sketchybar
assert_file_exists "$(marker sketchybar)" "--later drops restart-sketchybar-required"
"$R" --later aerospace
assert_eq "$("$R" --list | tr '\n' ' ')" "aerospace sketchybar " "--list prints marked components in order"
set +e; "$R" --later bogus >/dev/null 2>&1; rc=$?; set -e
assert_eq "$rc" "1" "--later rejects an unknown component"
assert_file_not_exists "$(marker bogus)" "no marker for an unknown component"
echo ""

section "Test 2: --pending restarts what is marked and running"
RUNNING="AeroSpace sketchybar" "$R" --pending >/dev/null
assert_file_contains "$LOG" "^aerospace reload-config$" "aerospace reloaded (matched despite AeroSpace spelling)"
assert_file_contains "$LOG" "^sketchybar --reload$" "sketchybar reloaded"
assert_file_not_exists "$(marker aerospace)" "aerospace marker consumed"
assert_file_not_exists "$(marker sketchybar)" "sketchybar marker consumed"
out=$("$R" --pending)
assert_contains "$out" "Nothing marked for restart" "--pending with nothing pending says so"
echo ""

section "Test 3: Not running means clear the marker, touch nothing"
reset
"$R" --later aerospace
out=$(RUNNING="" "$R" --pending)
assert_contains "$out" "aerospace: not running" "reports the component is not running"
assert_file_not_contains "$LOG" "aerospace" "aerospace not invoked"
assert_file_not_exists "$(marker aerospace)" "marker still cleared"
echo ""

section "Test 4: borders is kill-and-relaunch, honouring the toggle"
reset
"$R" --later borders
RUNNING="borders" "$R" --pending >/dev/null
wait_for_log "^borders $"
assert_file_contains "$LOG" "^pkill -x borders$" "borders killed"
assert_file_contains "$LOG" "^borders $" "borders relaunched"
reset
bash "$ROOT/bin/dotfiles-toggle" borders off >/dev/null
"$R" --later borders
out=$(RUNNING="borders" "$R" --pending)
sleep 1   # nothing to wait for: assert the relaunch did not happen
assert_file_contains "$LOG" "^pkill -x borders$" "borders killed when toggled off"
assert_file_not_contains "$LOG" "^borders $" "borders not relaunched when toggled off"
assert_contains "$out" "toggled off" "says why"
bash "$ROOT/bin/dotfiles-toggle" borders on >/dev/null
echo ""

section "Test 5: Restart now"
reset
"$R" --later sketchybar
RUNNING="sketchybar" "$R" sketchybar >/dev/null
assert_file_contains "$LOG" "^sketchybar --reload$" "direct restart reloads"
assert_file_not_exists "$(marker sketchybar)" "direct restart clears a pending marker too"
echo ""

section "Test 6: Argument handling"
set +e; "$R" >/dev/null 2>&1; rc=$?; set -e
assert_eq "$rc" "1" "no arguments exits 1"
set +e; "$R" --bogus >/dev/null 2>&1; rc=$?; set -e
assert_eq "$rc" "1" "unknown flag exits 1"
set +e; "$R" bogus >/dev/null 2>&1; rc=$?; set -e
assert_eq "$rc" "1" "unknown component exits 1"
set +e; "$R" --help >/dev/null; rc=$?; set -e
assert_eq "$rc" "0" "--help exits 0"
set +e; /bin/bash "$R" --list >/dev/null; rc=$?; set -e
assert_eq "$rc" "1" "runs under /bin/bash 3.2"
echo ""
