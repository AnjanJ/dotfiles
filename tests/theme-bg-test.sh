#!/usr/bin/env bash

# ============================================
# THEME BACKGROUND TEST SUITE
# ============================================
# scripts/theme-background.sh and bin/dotfiles-theme-bg: the generated
# palette gradient, candidate order (theme dir, user dir, generated),
# next/set/current/list, the desktoppr and osascript setters, the
# background toggle, and the apply-theme integration (set on a theme
# change only). desktoppr/osascript are stubs that log their arguments.
#
# Usage: tests/run theme-bg   (or /opt/homebrew/bin/bash tests/theme-bg-test.sh)
# ============================================

set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

require_command sips

MOCK="$TEST_TMP/dotfiles"
mkdir -p "$MOCK/scripts" "$MOCK/bin"
cp -r "$ROOT/themes" "$MOCK/themes"
for f in theme-utils.sh theme-render.sh theme-background.sh apply-theme.sh _helpers.sh; do
    cp "$ROOT/scripts/$f" "$MOCK/scripts/"
done
cp "$ROOT/bin/dotfiles-theme-bg" "$ROOT/bin/dotfiles-toggle" "$ROOT/bin/dotfiles-hook" "$MOCK/bin/"
mkdir -p "$MOCK/.config/ghostty" "$MOCK/.config/zellij" "$MOCK/.config/sketchybar" "$MOCK/.config/borders"
export DOTFILES_DIR="$MOCK"
export DOTFILES_STATE_DIR="$HOME/.local/state/dotfiles"
STATE="$DOTFILES_STATE_DIR/current"
LINK="$STATE/background"
USER_BG="$HOME/.config/dotfiles/backgrounds"

STUB="$TEST_TMP/stub"
LOG="$TEST_TMP/setter.log"
mkdir -p "$STUB"
: > "$LOG"
printf '#!/bin/bash\necho "desktoppr $*" >> "%s"\n' "$LOG" > "$STUB/desktoppr"
printf '#!/bin/bash\necho "osascript $*" >> "%s"\n' "$LOG" > "$STUB/osascript"
chmod +x "$STUB/desktoppr" "$STUB/osascript"
export PATH="$STUB:$PATH"
unset DOTFILES_NO_BACKGROUND
export DOTFILES_NO_APPEARANCE=1   # not under test here
export DOTFILES_NO_OPEN=1

BG="$MOCK/bin/dotfiles-theme-bg"
# The command resolves its own location with readlink -f, so paths under
# the mock repo come back canonical (/private/var on macOS).
MOCK_REAL="$(cd "$MOCK" && pwd -P)"
echo "tokyo-night" > "$HOME/.dotfiles-theme"

# A rendered theme, as `dotfiles theme` leaves it (no background yet)
mkdir -p "$STATE/theme"
cp "$ROOT/themes/tokyo-night/colors.toml" "$STATE/theme/colors.toml"
echo "tokyo-night" > "$STATE/theme.name"

echo ""
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║   Theme Background Tests                                  ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""

section "Test 1: A background is generated from the palette"
set +e; out=$("$BG" list 2>&1); rc=$?; set -e
assert_eq "$rc" "1" "list fails before anything exists"
assert_contains "$out" "No background found" "says so"
set +e; out=$("$BG" generate 2>&1); rc=$?; set -e
assert_eq "$rc" "0" "generate exits 0"
assert_file_exists "$STATE/theme/background.png" "background.png written"
assert_contains "$(file -b "$STATE/theme/background.png")" "PNG image data, 2560 x 1600" "2560x1600 PNG"
assert_file_not_exists "$STATE/theme/background.tga" "TGA intermediate removed"
echo ""

section "Test 2: next sets the only candidate and records the link"
set +e; out=$("$BG" next 2>&1); rc=$?; set -e
assert_eq "$rc" "0" "next exits 0"
assert_eq "$(readlink "$LINK")" "$STATE/theme/background.png" "link points at the generated background"
assert_file_contains "$LOG" "^desktoppr $STATE/theme/background.png$" "desktoppr called with the image"
assert_eq "$("$BG" current)" "$STATE/theme/background.png" "current prints it"
assert_contains "$("$BG" list)" "* $STATE/theme/background.png" "list marks it current"
echo ""

section "Test 3: Cycling order: theme dir, user dir, generated, wrap"
mkdir -p "$MOCK/themes/tokyo-night/backgrounds" "$USER_BG/tokyo-night"
cp "$STATE/theme/background.png" "$MOCK/themes/tokyo-night/backgrounds/1-tracked.png"
cp "$STATE/theme/background.png" "$USER_BG/tokyo-night/mine.jpg"
echo "not an image" > "$USER_BG/tokyo-night/notes.txt"
"$BG" next >/dev/null
assert_eq "$(readlink "$LINK")" "$MOCK_REAL/themes/tokyo-night/backgrounds/1-tracked.png" "after the generated one it wraps to the tracked image"
"$BG" next >/dev/null
assert_eq "$(readlink "$LINK")" "$USER_BG/tokyo-night/mine.jpg" "then the user's image"
"$BG" next >/dev/null
assert_eq "$(readlink "$LINK")" "$STATE/theme/background.png" "then the generated one again"
assert_not_contains "$("$BG" list)" "notes.txt" "non-image files are ignored"
echo ""

section "Test 4: set takes any file; the toggle keeps the desktop alone"
: > "$LOG"
set +e; out=$("$BG" set "$TEST_TMP/missing.png" 2>&1); rc=$?; set -e
assert_eq "$rc" "1" "set refuses a missing file"
"$BG" set "$USER_BG/tokyo-night/mine.jpg" >/dev/null
assert_eq "$(readlink "$LINK")" "$USER_BG/tokyo-night/mine.jpg" "set records the file"
assert_file_contains "$LOG" "^desktoppr $USER_BG/tokyo-night/mine.jpg$" "set applies it"
: > "$LOG"
bash "$MOCK/bin/dotfiles-toggle" background off >/dev/null
"$BG" next >/dev/null
assert_eq "$(cat "$LOG")" "" "toggled off: setter not called"
assert_eq "$(readlink "$LINK")" "$STATE/theme/background.png" "toggled off: link still advances"
bash "$MOCK/bin/dotfiles-toggle" background on >/dev/null
: > "$LOG"
DOTFILES_NO_BACKGROUND=1 "$BG" next >/dev/null
assert_eq "$(cat "$LOG")" "" "DOTFILES_NO_BACKGROUND: setter not called"
echo ""

section "Test 5: osascript fallback without desktoppr"
: > "$LOG"
rm "$STUB/desktoppr"
hash -r
PATH="$STUB:/usr/bin:/bin" "$BG" next >/dev/null
assert_file_contains "$LOG" "tell every desktop to set picture to POSIX file" "System Events asked to set the picture"
assert_file_contains "$LOG" "mine.jpg" "with the chosen image"
printf '#!/bin/bash\necho "desktoppr $*" >> "%s"\n' "$LOG" > "$STUB/desktoppr"
chmod +x "$STUB/desktoppr"
hash -r
echo ""

section "Test 6: dir creates the user folder for the theme"
assert_eq "$("$BG" dir)" "$USER_BG/tokyo-night" "prints the folder"
echo "catppuccin" > "$HOME/.dotfiles-theme"
"$BG" dir >/dev/null
assert_dir_exists "$USER_BG/catppuccin" "creates it for the active theme"
echo "tokyo-night" > "$HOME/.dotfiles-theme"
echo ""

section "Test 7: apply-theme sets a background on a theme change only"
rm -rf "$STATE" "$HOME/.dotfiles-theme"
: > "$LOG"
# shellcheck source=/dev/null
source "$MOCK/scripts/theme-utils.sh"
# shellcheck source=/dev/null
source "$MOCK/scripts/apply-theme.sh"
DOTFILES_DIR="$MOCK"
set +e; out=$(apply_theme "catppuccin" "true" 2>&1); rc=$?; set -e
assert_eq "$rc" "0" "apply-theme exits 0"
assert_file_exists "$STATE/theme/background.png" "generated background rendered with the theme"
assert_contains "$out" "Background → background.png" "reports the background"
assert_eq "$(readlink "$LINK")" "$STATE/theme/background.png" "link set to the new theme's gradient"
assert_eq "$(grep -c '^desktoppr ' "$LOG")" "1" "desktop set once"
set +e; apply_theme "catppuccin" "true" >/dev/null 2>&1; set -e
assert_eq "$(grep -c '^desktoppr ' "$LOG")" "1" "re-applying the same theme leaves the desktop alone"
"$BG" set "$USER_BG/tokyo-night/mine.jpg" >/dev/null
set +e; apply_theme "tokyo-night" "true" >/dev/null 2>&1; set -e
assert_eq "$(readlink "$LINK")" "$STATE/theme/background.png" "switching theme picks the candidate after the current one (user image → generated)"
echo ""

section "Test 8: Runs under /bin/bash 3.2"
set +e; out=$(/bin/bash "$BG" current 2>&1); rc=$?; set -e
assert_eq "$rc" "0" "current works under /bin/bash"
set +e; /bin/bash "$BG" generate >/dev/null 2>&1; rc=$?; set -e
assert_eq "$rc" "0" "generate works under /bin/bash"
echo ""
