#!/usr/bin/env bash

# ============================================
# SKETCHYBAR PLUGINS TEST SUITE
# ============================================
# Runs the memory, battery, updates and front-app plugins under /bin/bash
# 3.2 (the shebang sketchybar uses) against fake memory_pressure, sysctl,
# pmset, osascript, lsappinfo and sketchybar, and checks the label, colour and visibility they paint at
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

section "Test 2: Battery shows only when on battery or charging"
# Nerd Font glyphs built from their UTF-8 bytes: U+F0E7 bolt, U+F240 full.
BOLT=$(printf '\xef\x83\xa7')
FULL=$(printf '\xef\x89\x80')
FAKE_SOURCE="AC Power" FAKE_BATT=100 FAKE_STATE=charged line=$(paint battery.sh)
assert_eq "$line" "--set item drawing=off" "charged on AC hides the item"
FAKE_SOURCE="AC Power" FAKE_BATT=80 FAKE_STATE="AC attached; not charging" line=$(paint battery.sh)
assert_eq "$line" "--set item drawing=off" "held by optimised charging on AC hides it too"
FAKE_SOURCE="AC Power" FAKE_BATT=87 FAKE_STATE=charging line=$(paint battery.sh)
assert_contains "$line" "drawing=on icon=$BOLT label=" "charging shows it, with the bolt"
assert_contains "$line" "label=87% label.color=0xff000005" "charging keeps the charge colour"
FAKE_SOURCE="AC Power" FAKE_BATT=99 FAKE_STATE="finishing charge" line=$(paint battery.sh)
assert_contains "$line" "drawing=on" "finishing charge counts as charging"
FAKE_SOURCE="Battery Power" FAKE_BATT=100 FAKE_STATE=discharging line=$(paint battery.sh)
assert_contains "$line" "drawing=on icon=$FULL label=100%" "on battery it shows, full icon"
FAKE_SOURCE="Battery Power" FAKE_BATT="" FAKE_STATE="" line=$(paint battery.sh)
assert_eq "$line" "--set item drawing=off" "no battery, no item"
echo ""

section "Test 3: Battery colour bands"
FAKE_SOURCE="Battery Power" FAKE_STATE=discharging
for case in 80:0xff000005:green 79:0xff000004:orange 51:0xff000004:orange 50:0xff000003:yellow 40:0xff000003:yellow 39:0xff000002:red 5:0xff000002:red; do
    pct=${case%%:*}; rest=${case#*:}; color=${rest%%:*}; name=${rest#*:}
    FAKE_BATT=$pct line=$(paint battery.sh)
    assert_contains "$line" "label=${pct}% label.color=$color" "${pct}% is $name"
done
echo ""

section "Test 4: Updates item reads the saved check"
export DOTFILES_STATE_DIR="$HOME/state"
export FAKE_OSASCRIPT_LOG="$HOME/osascript.log"
mkdir -p "$DOTFILES_STATE_DIR"
cat > "$FAKEBIN/osascript" <<'F'
#!/usr/bin/env bash
printf '%s|%s\n' "$*" "${DOTFILES_UPDATES_MSG:-}" >> "$FAKE_OSASCRIPT_LOG"
F
chmod +x "$FAKEBIN/osascript"
line=$(paint updates.sh)
assert_eq "$line" "--set item drawing=off" "no saved check, no item"
printf '# checked 2026-11-21 17:39:28\n' > "$DOTFILES_STATE_DIR/update-available"
line=$(paint updates.sh)
assert_eq "$line" "--set item drawing=off" "nothing waiting hides it"
printf '%s\n' "# checked 2026-11-21 17:39:28" \
    "repo: 3 commits behind origin/main (run: dotfiles update)" \
    "brew: 2 packages outdated (run: dotfiles update)" > "$DOTFILES_STATE_DIR/update-available"
line=$(paint updates.sh)
assert_contains "$line" "drawing=on label=↑ 2 label.color=0xff000003" "two kinds waiting shows ↑ 2 in yellow"
/bin/bash "$PLUGINS/updates.sh" notify
note=$(tail -1 "$FAKE_OSASCRIPT_LOG")
assert_contains "$note" 'with title "dotfiles updates"' "click posts a notification"
assert_contains "$note" "repo: 3 commits behind origin/main (run: dotfiles update) · brew: 2 packages outdated" "listing every waiting item"
assert_not_contains "$note" "tell app" "no application is targeted"
echo ""

section "Test 5: Focused app"
export FAKE_FRONT_APP="Ghostty"
cat > "$FAKEBIN/lsappinfo" <<'F'
#!/usr/bin/env bash
case "$1" in
    front) echo "ASN:0x0-0x1234:" ;;
    info) [[ -n "$FAKE_FRONT_APP" ]] && printf '"%s" ASN:0x0-0x1234: (in front) \n    bundleID=[ NULL ] \n' "$FAKE_FRONT_APP" ;;
esac
exit 0
F
chmod +x "$FAKEBIN/lsappinfo"
line=$(SENDER=front_app_switched INFO="Zed" paint front-app.sh)
assert_eq "$line" "--set item drawing=on label=Zed" "the focus event's name is painted"
line=$(SENDER=forced paint front-app.sh)
assert_eq "$line" "--set item drawing=on label=Ghostty" "the first paint asks lsappinfo"
line=$(SENDER=front_app_switched INFO="" paint front-app.sh)
assert_eq "$line" "--set item drawing=on label=Ghostty" "an event without a name falls back to lsappinfo"
line=$(FAKE_FRONT_APP="" SENDER=forced paint front-app.sh)
assert_eq "$line" "--set item drawing=off" "no name at all hides the item"
echo ""
