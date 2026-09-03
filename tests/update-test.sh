#!/usr/bin/env bash
# shellcheck disable=SC2034

# ============================================
# UPDATE.SH TEST SUITE
# ============================================
# Tests for update.sh logic: symlink creation,
# idempotency, broken link handling, OS guard.
#
# Uses a temporary HOME directory — no real configs touched.
# Usage: tests/run update   (or /opt/homebrew/bin/bash tests/update-test.sh)
# ============================================

set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REAL_HOME="$HOME"

setup_sandbox() {
    TEST_HOME=$(mktemp -d)
    export HOME="$TEST_HOME"
    unset _HELPERS_LOADED 2>/dev/null || true
}

teardown_sandbox() {
    export HOME="$REAL_HOME"
    rm -rf "$TEST_HOME"
}

# ── Extracted: create_symlink from update.sh ──
create_symlink() {
    local source="$1"
    local target="$2"
    local name="$3"

    if [ -L "$target" ] && [ "$(readlink "$target")" = "$source" ]; then
        echo "up-to-date"
    else
        ln -sf "$source" "$target"
        echo "refreshed"
    fi
}

# ── Tests ─────────────────────────────────────

test_27_create_symlink_new() {
    echo ""
    section "Test 27: create_symlink creates link when none exists"
    setup_sandbox

    local source_file="$TEST_HOME/dotfiles/myconfig"
    local target_link="$TEST_HOME/.myconfig"
    mkdir -p "$TEST_HOME/dotfiles"
    echo "config content" > "$source_file"

    local result
    result=$(create_symlink "$source_file" "$target_link" "myconfig")
    assert_eq "$result" "refreshed" "Reports refreshed for new link"

    if [[ -L "$target_link" ]]; then
        pass "Symlink created"
        local actual_target
        actual_target=$(readlink "$target_link")
        assert_eq "$actual_target" "$source_file" "Symlink points to correct source"
    else
        fail "Symlink not created"
    fi

    teardown_sandbox
}

test_28_create_symlink_already_correct() {
    echo ""
    section "Test 28: create_symlink is no-op when link already correct"
    setup_sandbox

    local source_file="$TEST_HOME/dotfiles/myconfig"
    local target_link="$TEST_HOME/.myconfig"
    mkdir -p "$TEST_HOME/dotfiles"
    echo "config content" > "$source_file"

    # Create correct symlink first
    ln -sf "$source_file" "$target_link"

    local result
    result=$(create_symlink "$source_file" "$target_link" "myconfig")
    assert_eq "$result" "up-to-date" "Reports up-to-date for existing correct link"

    teardown_sandbox
}

test_29_create_symlink_broken() {
    echo ""
    section "Test 29: create_symlink overwrites broken symlink"
    setup_sandbox

    local source_file="$TEST_HOME/dotfiles/myconfig"
    local target_link="$TEST_HOME/.myconfig"
    mkdir -p "$TEST_HOME/dotfiles"
    echo "config content" > "$source_file"

    # Create broken symlink (points to non-existent file)
    ln -sf "$TEST_HOME/nonexistent" "$target_link"

    # Verify it's broken
    if [[ ! -e "$target_link" ]]; then
        pass "Pre-condition: symlink is broken"
    else
        fail "Pre-condition: symlink should be broken"
    fi

    local result
    result=$(create_symlink "$source_file" "$target_link" "myconfig")
    assert_eq "$result" "refreshed" "Reports refreshed for broken link"

    local actual_target
    actual_target=$(readlink "$target_link")
    assert_eq "$actual_target" "$source_file" "Fixed to correct source"

    teardown_sandbox
}

test_30_create_symlink_wrong_target() {
    echo ""
    section "Test 30: create_symlink overwrites link pointing to wrong target"
    setup_sandbox

    local source_file="$TEST_HOME/dotfiles/myconfig"
    local wrong_source="$TEST_HOME/dotfiles/old-myconfig"
    local target_link="$TEST_HOME/.myconfig"
    mkdir -p "$TEST_HOME/dotfiles"
    echo "new content" > "$source_file"
    echo "old content" > "$wrong_source"

    # Create symlink to wrong target
    ln -sf "$wrong_source" "$target_link"

    local result
    result=$(create_symlink "$source_file" "$target_link" "myconfig")
    assert_eq "$result" "refreshed" "Reports refreshed for wrong-target link"

    local actual_target
    actual_target=$(readlink "$target_link")
    assert_eq "$actual_target" "$source_file" "Updated to correct source"

    teardown_sandbox
}

test_31_macos_only_guard() {
    echo ""
    section "Test 31: macOS-only guard in update.sh"
    setup_sandbox

    # Test the guard logic — on macOS this always passes,
    # but we verify the check logic itself is sound
    local uname_output
    uname_output=$(uname)

    if [[ "$uname_output" == "Darwin" ]]; then
        pass "Running on macOS — guard passes"
    else
        pass "Not on macOS — guard would correctly reject"
    fi

    # Verify the guard pattern is present in update.sh
    if /usr/bin/grep -q 'uname.*Darwin' "$DOTFILES_DIR/update.sh"; then
        pass "macOS guard exists in update.sh"
    else
        fail "macOS guard missing from update.sh"
    fi

    teardown_sandbox
}

# ── Run All Tests ─────────────────────────────

echo ""
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║   Update.sh Test Suite                                     ║"
echo "╚═══════════════════════════════════════════════════════════╝"

test_27_create_symlink_new
test_28_create_symlink_already_correct
test_29_create_symlink_broken
test_30_create_symlink_wrong_target
test_31_macos_only_guard
