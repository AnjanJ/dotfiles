#!/usr/bin/env bash

# ============================================
# SKETCHYBAR PLUGINS TEST SUITE
# ============================================
# Runs the memory plugin under /bin/bash 3.2 (the shebang
# sketchybar uses) against fake memory_pressure, sysctl and
# sketchybar, and checks the label, colour and visibility they paint at
# each threshold. The agent-usage plugin has its own suite.
# Usage: tests/run sketchybar-plugins   (or /opt/homebrew/bin/bash tests/sketchybar-plugins-test.sh)
# ============================================
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

PLUGINS="$ROOT/.config/sketchybar/plugins"

FAKEBIN="$HOME/fakebin"
mkdir -p "$FAKEBIN" "$HOME/.config/sketchybar"
export FAKE_SKETCHYBAR_LOG="$HOME/sketchybar.log"

# Distinct values per token, so a test can tell which one a plugin chose
# (the real Aura palette gives yellow and orange the same hex).
cat > "$HOME/.config/sketchybar/colors.sh" <<'C'
export WHITE=0xff000001
export RED=0xff000002
export YELLOW=0xff000003
export ORANGE=0xff000004
export GREEN=0xff000005
C

cat > "$FAKEBIN/sketchybar" <<'F'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$FAKE_SKETCHYBAR_LOG"
F
cat > "$FAKEBIN/memory_pressure" <<'F'
#!/usr/bin/env bash
echo "System-wide memory free percentage: ${FAKE_FREE_PCT}%"
F
cat > "$FAKEBIN/sysctl" <<'F'
#!/usr/bin/env bash
case "$*" in
    "-n kern.memorystatus_vm_pressure_level") echo "$FAKE_PRESSURE_LEVEL" ;;
    "-n vm.swapusage") echo "total = 9216.00M  used = ${FAKE_SWAP}  free = 1290.75M  (encrypted)" ;;
    *) exit 1 ;;
esac
F
cat > "$FAKEBIN/pmset" <<'F'
#!/usr/bin/env bash
echo "Now drawing from '${FAKE_SOURCE}'"
echo " -InternalBattery-0 (id=1)	${FAKE_BATT}%; ${FAKE_STATE}; 0:00 remaining present: true"
F
chmod +x "$FAKEBIN"/*
export PATH="$FAKEBIN:$PATH"
export NAME=item
# Exported once so the plain `VAR=x line=$(paint ...)` assignments below
# reach the fakes (an assignment-only command does not export).
export FAKE_FREE_PCT FAKE_SWAP FAKE_PRESSURE_LEVEL FAKE_SOURCE FAKE_BATT FAKE_STATE

# Runs a plugin and returns the last line it sent to sketchybar.
paint() {
    : > "$FAKE_SKETCHYBAR_LOG"
    /bin/bash "$PLUGINS/$1"
    tail -1 "$FAKE_SKETCHYBAR_LOG"
}

echo ""
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║   Sketchybar Plugins Tests                                ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""

section "Test 1: Memory colour follows the kernel's pressure level"
FAKE_FREE_PCT=60 FAKE_SWAP=7925.25M
FAKE_PRESSURE_LEVEL=1 line=$(paint memory.sh)
assert_contains "$line" "label=40% label.color=0xff000001" "normal pressure is white and hides swap, however much is allocated"
FAKE_PRESSURE_LEVEL=2 line=$(paint memory.sh)
assert_contains "$line" "label=40% ⇄7925M label.color=0xff000003" "warning is yellow and shows swap"
FAKE_PRESSURE_LEVEL=4 line=$(paint memory.sh)
assert_contains "$line" "label=40% ⇄7925M label.color=0xff000002" "critical is red and shows swap"
FAKE_SWAP=1.50G FAKE_PRESSURE_LEVEL=2 line=$(paint memory.sh)
assert_contains "$line" "label=40% ⇄1536M" "swap reported in G becomes MB"
FAKE_SWAP=0.00M FAKE_PRESSURE_LEVEL=2 line=$(paint memory.sh)
assert_contains "$line" "label=40% label.color=0xff000003" "no swap, no swap figure, even under pressure"
FAKE_SWAP=0.00M FAKE_PRESSURE_LEVEL="" line=$(paint memory.sh)
assert_contains "$line" "label=40% label.color=0xff000001" "an unreadable level counts as normal"
FAKE_FREE_PCT="" FAKE_PRESSURE_LEVEL=1 line=$(paint memory.sh)
assert_eq "$line" "" "no reading, nothing painted"
echo ""
