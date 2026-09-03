#!/usr/bin/env bash

# ============================================
# THEME SYSTEM TEST SUITE
# ============================================
# Tests that apply-theme.sh renders themes/<name>/colors.toml through
# themes/_templates into ~/.local/state/dotfiles/current/theme/, swaps
# atomically, installs the generated copies, honours overrides, leaves
# the previous theme intact on failure, and that add-theme scaffolds a
# theme that actually applies.
#
# Uses a temporary directory — no real configs touched.
# Usage: tests/run theme   (or /opt/homebrew/bin/bash tests/theme-test.sh)
# ============================================

set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

REAL_DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REAL_HOME="$HOME"

# ── Mock Setup ────────────────────────────────

# Build a mock DOTFILES_DIR with real theme data and the config dirs the
# generated copies land in. HOME is a sandbox, so the rendered state dir
# and every file installed outside the repo stay inside it.
setup_theme_sandbox() {
    MOCK_DOTFILES=$(mktemp -d)
    TEST_HOME=$(mktemp -d)
    export HOME="$TEST_HOME"
    unset DOTFILES_STATE_DIR

    cp -r "$REAL_DOTFILES_DIR/themes" "$MOCK_DOTFILES/themes"
    mkdir -p "$MOCK_DOTFILES/scripts" "$MOCK_DOTFILES/bin"
    cp "$REAL_DOTFILES_DIR/scripts/theme-utils.sh" "$MOCK_DOTFILES/scripts/"
    cp "$REAL_DOTFILES_DIR/scripts/theme-render.sh" "$MOCK_DOTFILES/scripts/"
    cp "$REAL_DOTFILES_DIR/scripts/apply-theme.sh" "$MOCK_DOTFILES/scripts/"
    cp "$REAL_DOTFILES_DIR/scripts/_helpers.sh" "$MOCK_DOTFILES/scripts/"
    cp "$REAL_DOTFILES_DIR/bin/dotfiles-hook" "$MOCK_DOTFILES/bin/"

    mkdir -p "$MOCK_DOTFILES/.config/ghostty" "$MOCK_DOTFILES/.config/zellij" \
             "$MOCK_DOTFILES/.config/sketchybar" "$MOCK_DOTFILES/.config/borders" \
             "$MOCK_DOTFILES/.config/zed"
    echo 'config-file = ?theme.generated' > "$MOCK_DOTFILES/.config/ghostty/config"
    echo '{"theme": {"mode": "dark", "dark": "old-theme"}}' > "$MOCK_DOTFILES/.config/zed/settings.json"

    STATE="$TEST_HOME/.local/state/dotfiles/current"
    RENDERED="$STATE/theme"

    DOTFILES_DIR="$MOCK_DOTFILES"
    export DOTFILES_DIR
}

teardown_theme_sandbox() {
    export HOME="$REAL_HOME"
    unset DOTFILES_DIR
    rm -rf "$MOCK_DOTFILES" "$TEST_HOME"
}

# Helper: source apply-theme.sh in the mock context
load_theme_functions() {
    # shellcheck source=/dev/null
    source "$MOCK_DOTFILES/scripts/theme-utils.sh"
    # shellcheck source=/dev/null
    source "$MOCK_DOTFILES/scripts/apply-theme.sh"
    # Re-override DOTFILES_DIR (apply-theme.sh sets it from BASH_SOURCE)
    DOTFILES_DIR="$MOCK_DOTFILES"
    # shellcheck disable=SC2034  # read by apply-theme.sh
    DOTFILES_STATE_DIR="$TEST_HOME/.local/state/dotfiles"
}

# ── Tests ─────────────────────────────────────

echo ""
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║   Theme System Tests                                      ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""

# ── Test 1: Valid theme renders every template ──
section "Test 1: Valid theme renders every template into the state dir"
setup_theme_sandbox
load_theme_functions

set +e; apply_theme "tokyo-night" "true" >/dev/null 2>&1; rc=$?; set -e
assert_eq "$rc" "0" "apply_theme tokyo-night returns 0"

assert_eq "$(cat "$STATE/theme.name")" "tokyo-night" "theme.name written"
for tpl in "$MOCK_DOTFILES"/themes/_templates/*.tpl; do
    name=$(basename "$tpl" .tpl)
    assert_file_exists "$RENDERED/$name" "rendered $name"
done
assert_file_exists "$RENDERED/colors.toml" "colors.toml copied alongside"
assert_file_not_exists "$STATE/next-theme" "staging dir removed after swap"

assert_file_contains "$RENDERED/ghostty" "background = #1a1b26" "Ghostty background is Tokyo Night"
assert_file_contains "$RENDERED/ghostty" "palette = 4=#7aa2f7" "Ghostty ANSI blue rendered"
assert_file_contains "$RENDERED/starship.toml" 'palette = "dotfiles"' "Starship selects the fixed palette name"
assert_file_contains "$RENDERED/starship.toml" 'accent = "#7aa2f7"' "Starship palette carries the accent"
assert_file_contains "$RENDERED/zellij.kdl" '    dotfiles {' "Zellij theme is named dotfiles"
assert_file_contains "$RENDERED/sketchybar-colors.sh" "ACCENT_COLOR=0xff7aa2f7" "sketchybar accent in ARGB"
assert_file_contains "$RENDERED/borders-colors.sh" "BORDERS_BACKGROUND_COLOR=0x301a1b26" "borders alpha + stripped hex"
assert_file_contains "$RENDERED/nvim.lua" 'colorscheme = "tokyonight"' "nvim.lua carries theme.conf colorscheme"
assert_file_contains "$RENDERED/nvim.lua" "themes/tokyo-night/nvim/tokyo-night-theme.lua" "nvim.lua points at the plugin spec"
assert_file_contains "$RENDERED/claude.json" '"claude": "#7aa2f7"' "Claude theme uses the accent"
assert_file_contains "$RENDERED/delta.gitconfig" "syntax-theme = TwoDark" "delta theme from theme.conf"
assert_file_contains "$RENDERED/bat.conf" '--theme="TwoDark"' "bat theme from theme.conf"
assert_file_not_contains "$RENDERED/claude.json" "{{" "no unresolved tokens in claude.json"

teardown_theme_sandbox
echo ""

# ── Test 2: Generated copies installed where apps read them ──
section "Test 2: Generated copies installed into config dirs and HOME"
setup_theme_sandbox
load_theme_functions

set +e; apply_theme "tokyo-night" "true" >/dev/null 2>&1; set -e

assert_file_exists "$MOCK_DOTFILES/.config/ghostty/theme.generated" "Ghostty theme.generated installed"
assert_file_exists "$MOCK_DOTFILES/.config/zellij/themes/dotfiles.kdl" "Zellij themes/dotfiles.kdl installed"
assert_file_exists "$MOCK_DOTFILES/.config/sketchybar/colors.sh" "sketchybar colors.sh installed"
assert_file_exists "$MOCK_DOTFILES/.config/borders/colors.sh" "borders colors.sh installed"
assert_file_exists "$TEST_HOME/.zshrc-theme-env" "fzf env file installed in HOME"
assert_file_contains "$TEST_HOME/.zshrc-theme-env" "FZF_THEME_COLORS=" "fzf env exports the colour string"
assert_file_contains "$MOCK_DOTFILES/.config/zed/settings.json" '"dark": "Tokyo Night"' "Zed settings updated (best-effort)"
assert_file_not_exists "$TEST_HOME/.claude/themes/dotfiles.json" "Claude theme skipped when ~/.claude is absent"

mkdir -p "$TEST_HOME/.claude"
set +e; apply_theme "aura" "true" >/dev/null 2>&1; set -e
assert_file_exists "$TEST_HOME/.claude/themes/dotfiles.json" "Claude theme installed once ~/.claude exists"
assert_file_contains "$TEST_HOME/.claude/themes/dotfiles.json" '"claude": "#a277ff"' "Claude theme retinted to Aura"

teardown_theme_sandbox
echo ""

# ── Test 3: Overrides beat templates ──
section "Test 3: themes/<name>/overrides/<file> replaces the template output"
setup_theme_sandbox
load_theme_functions

set +e; apply_theme "aura" "true" >/dev/null 2>&1; set -e
# Aura ships overrides/ghostty with its hand-tuned palette 8 and selection
assert_file_contains "$RENDERED/ghostty" "palette = 8=#4d4d4d" "Aura override used for Ghostty"
assert_file_contains "$RENDERED/ghostty" "selection-background = #a277ff" "Aura override keeps accent selection"
assert_file_not_contains "$RENDERED/ghostty" "Generated by" "Override is verbatim, not rendered"
# Other files still come from templates
assert_file_contains "$RENDERED/zellij.kdl" 'bg "#15141b"' "Zellij still rendered from the Aura palette"

# A custom override for another output
mkdir -p "$MOCK_DOTFILES/themes/tokyo-night/overrides"
echo "custom lsd" > "$MOCK_DOTFILES/themes/tokyo-night/overrides/lsd.yaml"
set +e; apply_theme "tokyo-night" "true" >/dev/null 2>&1; set -e
assert_eq "$(cat "$RENDERED/lsd.yaml")" "custom lsd" "Ad-hoc override for lsd.yaml honoured"

teardown_theme_sandbox
echo ""

# ── Test 4: Invalid theme rejected, nothing rendered ──
section "Test 4: Invalid theme rejected"
setup_theme_sandbox
load_theme_functions

set +e; apply_theme "nonexistent-theme" "true" >/dev/null 2>&1; rc=$?; set -e
if [[ $rc -eq 0 ]]; then
    fail "Invalid theme should return non-zero"
else
    pass "Invalid theme returns non-zero exit code"
fi
assert_file_not_exists "$RENDERED" "Nothing rendered for an invalid theme"

teardown_theme_sandbox
echo ""

# ── Test 5: Missing theme.conf / colors.toml error out cleanly ──
section "Test 5: Missing theme.conf or colors.toml errors properly"
setup_theme_sandbox
load_theme_functions

mkdir -p "$MOCK_DOTFILES/themes/broken-theme"
VALID_THEMES+=("broken-theme")
set +e; apply_theme "broken-theme" "true" >/dev/null 2>&1; rc=$?; set -e
if [[ $rc -eq 0 ]]; then
    fail "Missing theme.conf should return non-zero"
else
    pass "Missing theme.conf returns error"
fi

# theme.conf present, colors.toml absent
cp "$MOCK_DOTFILES/themes/tokyo-night/theme.conf" "$MOCK_DOTFILES/themes/broken-theme/"
mkdir -p "$MOCK_DOTFILES/themes/broken-theme/nvim"
cp "$MOCK_DOTFILES/themes/tokyo-night/nvim/tokyo-night-theme.lua" "$MOCK_DOTFILES/themes/broken-theme/nvim/"
set +e; output=$(apply_theme "broken-theme" "true" 2>&1); rc=$?; set -e
if [[ $rc -ne 0 ]] && echo "$output" | /usr/bin/grep -q "colors.toml"; then
    pass "Missing colors.toml is named in the pre-flight error"
else
    fail "Missing colors.toml should fail pre-flight naming the file"
fi

teardown_theme_sandbox
echo ""

# ── Test 6: A failed render leaves the previous theme active ──
section "Test 6: Render failure leaves the previous theme untouched"
setup_theme_sandbox
load_theme_functions

set +e; apply_theme "tokyo-night" "true" >/dev/null 2>&1; set -e
before=$(cat "$RENDERED/ghostty")

# Break the aura palette (no hex background) so rendering fails
sed -i '' 's/^background = .*/background = "not-a-colour"/' "$MOCK_DOTFILES/themes/aura/colors.toml"
set +e; apply_theme "aura" "true" >/dev/null 2>&1; rc=$?; set -e
if [[ $rc -ne 0 ]]; then
    pass "Apply returns non-zero when a template cannot render"
else
    fail "Apply should return non-zero when a template cannot render"
fi
assert_eq "$(cat "$STATE/theme.name")" "tokyo-night" "theme.name still tokyo-night"
assert_eq "$(cat "$RENDERED/ghostty")" "$before" "Rendered Ghostty file unchanged"
assert_eq "$(cat "$TEST_HOME/.dotfiles-theme")" "tokyo-night" "State file still tokyo-night"
assert_file_not_exists "$STATE/next-theme" "Staging dir cleaned up after failure"

# An unresolved token in a template also fails safely
setup_theme_sandbox
load_theme_functions
set +e; apply_theme "tokyo-night" "true" >/dev/null 2>&1; set -e
echo 'x = {{ no_such_key }}' > "$MOCK_DOTFILES/themes/_templates/broken.tpl"
set +e; apply_theme "aura" "true" >/dev/null 2>&1; rc=$?; set -e
if [[ $rc -ne 0 ]]; then
    pass "Unresolved token fails the apply"
else
    fail "Unresolved token should fail the apply"
fi
assert_eq "$(cat "$STATE/theme.name")" "tokyo-night" "Previous theme kept after unresolved token"

teardown_theme_sandbox
echo ""

# ── Test 7: Idempotent — apply same theme twice ──
section "Test 7: Applying the same theme twice is a no-op"
setup_theme_sandbox
load_theme_functions

set +e; apply_theme "tokyo-night" "true" >/dev/null 2>&1; set -e
first=$(cd "$RENDERED" && cat ./*)
set +e; apply_theme "tokyo-night" "true" >/dev/null 2>&1; set -e
second=$(cd "$RENDERED" && cat ./*)
assert_eq "$second" "$first" "Rendered output identical after second apply"

teardown_theme_sandbox
echo ""

# ── Test 8: Theme switch replaces everything ──
section "Test 8: Theme switch (tokyo-night → catppuccin)"
setup_theme_sandbox
load_theme_functions

set +e; apply_theme "tokyo-night" "true" >/dev/null 2>&1; set -e
assert_file_contains "$RENDERED/zellij.kdl" 'bg "#1a1b26"' "Initially Tokyo Night"
set +e; apply_theme "catppuccin" "true" >/dev/null 2>&1; set -e
assert_file_contains "$RENDERED/zellij.kdl" 'bg "#1e1e2e"' "Zellij switched to Catppuccin"
assert_file_contains "$RENDERED/nvim.lua" 'colorscheme = "catppuccin-mocha"' "Neovim colorscheme switched"
assert_file_contains "$MOCK_DOTFILES/.config/sketchybar/colors.sh" "BAR_COLOR=0xff1e1e2e" "sketchybar copy switched"
assert_file_not_contains "$RENDERED/ghostty" "#1a1b26" "No Tokyo Night colours left in Ghostty"
assert_eq "$(cat "$TEST_HOME/.dotfiles-theme")" "catppuccin" "State file updated to catppuccin"

teardown_theme_sandbox
echo ""

# ── Test 9: theme-set hook fires with the theme name ──
section "Test 9: theme-set hook runs with the theme name"
setup_theme_sandbox
load_theme_functions

mkdir -p "$TEST_HOME/.config/dotfiles/hooks/theme-set.d"
cat > "$TEST_HOME/.config/dotfiles/hooks/theme-set.d/10-record.sh" <<'HOOK'
#!/bin/bash
echo "hooked:$1" > "$HOME/hook-ran"
HOOK
set +e; apply_theme "aura" "true" >/dev/null 2>&1; set -e
assert_eq "$(cat "$TEST_HOME/hook-ran" 2>/dev/null)" "hooked:aura" "Hook received the theme name"

teardown_theme_sandbox
echo ""

# ── Test 10: add-theme scaffolds a theme that applies ──
section "Test 10: add-theme scaffolds a theme that applies"
setup_theme_sandbox
load_theme_functions

DOTFILES_DIR="$MOCK_DOTFILES" bash "$REAL_DOTFILES_DIR/bin/dotfiles-add-theme" "test-new" >/dev/null 2>&1

assert_file_exists "$MOCK_DOTFILES/themes/test-new/colors.toml" "colors.toml created"
assert_file_exists "$MOCK_DOTFILES/themes/test-new/theme.conf" "theme.conf created"
assert_file_exists "$MOCK_DOTFILES/themes/test-new/nvim/test-new-theme.lua" "nvim plugin template created"
assert_file_exists "$MOCK_DOTFILES/themes/test-new/overrides/README.md" "overrides/ explained"
assert_file_contains "$MOCK_DOTFILES/themes/test-new/theme.conf" "nvim_colorscheme" "theme.conf has nvim_colorscheme"
assert_file_contains "$MOCK_DOTFILES/themes/test-new/theme.conf" "bat_theme" "theme.conf has bat_theme"
assert_file_not_contains "$MOCK_DOTFILES/themes/test-new/theme.conf" "fzf_colors" "theme.conf no longer carries colours"

# Fill in the required names and apply it
sed -i '' 's/^nvim_colorscheme=""/nvim_colorscheme="x"/; s/^vscode_theme=""/vscode_theme="x"/; s/^zed_theme=""/zed_theme="x"/; s/^bat_theme=""/bat_theme="x"/; s/^delta_theme=""/delta_theme="x"/' \
    "$MOCK_DOTFILES/themes/test-new/theme.conf"
VALID_THEMES+=("test-new")
set +e; apply_theme "test-new" "true" >/dev/null 2>&1; rc=$?; set -e
assert_eq "$rc" "0" "Scaffolded theme applies cleanly"
assert_file_contains "$RENDERED/ghostty" "background = #1a1b26" "Scaffold palette rendered"

# Minimal palette: derived keys fill the gaps
cat > "$MOCK_DOTFILES/themes/test-new/colors.toml" <<'MIN'
background = "#101010"
foreground = "#e0e0e0"
red = "#ff0000"
green = "#00ff00"
yellow = "#ffff00"
blue = "#0000ff"
magenta = "#ff00ff"
cyan = "#00ffff"
MIN
set +e; apply_theme "test-new" "true" >/dev/null 2>&1; rc=$?; set -e
assert_eq "$rc" "0" "Minimal 8-colour palette applies"
assert_file_contains "$RENDERED/sketchybar-colors.sh" "ACCENT_COLOR=0xff0000ff" "accent derived from blue"
assert_file_contains "$RENDERED/lazygit.yml" "lightTheme: false" "mode derived from background luminance"

teardown_theme_sandbox
