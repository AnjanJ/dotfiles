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
    cp "$REAL_DOTFILES_DIR/scripts/theme-background.sh" "$MOCK_DOTFILES/scripts/"
    cp "$REAL_DOTFILES_DIR/scripts/apply-theme.sh" "$MOCK_DOTFILES/scripts/"
    cp "$REAL_DOTFILES_DIR/scripts/_helpers.sh" "$MOCK_DOTFILES/scripts/"
    cp "$REAL_DOTFILES_DIR/bin/dotfiles-hook" "$MOCK_DOTFILES/bin/"
    cp "$REAL_DOTFILES_DIR/bin/dotfiles-toggle" "$MOCK_DOTFILES/bin/"

    # Stub the two ways apply-theme can flip macOS appearance; the log
    # says which was called and with what.
    STUB="$TEST_HOME/stub"
    APPEARANCE_LOG="$TEST_HOME/appearance.log"
    mkdir -p "$STUB"
    : > "$APPEARANCE_LOG"
    printf '#!/bin/bash\necho "dark-mode $*" >> "%s"\n' "$APPEARANCE_LOG" > "$STUB/dark-mode"
    printf '#!/bin/bash\necho "osascript $*" >> "%s"\n' "$APPEARANCE_LOG" > "$STUB/osascript"
    chmod +x "$STUB/dark-mode" "$STUB/osascript"
    export PATH="$STUB:$PATH"
    unset DOTFILES_NO_APPEARANCE

    mkdir -p "$MOCK_DOTFILES/.config/ghostty" "$MOCK_DOTFILES/.config/zellij" \
             "$MOCK_DOTFILES/.config/sketchybar" "$MOCK_DOTFILES/.config/borders" \
             "$MOCK_DOTFILES/.config/zed"
    echo 'config-file = ?theme.generated' > "$MOCK_DOTFILES/.config/ghostty/config"
    echo '{"theme": {"mode": "dark", "dark": "old-theme"}, "tab_size": 2}' > "$MOCK_DOTFILES/.config/zed/settings.base.json"
    mkdir -p "$MOCK_DOTFILES/.config/vscode"
    printf '{\n  "workbench.colorTheme": "{{ vscode_theme }}",\n  // a comment, so this is JSONC\n  "editor.fontSize": 18,\n}\n' > "$MOCK_DOTFILES/.config/vscode/settings.base.json"

    STATE="$TEST_HOME/.local/state/dotfiles/current"
    RENDERED="$STATE/theme"

    DOTFILES_DIR="$MOCK_DOTFILES"
    export DOTFILES_DIR
}

teardown_theme_sandbox() {
    export HOME="$REAL_HOME"
    export PATH="${PATH#"$STUB":}"
    export DOTFILES_NO_APPEARANCE=1
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

# ── Test 2b: Editor settings are generated; tracked base files stay clean ──
section "Test 2b: Zed and VS Code settings rendered from settings.base.json"
setup_theme_sandbox
load_theme_functions
mkdir -p "$TEST_HOME/.config/zed" "$TEST_HOME/Library/Application Support/Code/User"
zed_base_before=$(cat "$MOCK_DOTFILES/.config/zed/settings.base.json")
vscode_base_before=$(cat "$MOCK_DOTFILES/.config/vscode/settings.base.json")

set +e; apply_theme "tokyo-night" "true" >/dev/null 2>&1; set -e
assert_eq "$(cat "$MOCK_DOTFILES/.config/zed/settings.base.json")" "$zed_base_before" "Zed settings.base.json untouched by a theme switch"
assert_eq "$(cat "$MOCK_DOTFILES/.config/vscode/settings.base.json")" "$vscode_base_before" "VS Code settings.base.json untouched by a theme switch"
assert_eq "$(jq -r .theme.dark "$MOCK_DOTFILES/.config/zed/settings.json")" "Tokyo Night" "generated Zed settings carry the theme"
assert_eq "$(jq -r .tab_size "$MOCK_DOTFILES/.config/zed/settings.json")" "2" "and everything else from the base"
assert_file_contains "$MOCK_DOTFILES/.config/vscode/settings.json" '"workbench.colorTheme": "Tokyo Night"' "generated VS Code settings carry the theme"
assert_file_contains "$MOCK_DOTFILES/.config/vscode/settings.json" '// a comment' "VS Code comments survive (JSONC handled as text)"
assert_symlink "$TEST_HOME/.config/zed/settings.json" "$MOCK_DOTFILES/.config/zed/settings.json" "Zed's path linked to the generated file when nothing was there"
assert_symlink "$TEST_HOME/Library/Application Support/Code/User/settings.json" "$MOCK_DOTFILES/.config/vscode/settings.json" "VS Code's path linked too"

# The editors write their own settings files: those edits must reach the base
jq '.tab_size = 4 | .new_key = "from-zed"' "$MOCK_DOTFILES/.config/zed/settings.json" > "$TEST_HOME/zed.tmp"
mv "$TEST_HOME/zed.tmp" "$MOCK_DOTFILES/.config/zed/settings.json"
sed -i '' 's/"editor.fontSize": 18/"editor.fontSize": 20/' "$MOCK_DOTFILES/.config/vscode/settings.json"
set +e; out=$(apply_theme "aura" "true" 2>&1); set -e
assert_contains "$out" "Zed settings changed in Zed" "in-app Zed edits are reported"
assert_eq "$(jq -r .new_key "$MOCK_DOTFILES/.config/zed/settings.base.json")" "from-zed" "in-app Zed edits adopted into the base"
assert_eq "$(jq -r .theme.dark "$MOCK_DOTFILES/.config/zed/settings.base.json")" "old-theme" "but the base keeps its default theme block"
assert_eq "$(jq -r .theme.dark "$MOCK_DOTFILES/.config/zed/settings.json")" "Aura Soft Dark" "and the generated file moves to the new theme"
assert_eq "$(jq -r .tab_size "$MOCK_DOTFILES/.config/zed/settings.json")" "4" "keeping the in-app value"
assert_file_contains "$MOCK_DOTFILES/.config/vscode/settings.base.json" '"editor.fontSize": 20' "in-app VS Code edits adopted into the base"
assert_file_contains "$MOCK_DOTFILES/.config/vscode/settings.base.json" '"workbench.colorTheme": "{{ vscode_theme }}"' "with the theme placeholder kept"
assert_file_contains "$MOCK_DOTFILES/.config/vscode/settings.json" '"workbench.colorTheme": "Aura Dark"' "generated VS Code settings on the new theme"

# A theme with no editor names leaves the live selection alone
mkdir -p "$MOCK_DOTFILES/themes/plain"
cp "$MOCK_DOTFILES/themes/tokyo-night/colors.toml" "$MOCK_DOTFILES/themes/plain/"
printf 'nvim_colorscheme="x"\nvscode_theme=""\nzed_theme=""\nbat_theme="ansi"\ndelta_theme="ansi"\n' > "$MOCK_DOTFILES/themes/plain/theme.conf"
VALID_THEMES+=("plain")
set +e; apply_theme "plain" "true" >/dev/null 2>&1; set -e
assert_eq "$(jq -r .theme.dark "$MOCK_DOTFILES/.config/zed/settings.json")" "Aura Soft Dark" "empty zed_theme keeps the previous Zed theme"
assert_file_contains "$MOCK_DOTFILES/.config/vscode/settings.json" '"workbench.colorTheme": "Aura Dark"' "empty vscode_theme keeps the previous VS Code theme"

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

# Hash every rendered file (background.png is binary and
# nvim-dotfiles-theme/ is a directory, so cat would not do)
set +e; apply_theme "tokyo-night" "true" >/dev/null 2>&1; set -e
first=$(cd "$RENDERED" && find . -type f | sort | xargs shasum)
set +e; apply_theme "tokyo-night" "true" >/dev/null 2>&1; set -e
second=$(cd "$RENDERED" && find . -type f | sort | xargs shasum)
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

# ── Test 8b: Light theme drives mode-aware outputs and macOS appearance ──
section "Test 8b: Light theme (catppuccin-latte) sets mode, Zed slot and appearance"
setup_theme_sandbox
load_theme_functions

set +e; apply_theme "catppuccin-latte" "true" >/dev/null 2>&1; rc=$?; set -e
assert_eq "$rc" "0" "catppuccin-latte applies"
assert_eq "$(cat "$RENDERED/theme.mode")" "light" "theme.mode records light"
assert_file_contains "$RENDERED/lazygit.yml" "lightTheme: true" "lazygit told it is a light theme"
assert_file_contains "$RENDERED/claude.json" '"base": "light"' "Claude Code theme base is light"
assert_file_contains "$RENDERED/ghostty" "background = #eff1f5" "Ghostty background is Latte"
assert_file_contains "$RENDERED/ghostty" "palette = 0=#5c5f77" "ANSI black stays dark on a light ground"
assert_eq "$(jq -r .theme.mode "$MOCK_DOTFILES/.config/zed/settings.json")" "light" "Zed mode pinned to light"
assert_eq "$(jq -r .theme.light "$MOCK_DOTFILES/.config/zed/settings.json")" "Catppuccin Latte" "Zed light slot set"
assert_eq "$(jq -r .theme.dark "$MOCK_DOTFILES/.config/zed/settings.json")" "old-theme" "Zed dark slot untouched"
assert_file_contains "$APPEARANCE_LOG" "^dark-mode off$" "macOS appearance switched to light via dark-mode"
assert_file_not_contains "$APPEARANCE_LOG" "osascript" "osascript not used when dark-mode exists"

: > "$APPEARANCE_LOG"
set +e; apply_theme "tokyo-night" "true" >/dev/null 2>&1; set -e
assert_eq "$(cat "$RENDERED/theme.mode")" "dark" "theme.mode back to dark"
assert_eq "$(jq -r .theme.mode "$MOCK_DOTFILES/.config/zed/settings.json")" "dark" "Zed mode pinned to dark"
assert_eq "$(jq -r .theme.dark "$MOCK_DOTFILES/.config/zed/settings.json")" "Tokyo Night" "Zed dark slot set"
assert_eq "$(jq -r .theme.light "$MOCK_DOTFILES/.config/zed/settings.json")" "Catppuccin Latte" "Zed light slot keeps the last light theme"
assert_file_contains "$APPEARANCE_LOG" "^dark-mode on$" "macOS appearance switched to dark"

teardown_theme_sandbox
echo ""

# ── Test 8c: Appearance switch can be turned off, and falls back to osascript ──
section "Test 8c: appearance toggle and the osascript fallback"
setup_theme_sandbox
load_theme_functions

bash "$MOCK_DOTFILES/bin/dotfiles-toggle" appearance off >/dev/null
set +e; apply_theme "flexoki-light" "true" >/dev/null 2>&1; rc=$?; set -e
assert_eq "$rc" "0" "flexoki-light applies"
assert_eq "$(cat "$APPEARANCE_LOG")" "" "no appearance call when the toggle is off"
bash "$MOCK_DOTFILES/bin/dotfiles-toggle" appearance on >/dev/null

DOTFILES_NO_APPEARANCE=1
set +e; apply_theme "flexoki-light" "true" >/dev/null 2>&1; set -e
unset DOTFILES_NO_APPEARANCE
assert_eq "$(cat "$APPEARANCE_LOG")" "" "no appearance call under DOTFILES_NO_APPEARANCE"

# Without dark-mode anywhere on PATH (Homebrew dropped too, so a real
# install on this machine cannot leak in) apply-theme falls back to osascript.
rm "$STUB/dark-mode"
hash -r
set +e; out=$(PATH="$STUB:/usr/bin:/bin" apply_theme "flexoki-light" "true" 2>&1); set -e
assert_file_contains "$APPEARANCE_LOG" "set dark mode to false" "osascript fallback asks System Events for light"
assert_contains "$out" "macOS appearance → light" "reports the switch"

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

# ── Test 10: One render at a time ──
section "Test 10: apply_theme takes a lock"
setup_theme_sandbox
load_theme_functions
mkdir -p "$TEST_HOME/.local/state/dotfiles/theme.lock"
echo "$$" > "$TEST_HOME/.local/state/dotfiles/theme.lock/pid"   # this test process is alive
set +e; out=$(apply_theme "tokyo-night" "true" 2>&1); rc=$?; set -e
assert_eq "$rc" "1" "a live lock stops the render"
assert_contains "$out" "another theme render is running (pid $$)" "and names the holder"
assert_file_not_exists "$RENDERED/ghostty" "nothing rendered under a live lock"
echo "2147483000" > "$TEST_HOME/.local/state/dotfiles/theme.lock/pid"   # nobody has this pid
set +e; out=$(apply_theme "tokyo-night" "true" 2>&1); rc=$?; set -e
assert_eq "$rc" "0" "a stale lock is removed and the render proceeds"
assert_contains "$out" "stale theme lock" "stale lock reported"
assert_dir_not_exists "$TEST_HOME/.local/state/dotfiles/theme.lock" "lock released afterwards"
teardown_theme_sandbox
echo ""

# ── Test 11: Palette preview ──
section "Test 11: dotfiles theme preview"
PREVIEW="$REAL_DOTFILES_DIR/bin/dotfiles-theme-preview"
out=$("$PREVIEW" tokyo-night --no-color)
assert_contains "$out" "tokyo-night (dark)" "names the theme and its mode"
assert_matches "$out" "^background *#1a1b26$" "lists background"
assert_matches "$out" "^bright_red *#" "derived bright colours included"
assert_not_contains "$out" "{{" "no unresolved tokens"
out=$("$PREVIEW" "$REAL_DOTFILES_DIR/themes/catppuccin-latte/colors.toml" --no-color)
assert_contains "$out" "(light)" "a palette file can be previewed by path"
out=$(DOTFILES_PREVIEW_FORCE_COLOR=1 "$PREVIEW" aura)
assert_contains "$out" "$(printf '\033[48;2;21;20;27m')" "colour output paints the background swatch"
set +e; out=$("$PREVIEW" nope 2>&1); rc=$?; set -e
assert_eq "$rc" "1" "unknown theme exits 1"
assert_contains "$out" "No theme 'nope'" "and says so"
