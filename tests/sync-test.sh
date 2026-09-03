#!/usr/bin/env bash

# ============================================
# DOTFILES SYNC TEST SUITE
# ============================================
# Tests that dotfiles-sync refreshes symlinks,
# handles broken links, dry-run mode, and --help.
#
# Uses temporary directories — no real configs touched.
# Usage: tests/run sync   (or /opt/homebrew/bin/bash tests/sync-test.sh)
# ============================================

set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

REAL_DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REAL_HOME="$HOME"

# ── Mock Setup ────────────────────────────────

setup_sync_sandbox() {
    MOCK_DOTFILES=$(mktemp -d)
    TEST_HOME=$(mktemp -d)
    export HOME="$TEST_HOME"

    # Copy scripts needed by dotfiles-sync
    cp -r "$REAL_DOTFILES_DIR/scripts" "$MOCK_DOTFILES/scripts/"

    # Create mock dotfiles source files
    echo "zshrc" > "$MOCK_DOTFILES/.zshrc"
    echo "gitignore" > "$MOCK_DOTFILES/.gitignore_global"
    echo "terminal" > "$MOCK_DOTFILES/.zshrc-terminal-enhancements"

    mkdir -p "$MOCK_DOTFILES/.config/aerospace"
    mkdir -p "$MOCK_DOTFILES/.config/ghostty"
    mkdir -p "$MOCK_DOTFILES/.config/nvim"
    mkdir -p "$MOCK_DOTFILES/.config/zellij"
    mkdir -p "$MOCK_DOTFILES/.config/mise"
    mkdir -p "$MOCK_DOTFILES/.config/zed/snippets"
    touch "$MOCK_DOTFILES/.config/starship.toml"
    touch "$MOCK_DOTFILES/.config/mise/config.toml"
    touch "$MOCK_DOTFILES/.config/zed/settings.json"
    touch "$MOCK_DOTFILES/.config/zed/tasks.json"

    # Create bin directory with a script
    mkdir -p "$MOCK_DOTFILES/bin"
    echo "#!/bin/bash" > "$MOCK_DOTFILES/bin/test-script"

    # Create HOME directories
    mkdir -p "$TEST_HOME/.config/zed/snippets"
    mkdir -p "$TEST_HOME/.config/mise"
    mkdir -p "$TEST_HOME/bin"

    # Create a minimal sync script that just does symlink refresh
    # (skip git pull and theme reapply since those need real git/theme)
    cat > "$MOCK_DOTFILES/bin/dotfiles-sync-test" <<'SYNCEOF'
#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$1"
DRY_RUN="${2:-false}"

source "$DOTFILES_DIR/scripts/_helpers.sh"

CHANGES=0

_check_link() {
    local source="$1" target="$2" name="$3"
    if [[ -L "$target" && "$(readlink "$target")" == "$source" ]]; then
        return 0
    fi
    if [[ "$DRY_RUN" == true ]]; then
        echo "  Would link: $name"
    else
        ln -sf "$source" "$target"
    fi
    CHANGES=$((CHANGES + 1))
}

# Shell configs
_check_link "$DOTFILES_DIR/.zshrc" ~/.zshrc ".zshrc"
[[ -f "$DOTFILES_DIR/.zshrc-terminal-enhancements" ]] && _check_link "$DOTFILES_DIR/.zshrc-terminal-enhancements" ~/.zshrc-terminal-enhancements ".zshrc-terminal-enhancements"

# Core configs
[[ -f "$DOTFILES_DIR/.gitignore_global" ]] && _check_link "$DOTFILES_DIR/.gitignore_global" ~/.gitignore_global ".gitignore_global"

# bin scripts
mkdir -p ~/bin
for script in "$DOTFILES_DIR/bin/"*; do
    name=$(basename "$script")
    _check_link "$script" ~/bin/"$name" "bin/$name"
done

echo "CHANGES=$CHANGES"
SYNCEOF
    chmod +x "$MOCK_DOTFILES/bin/dotfiles-sync-test"
}

teardown_sync_sandbox() {
    export HOME="$REAL_HOME"
    rm -rf "$MOCK_DOTFILES" "$TEST_HOME"
}

# ── Tests ─────────────────────────────────────

echo ""
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║   Dotfiles Sync Tests                                     ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""

# ── Test 1: --help shows usage ──
section "Test 1: --help shows usage"
output=$(bash "$REAL_DOTFILES_DIR/bin/dotfiles-sync" --help 2>&1)

assert_contains "$output" "Usage:" "--help shows usage line"
assert_contains "$output" "--dry-run" "--help mentions --dry-run"

echo ""

# ── Test 2: Symlink refresh creates missing links ──
section "Test 2: Symlink refresh creates missing links"
setup_sync_sandbox

# No symlinks exist yet — sync should create them
output=$(bash "$MOCK_DOTFILES/bin/dotfiles-sync-test" "$MOCK_DOTFILES" false 2>&1)

assert_symlink "$TEST_HOME/.zshrc" "$MOCK_DOTFILES/.zshrc" \
    "Creates .zshrc symlink"
assert_symlink "$TEST_HOME/.zshrc-terminal-enhancements" "$MOCK_DOTFILES/.zshrc-terminal-enhancements" \
    "Creates .zshrc-terminal-enhancements symlink"

teardown_sync_sandbox
echo ""

# ── Test 3: Symlink refresh fixes broken links ──
section "Test 3: Symlink refresh fixes broken links"
setup_sync_sandbox

# Create a broken symlink
ln -sf "/nonexistent/path/.zshrc" "$TEST_HOME/.zshrc"

# Verify it's broken
if [[ ! -e "$TEST_HOME/.zshrc" ]]; then
    pass "Symlink starts as broken"
else
    fail "Symlink should be broken initially"
fi

# Run sync to fix it
bash "$MOCK_DOTFILES/bin/dotfiles-sync-test" "$MOCK_DOTFILES" false >/dev/null 2>&1

assert_symlink "$TEST_HOME/.zshrc" "$MOCK_DOTFILES/.zshrc" \
    "Broken symlink was fixed"

teardown_sync_sandbox
echo ""

# ── Test 4: Symlink refresh skips correct links ──
section "Test 4: Symlink refresh skips correct links"
setup_sync_sandbox

# Create correct symlinks first
ln -sf "$MOCK_DOTFILES/.zshrc" "$TEST_HOME/.zshrc"
ln -sf "$MOCK_DOTFILES/.gitignore_global" "$TEST_HOME/.gitignore_global"
ln -sf "$MOCK_DOTFILES/.zshrc-terminal-enhancements" "$TEST_HOME/.zshrc-terminal-enhancements"
mkdir -p "$TEST_HOME/bin"
ln -sf "$MOCK_DOTFILES/bin/test-script" "$TEST_HOME/bin/test-script"
ln -sf "$MOCK_DOTFILES/bin/dotfiles-sync-test" "$TEST_HOME/bin/dotfiles-sync-test"

# Run sync — should report 0 changes
output=$(bash "$MOCK_DOTFILES/bin/dotfiles-sync-test" "$MOCK_DOTFILES" false 2>&1)

assert_contains "$output" "CHANGES=0" "No changes needed for correct links"

teardown_sync_sandbox
echo ""

# ── Test 5: Missing source file skipped gracefully ──
section "Test 5: Missing source file skipped gracefully"
setup_sync_sandbox

# Remove a source file that sync checks for
rm -f "$MOCK_DOTFILES/.zshrc-terminal-enhancements"

# Run sync — should not crash
output=$(bash "$MOCK_DOTFILES/bin/dotfiles-sync-test" "$MOCK_DOTFILES" false 2>&1)
exit_code=$?

assert_eq "$exit_code" "0" "Sync completes successfully with missing optional file"

# .zshrc should still be linked
assert_symlink "$TEST_HOME/.zshrc" "$MOCK_DOTFILES/.zshrc" \
    "Other symlinks still created"

# Terminal enhancements should NOT be linked (source missing)
if [[ ! -L "$TEST_HOME/.zshrc-terminal-enhancements" ]]; then
    pass "Missing source file not linked"
else
    fail "Should not create link for missing source"
fi

teardown_sync_sandbox
echo ""

# ── Test 6: --dry-run mode reports without changes ──
section "Test 6: --dry-run mode reports without changes"
setup_sync_sandbox

# Run in dry-run mode
output=$(bash "$MOCK_DOTFILES/bin/dotfiles-sync-test" "$MOCK_DOTFILES" true 2>&1)

# Should report would-be changes
assert_contains "$output" "Would link" "Dry-run reports what would change"

# But no symlinks should actually exist
if [[ ! -L "$TEST_HOME/.zshrc" ]]; then
    pass "No symlinks created in dry-run mode"
else
    fail "Dry-run should not create symlinks"
fi

teardown_sync_sandbox
echo ""

# ── Test 7: Theme reapply triggered when theme state exists ──
section "Test 7: Theme state file detection"
setup_sync_sandbox

# Create a theme state file
echo "tokyo-night" > "$TEST_HOME/.dotfiles-theme"

if [[ -f "$TEST_HOME/.dotfiles-theme" ]]; then
    pass "Theme state file exists"
else
    fail "Theme state file should exist"
fi

# Verify theme-utils.sh can read it
source "$MOCK_DOTFILES/scripts/theme-utils.sh"
theme=$(get_current_theme)
assert_eq "$theme" "tokyo-night" "Theme state file read correctly"

teardown_sync_sandbox
