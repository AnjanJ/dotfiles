#!/usr/bin/env bash

# ============================================
# MENU TEST SUITE
# ============================================
# bin/dotfiles-menu: the row listings per route (label<TAB>command),
# theme rows marking the active theme and its mode, toggle rows with
# state, launcher rows from the installed bundles, the commands route
# built from `dotfiles commands --plain`, --run (dry) and the numbered
# fallback picker. fzf is never used: DOTFILES_MENU_NO_FZF is set.
#
# Usage: tests/run menu   (or /opt/homebrew/bin/bash tests/menu-test.sh)
# ============================================

set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

M="$ROOT/bin/dotfiles-menu"
export DOTFILES_MENU_DRY=1
export DOTFILES_MENU_NO_FZF=1
export DOTFILES_STATE_DIR="$HOME/.local/state/dotfiles"
export DOTFILES_LAUNCHER_APPS_DIR="$TEST_TMP/Applications"
mkdir -p "$DOTFILES_LAUNCHER_APPS_DIR"
echo "catppuccin" > "$HOME/.dotfiles-theme"

label_of() { cut -f1; }
command_of_label() { awk -F'\t' -v l="$1" '$1 == l { print $2 }'; }

echo ""
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║   Menu Tests                                              ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""

section "Test 1: Root rows"
root_rows="$("$M" --list)"
assert_contains "$root_rows" "Theme ▸	menu:theme" "Theme submenu row"
assert_contains "$root_rows" "Toggles ▸	menu:toggle" "Toggles submenu row"
assert_contains "$root_rows" "Launchers ▸	menu:launchers" "Launchers submenu row"
assert_contains "$root_rows" "Reminder ▸	menu:reminder" "Reminder submenu row"
assert_contains "$root_rows" "Health check	dotfiles health" "health row is a shell command"
assert_contains "$root_rows" "All commands ▸	menu:commands" "commands submenu row"
assert_eq "$("$M" root --list)" "$root_rows" "root can be named"
echo ""

section "Test 2: Theme rows mark the active theme and its mode"
theme="$("$M" theme --list)"
assert_contains "$theme" "* Switch to catppuccin (dark)	dotfiles theme catppuccin" "active theme starred"
assert_contains "$theme" "  Switch to catppuccin-latte (light)	dotfiles theme catppuccin-latte" "light theme shows its mode"
assert_contains "$theme" "  Switch to tokyo-night (dark)	dotfiles theme tokyo-night" "other themes unstarred"
assert_contains "$theme" "Background: next	dotfiles theme bg next" "background row"
assert_contains "$theme" "Add a theme (scaffold)	menu:prompt:add-theme" "prompt row"
echo ""

section "Test 3: Toggle rows carry the state"
"$ROOT/bin/dotfiles-toggle" borders off >/dev/null
toggles="$("$M" toggle --list)"
assert_contains "$toggles" "borders: off	dotfiles toggle borders toggle" "off flag"
assert_contains "$toggles" "startup-apps: on	dotfiles toggle startup-apps toggle" "on flag"
assert_eq "$("$M" toggles --list)" "$toggles" "toggles alias"
echo ""

section "Test 4: Launcher rows list installed bundles"
launchers="$("$M" launchers --list)"
assert_contains "$launchers" "Install a web app (Chrome --app)	menu:prompt:webapp" "install prompt row"
assert_not_contains "$launchers" "Remove web app" "nothing to remove yet"
DOTFILES_LAUNCHER_NO_REGISTER=1 "$ROOT/bin/dotfiles-webapp-install" "Gmail Test" https://mail.google.com --no-icon >/dev/null 2>&1 \
    || true   # the AeroSpace rule step needs no repo edit here (no --float/--workspace)
launchers="$("$M" launchers --list)"
assert_contains "$launchers" "Remove web app: Gmail Test (https://mail.google.com)	dotfiles webapp remove \"Gmail Test\"" "installed web app listed for removal"
echo ""

section "Test 5: Commands route mirrors dotfiles commands --plain"
cmds="$("$M" commands --list)"
assert_contains "$cmds" "health — " "a command with its summary"
assert_contains "$cmds" "	dotfiles health" "…runs through the router"
assert_contains "$cmds" "theme bg — " "nested routes appear with spaces"
n_menu="$(printf '%s\n' "$cmds" | grep -c .)"
n_cli="$("$ROOT/bin/dotfiles" commands --plain | grep -c .)"
assert_eq "$n_menu" "$n_cli" "one row per command"
echo ""

section "Test 5b: User rows from menu.d"
MENU_D="$HOME/.config/dotfiles/menu.d"
mkdir -p "$MENU_D"
printf '# my rows\nOpen notes\tzed ~/notes\nPersonal/Journal\tzed ~/journal\nPersonal/Weekly review\topen https://example.com/review\nWork Tools/VPN\tvpn up\nHealth check\tdotfiles health --fast\nno tab here\n\tno label\n' > "$MENU_D/10-mine.tsv"
root_rows="$("$M" --list)"
assert_contains "$root_rows" $'Open notes\tzed ~/notes' "an un-nested user row lands on the root menu"
assert_contains "$root_rows" $'Personal ▸\tmenu:personal' "a nested label adds one submenu row"
assert_eq "$(grep -c 'Personal ▸' <<<"$root_rows")" "1" "one submenu row for several nested labels"
assert_contains "$root_rows" $'Work Tools ▸\tmenu:work-tools' "submenu route is the lowercased, dashed prefix"
assert_contains "$root_rows" $'Health check\tdotfiles health --fast' "a label matching a built-in row overrides its command"
assert_eq "$(grep -c '^Health check' <<<"$root_rows")" "1" "without duplicating the row"
assert_eq "$(head -6 <<<"$root_rows" | grep -c 'Health check')" "1" "and keeps its position"
assert_not_contains "$root_rows" "no tab here" "a line without a tab is ignored"
assert_not_contains "$root_rows" "no label" "a line without a label is ignored"
sub="$("$M" personal --list)"
assert_eq "$sub" $'Journal\tzed ~/journal\nWeekly review\topen https://example.com/review' "the submenu lists the nested rows without their prefix"
assert_eq "$("$M" work-tools --run "VPN")" "vpn up" "--run works in a user submenu"
assert_eq "$("$M" root --run "Open notes")" "zed ~/notes" "--run works for a root user row"
set +e; out=$("$M" nothing-here --list 2>&1); rc=$?; set -e
assert_eq "$rc" "1" "a prefix nobody uses is still an unknown menu"
assert_contains "$out" "menu.d" "and the error mentions where submenus come from"
rm -rf "$MENU_D"
assert_not_contains "$("$M" --list)" "Personal" "rows disappear with the file"
echo ""

section "Test 6: --run resolves a label to its command (dry)"
assert_eq "$("$M" theme --run "  Switch to tokyo-night (dark)")" "dotfiles theme tokyo-night" "theme row"
assert_eq "$("$M" reminder --run "In 25 minutes (pomodoro)")" 'dotfiles reminder 25 "Pomodoro done"' "quoted argument preserved"
assert_contains "$("$M" root --run "Theme ▸")" "opens the 'theme' menu" "submenu row explains itself"
set +e; out=$("$M" theme --run "nope" 2>&1); rc=$?; set -e
assert_eq "$rc" "1" "unknown label fails"
assert_contains "$out" "No row 'nope'" "…and says so"
set +e; out=$("$M" bogus --list 2>&1); rc=$?; set -e
assert_eq "$rc" "1" "unknown route fails"
assert_contains "$out" "Unknown menu 'bogus'" "…and lists the routes"
echo ""

section "Test 7: Prompt rows build a command from answers"
out="$(printf 'Notes\nnotes.example.com\n' | "$M" launchers --run "Install a web app (Chrome --app)")"
assert_eq "$out" 'dotfiles webapp install "Notes" "notes.example.com" --float' "web app prompt"
out="$(printf '7\nStretch\n' | "$M" reminder --run "Custom…")"
assert_eq "$out" 'dotfiles reminder 7 "Stretch"' "reminder prompt with message"
out="$(printf '9\n\n' | "$M" reminder --run "Custom…")"
assert_eq "$out" 'dotfiles reminder 9' "reminder prompt without message"
set +e; printf 'abc\n\n' | "$M" reminder --run "Custom…" >/dev/null 2>&1; rc=$?; set -e
assert_eq "$rc" "1" "bad minutes rejected"
echo ""

section "Test 8: Numbered fallback picker (no fzf)"
out="$(printf '2\n' | "$M" reminder 2>/dev/null)"
assert_eq "$out" "dotfiles reminder 15" "second row chosen by number"
out="$(printf '1\n1\n' | "$M" 2>/dev/null)"
assert_eq "$out" "dotfiles theme aura" "descends from root into theme and picks the first row"
out="$(printf '\n' | "$M" reminder 2>/dev/null)"
assert_eq "$out" "" "Enter cancels"
echo ""

section "Test 9: Runs under /bin/bash 3.2"
set +e; out=$(/bin/bash "$M" reminder --list 2>&1); rc=$?; set -e
assert_eq "$rc" "0" "lists under /bin/bash"
assert_contains "$out" "In 5 minutes	dotfiles reminder 5" "rows intact"
echo ""
