#!/usr/bin/env bash

# ============================================
# THEME INSTALL TEST SUITE
# ============================================
# `dotfiles theme install <git-url>` and `dotfiles theme remove`, plus
# what apply-theme does with a cloned theme: only colour data is staged
# (nvim/*.lua, code-capable overrides and symlinks are dropped and
# named), theme.conf is parsed rather than sourced, and Neovim falls
# back to the palette-driven "dotfiles" colorscheme. The "remote" is a
# local git repo built here; nothing leaves the sandbox.
#
# Usage: tests/run theme-install   (or /opt/homebrew/bin/bash tests/theme-install-test.sh)
# ============================================

set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

require_command git

# Mock repo with the real theme machinery
MOCK="$TEST_TMP/dotfiles"
mkdir -p "$MOCK/scripts" "$MOCK/bin"
cp -r "$ROOT/themes" "$MOCK/themes"
for f in theme-utils.sh theme-render.sh theme-background.sh apply-theme.sh _helpers.sh; do
    cp "$ROOT/scripts/$f" "$MOCK/scripts/"
done
for b in dotfiles-theme-install dotfiles-theme-remove dotfiles-theme dotfiles-toggle dotfiles-hook; do
    cp "$ROOT/bin/$b" "$MOCK/bin/"
done
mkdir -p "$MOCK/.config/ghostty" "$MOCK/.config/zellij" "$MOCK/.config/sketchybar" "$MOCK/.config/borders" "$MOCK/.config/zed"
echo '{"theme": {"mode": "dark", "dark": "old-theme"}}' > "$MOCK/.config/zed/settings.json"
export DOTFILES_DIR="$MOCK"
export DOTFILES_STATE_DIR="$HOME/.local/state/dotfiles"
export DOTFILES_USER_THEMES_DIR="$HOME/.config/dotfiles/themes"
RENDERED="$DOTFILES_STATE_DIR/current/theme"
INSTALL="$MOCK/bin/dotfiles-theme-install"
REMOVE="$MOCK/bin/dotfiles-theme-remove"
MARKER="$TEST_TMP/theme-conf-was-sourced"

# A stranger's theme repo: a palette plus everything a theme must not
# be allowed to run
REMOTE="$TEST_TMP/omarchy-inky-theme"
mkdir -p "$REMOTE/nvim" "$REMOTE/overrides" "$REMOTE/backgrounds" "$REMOTE/bat"
cat > "$REMOTE/colors.toml" <<'EOF'
mode = "dark"
background = "#101820"
foreground = "#e6e1cf"
accent = "#ffb454"
red = "#f07178"
green = "#aad94c"
yellow = "#ffb454"
blue = "#59c2ff"
magenta = "#d2a6ff"
cyan = "#95e6cb"
EOF
cat > "$REMOTE/theme.conf" <<EOF
# a theme.conf that also tries to run something when sourced
touch "$MARKER"
nvim_colorscheme="inky"
vscode_theme="Inky"
zed_theme="Inky Dark"   # trailing comment is fine
bat_theme="ansi"
delta_theme="ansi"
warp_theme="\$(touch $MARKER)"
EOF
echo 'return { "evil/plugin", config = function() os.execute("touch '"$MARKER"'") end }' > "$REMOTE/nvim/inky-theme.lua"
printf 'command = /bin/sh -c "touch %s"\nbackground = #101820\n' "$MARKER" > "$REMOTE/overrides/ghostty"
printf '{\n  "name": "inky-override",\n  "base": "dark"\n}\n' > "$REMOTE/overrides/claude.json"
ln -s /etc/passwd "$REMOTE/overrides/lsd.yaml"
printf 'PNG?' > "$REMOTE/backgrounds/1-ink.png"
ln -s /etc/hosts "$REMOTE/backgrounds/2-link.jpg"
printf '<plist/>' > "$REMOTE/bat/inky.tmTheme"
echo 'evil' > "$REMOTE/install.sh"
git -C "$REMOTE" init -q
git -C "$REMOTE" -c user.name=t -c user.email=t@t add -A
git -C "$REMOTE" -c user.name=t -c user.email=t@t commit -q -m "theme"

echo ""
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║   Theme Install Tests                                     ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""

section "Test 1: URL and name validation"
set +e; out=$("$INSTALL" 2>&1); rc=$?; set -e
assert_eq "$rc" "1" "no URL shows usage"
set +e; out=$("$INSTALL" --upload-pack=evil 2>&1); rc=$?; set -e
assert_eq "$rc" "1" "option-like URL refused"
assert_contains "$out" "Refusing URL" "…and says so"
set +e; out=$("$INSTALL" "ext::sh -c evil" 2>&1); rc=$?; set -e
assert_eq "$rc" "1" "ext:: transport refused"
set +e; out=$("$INSTALL" "file://$TEST_TMP/omarchy-tokyo-night-theme" --no-apply 2>&1); rc=$?; set -e
assert_eq "$rc" "1" "a name shipped with the repo is refused"
assert_contains "$out" "shipped with the repo" "…and explains"
set +e; out=$("$INSTALL" "file://$TEST_TMP/does-not-exist" --no-apply 2>&1); rc=$?; set -e
assert_eq "$rc" "1" "clone failure fails"
assert_contains "$out" "Could not clone" "…and says so"
assert_dir_not_exists "$DOTFILES_USER_THEMES_DIR/does-not-exist" "nothing left behind"
echo ""

section "Test 2: Install clones into the user themes dir"
set +e; out=$("$INSTALL" "file://$REMOTE" --no-apply 2>&1); rc=$?; set -e
assert_eq "$rc" "0" "install exits 0"
assert_contains "$out" "Installed inky → $DOTFILES_USER_THEMES_DIR/inky" "name derived from the URL (omarchy- prefix and -theme suffix stripped)"
assert_file_exists "$DOTFILES_USER_THEMES_DIR/inky/colors.toml" "clone has the palette"
assert_dir_exists "$DOTFILES_USER_THEMES_DIR/inky/.git" "clone is marked by .git"
assert_contains "$out" "Apply with: dotfiles theme inky" "--no-apply tells how to apply"
assert_contains "$(DOTFILES_DIR="$MOCK" bash -c 'source "$DOTFILES_DIR/scripts/theme-utils.sh"; echo "${VALID_THEMES[*]}"')" "inky" "installed theme discovered"
echo ""

section "Test 3: Applying a cloned theme stages colour data only"
set +e; out=$(DOTFILES_NO_APPEARANCE=1 DOTFILES_NO_BACKGROUND=1 bash "$MOCK/scripts/apply-theme.sh" inky 2>&1); rc=$?; set -e
assert_eq "$rc" "0" "apply exits 0"
assert_file_not_exists "$MARKER" "nothing from the theme ran (theme.conf parsed, nvim spec dropped, ghostty override dropped)"
assert_contains "$out" "staging colour data only" "cloned theme announced"
assert_contains "$out" "nvim" "dropped list names nvim/"
assert_contains "$out" "overrides/ghostty" "dropped list names the ghostty override"
assert_contains "$out" "overrides/lsd.yaml (symlink)" "symlinked override dropped"
assert_contains "$out" "backgrounds/2-link.jpg" "symlinked background dropped"
assert_contains "$out" "install.sh" "unknown file dropped"
assert_file_contains "$RENDERED/ghostty" "background = #101820" "ghostty rendered from the template, not the override"
assert_file_not_contains "$RENDERED/ghostty" "command =" "no command line from the override"
assert_file_contains "$RENDERED/claude.json" '"name": "inky-override"' "claude.json override kept (colour data)"
assert_file_contains "$RENDERED/nvim.lua" 'colorscheme = "dotfiles"' "Neovim uses the palette-driven fallback colorscheme"
assert_file_contains "$RENDERED/nvim.lua" 'plugin_spec = "'"$MOCK"'/themes/_shared/nvim/dotfiles-theme.lua"' "plugin spec is the shared fallback"
assert_file_exists "$RENDERED/nvim-dotfiles-theme/colors/dotfiles.lua" "fallback colorscheme installed beside the palette"
assert_file_contains "$RENDERED/nvim.lua" 'red = "#f07178"' "full palette rendered for the fallback"
assert_eq "$(jq -r .theme.dark "$MOCK/.config/zed/settings.json")" "Inky Dark" "zed_theme parsed from theme.conf (with its trailing comment)"
assert_file_exists "$HOME/.config/bat/config" "bat config written"
assert_eq "$(cat "$HOME/.dotfiles-theme")" "inky" "state records the installed theme"
assert_contains "$out" "Dropped from $DOTFILES_USER_THEMES_DIR/inky" "warning names the source dir"
echo ""

section "Test 4: Backgrounds of an installed theme are found"
# shellcheck source=/dev/null
source "$MOCK/scripts/theme-utils.sh"
# shellcheck source=/dev/null
source "$MOCK/scripts/theme-render.sh"
# shellcheck source=/dev/null
source "$MOCK/scripts/theme-background.sh"
srcs="$(theme_background_sources inky)"
assert_contains "$srcs" "$DOTFILES_USER_THEMES_DIR/inky/backgrounds/1-ink.png" "tracked background of the installed theme listed"
echo ""

section "Test 5: A hand-written user theme is trusted"
mkdir -p "$DOTFILES_USER_THEMES_DIR/mine/nvim"
cp "$REMOTE/colors.toml" "$DOTFILES_USER_THEMES_DIR/mine/colors.toml"
printf 'nvim_colorscheme="x"\nvscode_theme="x"\nzed_theme="x"\nbat_theme="ansi"\ndelta_theme="ansi"\n' > "$DOTFILES_USER_THEMES_DIR/mine/theme.conf"
echo 'return {}' > "$DOTFILES_USER_THEMES_DIR/mine/nvim/mine-theme.lua"
set +e; out=$(DOTFILES_NO_APPEARANCE=1 DOTFILES_NO_BACKGROUND=1 bash "$MOCK/scripts/apply-theme.sh" mine 2>&1); rc=$?; set -e
assert_eq "$rc" "0" "hand-written user theme applies"
assert_not_contains "$out" "colour data only" "not treated as cloned"
assert_file_contains "$RENDERED/nvim.lua" 'colorscheme = "x"' "its own nvim spec and colorscheme are used"
echo ""

section "Test 6: Reinstall replaces a clone; a theme without theme.conf gets one"
set +e; out=$("$INSTALL" "file://$REMOTE" --no-apply 2>&1); rc=$?; set -e
assert_eq "$rc" "0" "reinstall exits 0"
assert_contains "$out" "Replacing installed theme 'inky'" "says it replaced"
BARE="$TEST_TMP/plain-palette"
mkdir -p "$BARE"
cp "$REMOTE/colors.toml" "$BARE/"
git -C "$BARE" init -q && git -C "$BARE" -c user.name=t -c user.email=t@t add -A && git -C "$BARE" -c user.name=t -c user.email=t@t commit -q -m p
set +e; out=$("$INSTALL" "file://$BARE" --no-apply 2>&1); rc=$?; set -e
assert_eq "$rc" "0" "palette-only repo installs"
assert_file_contains "$DOTFILES_USER_THEMES_DIR/plain-palette/theme.conf" 'nvim_colorscheme="dotfiles"' "minimal theme.conf written"
set +e; DOTFILES_NO_APPEARANCE=1 DOTFILES_NO_BACKGROUND=1 bash "$MOCK/scripts/apply-theme.sh" plain-palette >/dev/null 2>&1; rc=$?; set -e
assert_eq "$rc" "0" "…and applies with empty editor names"
assert_eq "$(jq -r .theme.dark "$MOCK/.config/zed/settings.json")" "x" "Zed left alone when zed_theme is empty (still the hand-written theme's)"
NOPAL="$TEST_TMP/no-palette"
mkdir -p "$NOPAL" && echo x > "$NOPAL/README.md"
git -C "$NOPAL" init -q && git -C "$NOPAL" -c user.name=t -c user.email=t@t add -A && git -C "$NOPAL" -c user.name=t -c user.email=t@t commit -q -m p
set +e; out=$("$INSTALL" "file://$NOPAL" --no-apply 2>&1); rc=$?; set -e
assert_eq "$rc" "1" "repo without colors.toml refused"
assert_dir_not_exists "$DOTFILES_USER_THEMES_DIR/no-palette" "…and removed again"
echo ""

section "Test 7: Remove"
assert_contains "$("$REMOVE" --list)" "inky" "list shows installed themes"
assert_contains "$("$REMOVE" --list)" "(cloned)" "…marked as cloned"
assert_contains "$("$REMOVE" --list)" "mine" "…and hand-written ones"
set +e; out=$("$REMOVE" plain-palette 2>&1); rc=$?; set -e
assert_eq "$rc" "1" "active theme cannot be removed"
assert_contains "$out" "is the active theme" "…and says why"
echo "mine" > "$HOME/.dotfiles-theme"
set +e; out=$("$REMOVE" plain-palette 2>&1); rc=$?; set -e
assert_eq "$rc" "0" "inactive installed theme removed"
assert_dir_not_exists "$DOTFILES_USER_THEMES_DIR/plain-palette" "directory gone"
set +e; out=$("$REMOVE" tokyo-night 2>&1); rc=$?; set -e
assert_eq "$rc" "1" "repo theme refused"
set +e; out=$("$REMOVE" nope 2>&1); rc=$?; set -e
assert_eq "$rc" "1" "unknown theme refused"
echo ""

section "Test 8: Runs under /bin/bash 3.2"
set +e; out=$(/bin/bash "$REMOVE" --list 2>&1); rc=$?; set -e
assert_eq "$rc" "0" "remove --list under /bin/bash"
set +e; DOTFILES_NO_APPEARANCE=1 DOTFILES_NO_BACKGROUND=1 /bin/bash "$MOCK/scripts/apply-theme.sh" inky >/dev/null 2>&1; rc=$?; set -e
assert_eq "$rc" "0" "cloned theme applies under /bin/bash"
assert_file_not_exists "$MARKER" "still nothing ran"
echo ""
