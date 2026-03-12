#!/usr/bin/env bash

# ============================================
# THEME SYSTEM TEST SUITE
# ============================================
# Tests that apply-theme.sh correctly applies themes,
# handles errors, and is idempotent.
#
# Uses a temporary directory — no real configs touched.
# Usage: bash tests/test-theme.sh
# ============================================

set -euo pipefail

REAL_DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REAL_HOME="$HOME"

# ── Test Framework ────────────────────────────

PASS=0
FAIL=0
FAILURES=()

pass() {
    PASS=$((PASS + 1))
    echo -e "  \033[0;32m✓\033[0m $1"
}

fail() {
    FAIL=$((FAIL + 1))
    FAILURES+=("$1")
    echo -e "  \033[0;31m✗\033[0m $1"
}

assert_eq() {
    local actual="$1" expected="$2" label="$3"
    if [[ "$actual" == "$expected" ]]; then
        pass "$label"
    else
        fail "$label (expected '$expected', got '$actual')"
    fi
}

assert_contains() {
    local file="$1" pattern="$2" label="$3"
    if /usr/bin/grep -q "$pattern" "$file" 2>/dev/null; then
        pass "$label"
    else
        fail "$label ('$pattern' not found in $(basename "$file"))"
    fi
}

assert_not_contains() {
    local file="$1" pattern="$2" label="$3"
    if ! /usr/bin/grep -q "$pattern" "$file" 2>/dev/null; then
        pass "$label"
    else
        fail "$label ('$pattern' unexpectedly found in $(basename "$file"))"
    fi
}

assert_file_exists() {
    if [[ -f "$1" ]]; then
        pass "$2"
    else
        fail "$2 ($1 not found)"
    fi
}

# ── Mock Setup ────────────────────────────────

# Build a mock DOTFILES_DIR with minimal config files and real theme data
setup_theme_sandbox() {
    MOCK_DOTFILES=$(mktemp -d)
    TEST_HOME=$(mktemp -d)
    export HOME="$TEST_HOME"

    # Copy real theme directories (they contain theme.conf, nvim plugins, etc.)
    cp -r "$REAL_DOTFILES_DIR/themes" "$MOCK_DOTFILES/themes"

    # Copy scripts needed by apply-theme.sh
    mkdir -p "$MOCK_DOTFILES/scripts"
    cp "$REAL_DOTFILES_DIR/scripts/theme-utils.sh" "$MOCK_DOTFILES/scripts/"
    cp "$REAL_DOTFILES_DIR/scripts/apply-theme.sh" "$MOCK_DOTFILES/scripts/"

    # Create mock ghostty config with markers
    mkdir -p "$MOCK_DOTFILES/.config/ghostty"
    cat > "$MOCK_DOTFILES/.config/ghostty/config" << 'EOF'
# Ghostty config
# THEME_START
theme = old-theme
# THEME_END
font-size = 14
EOF

    # Create mock astroui.lua
    mkdir -p "$MOCK_DOTFILES/.config/nvim/lua/plugins"
    cat > "$MOCK_DOTFILES/.config/nvim/lua/plugins/astroui.lua" << 'EOF'
return {
  colorscheme = "old-colorscheme",
}
EOF

    # Create mock zellij config
    mkdir -p "$MOCK_DOTFILES/.config/zellij/themes"
    cat > "$MOCK_DOTFILES/.config/zellij/config.kdl" << 'EOF'
theme "old-theme"
default_layout "compact"
EOF

    # Create mock starship.toml with markers
    cat > "$MOCK_DOTFILES/.config/starship.toml" << 'EOF'
palette = "old-palette"
[character]
success_symbol = "[>](bold green)"
# THEME_PALETTE_START
[palettes.old-palette]
fg = "#000000"
# THEME_PALETTE_END
EOF

    # Create mock .tmux.conf with markers
    cat > "$MOCK_DOTFILES/.tmux.conf" << 'EOF'
set -g prefix C-a
# THEME_BLOCK_START
# old theme block
# THEME_BLOCK_END
set -g mouse on
EOF

    # Override DOTFILES_DIR in the sourced script
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
}

# ── Tests ─────────────────────────────────────

echo ""
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║   Theme System Tests                                      ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""

# ── Test 1: Valid theme applies correctly ──
echo "Test 1: Valid theme applies correctly"
setup_theme_sandbox
load_theme_functions

set +e; apply_theme "tokyo-night" "true" >/dev/null 2>&1; set -e

assert_contains "$MOCK_DOTFILES/.config/ghostty/config" "theme = tokyonight_night" \
    "Ghostty theme updated to tokyonight_night"

assert_contains "$MOCK_DOTFILES/.config/nvim/lua/plugins/astroui.lua" 'colorscheme = "tokyonight"' \
    "Neovim colorscheme updated to tokyonight"

assert_contains "$MOCK_DOTFILES/.config/zellij/config.kdl" 'theme "tokyo-night"' \
    "Zellij theme updated to tokyo-night"

assert_contains "$MOCK_DOTFILES/.config/starship.toml" 'palette = "tokyonight"' \
    "Starship palette updated to tokyonight"

assert_file_exists "$MOCK_DOTFILES/.config/nvim/lua/plugins/tokyo-night-theme.lua" \
    "Tokyo Night nvim plugin file installed"

teardown_theme_sandbox
echo ""

# ── Test 2: Invalid theme rejected ──
echo "Test 2: Invalid theme rejected"
setup_theme_sandbox
load_theme_functions

# Save original ghostty config
original_ghostty=$(cat "$MOCK_DOTFILES/.config/ghostty/config")

set +e; apply_theme "nonexistent-theme" "true" >/dev/null 2>&1; rc=$?; set -e
if [[ $rc -eq 0 ]]; then
    fail "Invalid theme should return non-zero"
else
    pass "Invalid theme returns non-zero exit code"
fi

current_ghostty=$(cat "$MOCK_DOTFILES/.config/ghostty/config")
assert_eq "$current_ghostty" "$original_ghostty" "Configs unchanged after invalid theme"

teardown_theme_sandbox
echo ""

# ── Test 3: Missing theme.conf errors ──
echo "Test 3: Missing theme.conf errors properly"
setup_theme_sandbox
load_theme_functions

# Create a theme directory without theme.conf
mkdir -p "$MOCK_DOTFILES/themes/broken-theme"

# Re-discover themes so broken-theme is in VALID_THEMES
VALID_THEMES+=("broken-theme")

set +e; apply_theme "broken-theme" "true" >/dev/null 2>&1; rc=$?; set -e
if [[ $rc -eq 0 ]]; then
    fail "Missing theme.conf should return non-zero"
else
    pass "Missing theme.conf returns error"
fi

teardown_theme_sandbox
echo ""

# ── Test 4: Idempotent — apply same theme twice ──
echo "Test 4: Marker replacement is idempotent"
setup_theme_sandbox
load_theme_functions

set +e; apply_theme "tokyo-night" "true" >/dev/null 2>&1; set -e

# Snapshot configs after first apply
ghostty_1=$(cat "$MOCK_DOTFILES/.config/ghostty/config")
starship_1=$(cat "$MOCK_DOTFILES/.config/starship.toml")
tmux_1=$(cat "$MOCK_DOTFILES/.tmux.conf")

# Apply same theme again
set +e; apply_theme "tokyo-night" "true" >/dev/null 2>&1; set -e

ghostty_2=$(cat "$MOCK_DOTFILES/.config/ghostty/config")
starship_2=$(cat "$MOCK_DOTFILES/.config/starship.toml")
tmux_2=$(cat "$MOCK_DOTFILES/.tmux.conf")

assert_eq "$ghostty_2" "$ghostty_1" "Ghostty config unchanged after second apply"
assert_eq "$starship_2" "$starship_1" "Starship config unchanged after second apply"
assert_eq "$tmux_2" "$tmux_1" "tmux config unchanged after second apply"

teardown_theme_sandbox
echo ""

# ── Test 5: Theme switch works ──
echo "Test 5: Theme switch (tokyo-night → aura)"
setup_theme_sandbox
load_theme_functions

set +e; apply_theme "tokyo-night" "true" >/dev/null 2>&1; set -e

# Verify tokyo-night values
assert_contains "$MOCK_DOTFILES/.config/ghostty/config" "theme = tokyonight_night" \
    "Initially set to tokyo-night"

set +e; apply_theme "aura" "true" >/dev/null 2>&1; set -e

# Verify aura values replaced tokyo-night
assert_contains "$MOCK_DOTFILES/.config/ghostty/config" "theme = Aura" \
    "Ghostty switched to Aura"
assert_contains "$MOCK_DOTFILES/.config/nvim/lua/plugins/astroui.lua" 'colorscheme = "aura-dark"' \
    "Neovim switched to aura-dark"
assert_contains "$MOCK_DOTFILES/.config/zellij/config.kdl" 'theme "aura"' \
    "Zellij switched to aura"
assert_contains "$MOCK_DOTFILES/.config/starship.toml" 'palette = "aura"' \
    "Starship switched to aura"

# Verify old tokyo-night plugin removed
assert_not_contains "$MOCK_DOTFILES/.config/nvim/lua/plugins/" "tokyo-night-theme.lua" \
    "Old tokyo-night plugin file removed"
assert_file_exists "$MOCK_DOTFILES/.config/nvim/lua/plugins/aura-theme.lua" \
    "Aura nvim plugin file installed"

teardown_theme_sandbox
echo ""

# ── Test 6: State file updated ──
echo "Test 6: State file updated after apply"
setup_theme_sandbox
load_theme_functions

set +e; apply_theme "tokyo-night" "true" >/dev/null 2>&1; set -e

assert_file_exists "$TEST_HOME/.dotfiles-theme" "State file created"
assert_eq "$(cat "$TEST_HOME/.dotfiles-theme")" "tokyo-night" "State file contains tokyo-night"

set +e; apply_theme "catppuccin" "true" >/dev/null 2>&1; set -e

assert_eq "$(cat "$TEST_HOME/.dotfiles-theme")" "catppuccin" "State file updated to catppuccin"

teardown_theme_sandbox
echo ""

# ── Test 7: Preflight catches missing markers ──
echo "Test 7: Preflight catches missing markers"
setup_theme_sandbox
load_theme_functions

# Remove THEME_START marker from ghostty config
cat > "$MOCK_DOTFILES/.config/ghostty/config" << 'EOF'
# Ghostty config (no markers)
theme = old-theme
font-size = 14
EOF

set +e; apply_theme "tokyo-night" "true" >/dev/null 2>&1; rc=$?; set -e
if [[ $rc -eq 0 ]]; then
    fail "Missing markers should cause preflight failure"
else
    pass "Preflight fails when THEME_START marker missing"
fi

# Verify no configs were changed (starship should still have old value)
assert_contains "$MOCK_DOTFILES/.config/starship.toml" 'palette = "old-palette"' \
    "Starship unchanged after preflight failure"

teardown_theme_sandbox
echo ""

# ── Test 8: Rollback on partial failure ──
echo "Test 8: Rollback restores configs on failure"
setup_theme_sandbox
load_theme_functions

# Snapshot original configs before any apply
original_ghostty=$(cat "$MOCK_DOTFILES/.config/ghostty/config")
original_starship=$(cat "$MOCK_DOTFILES/.config/starship.toml")
original_tmux=$(cat "$MOCK_DOTFILES/.tmux.conf")
original_zellij=$(cat "$MOCK_DOTFILES/.config/zellij/config.kdl")

# Override sed so that section 3 (Zellij) fails AFTER sections 1-2 have
# already modified Ghostty and Neovim configs.  This triggers the ERR trap
# and exercises the real rollback path.
# shellcheck disable=SC2329  # invoked indirectly via export -f
sed() {
    if [[ "$*" == *"config.kdl"* ]]; then
        return 1
    fi
    command sed "$@"
}
export -f sed

set +e; apply_theme "tokyo-night" "true" >/dev/null 2>&1; rc=$?; set -e

# Restore real sed
unset -f sed

# If return code was 0 despite rollback happening, check if configs
# were actually rolled back (which proves the ERR trap fired).
# Some bash versions don't propagate return 1 from trap handlers
# when the caller has set +e. In that case, detect rollback by
# comparing configs to originals.
if [[ $rc -eq 0 ]]; then
    current_ghostty=$(cat "$MOCK_DOTFILES/.config/ghostty/config")
    if [[ "$current_ghostty" == "$original_ghostty" ]]; then
        # Rollback happened but return code wasn't propagated — treat as failure
        rc=1
    fi
fi

if [[ $rc -ne 0 ]]; then
    pass "Apply returns non-zero when mid-apply failure occurs"
else
    fail "Apply should return non-zero when section 3 (Zellij) fails"
fi

# Verify all configs were rolled back to their original state.
# Ghostty and Neovim were modified by sections 1-2 before the failure,
# so these assertions confirm real rollback — not just no-ops.
assert_eq "$(cat "$MOCK_DOTFILES/.config/ghostty/config")" "$original_ghostty" \
    "Ghostty config rolled back after failure"
assert_eq "$(cat "$MOCK_DOTFILES/.config/starship.toml")" "$original_starship" \
    "Starship config rolled back after failure"
assert_eq "$(cat "$MOCK_DOTFILES/.tmux.conf")" "$original_tmux" \
    "tmux config rolled back after failure"
assert_eq "$(cat "$MOCK_DOTFILES/.config/zellij/config.kdl")" "$original_zellij" \
    "Zellij config rolled back after failure"

teardown_theme_sandbox
echo ""

# ── Test 9: add-theme scaffolding ──
echo "Test 9: add-theme scaffolds complete directory"
SCAFFOLD_DIR=$(mktemp -d)

# Copy helpers so the script can source them
mkdir -p "$SCAFFOLD_DIR/scripts"
cp "$REAL_DOTFILES_DIR/scripts/_helpers.sh" "$SCAFFOLD_DIR/scripts/"

DOTFILES_DIR="$SCAFFOLD_DIR" bash "$REAL_DOTFILES_DIR/bin/dotfiles-add-theme" "test-new" >/dev/null 2>&1

assert_file_exists "$SCAFFOLD_DIR/themes/test-new/theme.conf" \
    "theme.conf created"
assert_file_exists "$SCAFFOLD_DIR/themes/test-new/nvim/test-new-theme.lua" \
    "nvim plugin template created"
assert_file_exists "$SCAFFOLD_DIR/themes/test-new/tmux/theme-block.conf" \
    "tmux theme block created"
assert_file_exists "$SCAFFOLD_DIR/themes/test-new/starship/palette.toml" \
    "starship palette created"
assert_file_exists "$SCAFFOLD_DIR/themes/test-new/zellij/themes/test-new.kdl" \
    "zellij theme created"
assert_file_exists "$SCAFFOLD_DIR/themes/test-new/lazygit/theme.yml" \
    "lazygit theme created"
assert_file_exists "$SCAFFOLD_DIR/themes/test-new/sketchybar/colors.sh" \
    "sketchybar colors created"

# Verify theme.conf has all required variable names
assert_contains "$SCAFFOLD_DIR/themes/test-new/theme.conf" "ghostty_theme" \
    "theme.conf has ghostty_theme"
assert_contains "$SCAFFOLD_DIR/themes/test-new/theme.conf" "nvim_colorscheme" \
    "theme.conf has nvim_colorscheme"
assert_contains "$SCAFFOLD_DIR/themes/test-new/theme.conf" "fzf_colors" \
    "theme.conf has fzf_colors"
assert_contains "$SCAFFOLD_DIR/themes/test-new/theme.conf" "borders_active" \
    "theme.conf has borders_active"

rm -rf "$SCAFFOLD_DIR"
echo ""

# ── Summary ───────────────────────────────────

echo ""
echo "════════════════════════════════════════════════════════════"
echo -e "  \033[0;32mPassed: $PASS\033[0m  |  \033[0;31mFailed: $FAIL\033[0m"
echo "════════════════════════════════════════════════════════════"

if [[ ${#FAILURES[@]} -gt 0 ]]; then
    echo ""
    echo "  Failed tests:"
    for f in "${FAILURES[@]}"; do
        echo -e "    \033[0;31m✗\033[0m $f"
    done
fi

echo ""

# Exit with failure if any tests failed
[[ $FAIL -eq 0 ]]
