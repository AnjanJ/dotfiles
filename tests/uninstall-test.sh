#!/usr/bin/env bash

# ============================================
# DOTFILES UNINSTALL TEST SUITE
# ============================================
# Tests that dotfiles-uninstall removes every symlink declared in
# scripts/symlink-map.sh (and only those that point into the repo),
# honours --yes / cancellation, and shows --help.
#
# Uses temporary directories — no real configs touched.
# Usage: tests/run uninstall   (or /opt/homebrew/bin/bash tests/uninstall-test.sh)
# ============================================

set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

REAL_DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REAL_HOME="$HOME"

# ── Mock Setup ────────────────────────────────

setup_uninstall_sandbox() {
    MOCK_DOTFILES=$(mktemp -d)
    TEST_HOME=$(mktemp -d)
    export HOME="$TEST_HOME"

    cp -r "$REAL_DOTFILES_DIR/scripts" "$MOCK_DOTFILES/scripts/"
    mkdir -p "$MOCK_DOTFILES/bin"
    cp "$REAL_DOTFILES_DIR/bin/dotfiles-uninstall" "$MOCK_DOTFILES/bin/dotfiles-uninstall"
    sed -i '' "s|^DOTFILES_DIR=.*|DOTFILES_DIR=\"$MOCK_DOTFILES\"|" "$MOCK_DOTFILES/bin/dotfiles-uninstall"

    # Repo sources: a loose dotfile, a map-only loose dotfile, a config
    # directory, a nested single file, and a bin/ script
    echo "zshrc" > "$MOCK_DOTFILES/.zshrc"
    echo "rubocop" > "$MOCK_DOTFILES/.rubocop.yml"
    echo "dhh" > "$MOCK_DOTFILES/.zshrc-dhh-additions"
    mkdir -p "$MOCK_DOTFILES/.config/nvim"
    echo "nvim" > "$MOCK_DOTFILES/.config/nvim/init.lua"
    mkdir -p "$MOCK_DOTFILES/.config/mise"
    echo "mise" > "$MOCK_DOTFILES/.config/mise/config.toml"
    echo "#!/bin/bash" > "$MOCK_DOTFILES/bin/test-script"

    # Link everything the map knows about into the sandbox HOME, the way
    # install/sync would
    # shellcheck disable=SC2329  # invoked via dotfiles_for_each_link
    _link() {
        mkdir -p "$(dirname "$2")"
        ln -sfn "$1" "$2"
    }
    # shellcheck disable=SC2034  # read by symlink-map.sh
    DOTFILES_DIR="$MOCK_DOTFILES"
    # shellcheck source=../scripts/symlink-map.sh
    source "$MOCK_DOTFILES/scripts/symlink-map.sh"
    dotfiles_for_each_link _link

    # A link at a managed path that points somewhere else — must survive
    mkdir -p "$TEST_HOME/elsewhere"
    echo "foreign" > "$TEST_HOME/elsewhere/dhh"
    ln -sfn "$TEST_HOME/elsewhere/dhh" "$TEST_HOME/.zshrc-dhh-additions"
}

teardown_uninstall_sandbox() {
    export HOME="$REAL_HOME"
    rm -rf "$MOCK_DOTFILES" "$TEST_HOME"
}

# ── Tests ─────────────────────────────────────

echo ""
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║   Dotfiles Uninstall Tests                                ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""

# ── Test 1: --help shows usage ──
section "Test 1: --help shows usage"
setup_uninstall_sandbox
output=$(bash "$MOCK_DOTFILES/bin/dotfiles-uninstall" --help 2>&1)
assert_contains "$output" "Usage:" "--help shows usage line"
assert_contains "$output" "--yes" "--help mentions --yes"
teardown_uninstall_sandbox
echo ""

# ── Test 2: --yes removes every mapped symlink ──
section "Test 2: --yes removes every mapped symlink"
setup_uninstall_sandbox
output=$(bash "$MOCK_DOTFILES/bin/dotfiles-uninstall" --yes 2>&1)
assert_file_not_exists "$TEST_HOME/.zshrc" "Removed ~/.zshrc"
assert_file_not_exists "$TEST_HOME/.rubocop.yml" "Removed map-only entry ~/.rubocop.yml"
assert_file_not_exists "$TEST_HOME/.config/nvim" "Removed ~/.config/nvim directory link"
assert_file_not_exists "$TEST_HOME/.config/mise/config.toml" "Removed nested single-file link"
assert_file_not_exists "$TEST_HOME/bin/test-script" "Removed ~/bin script link"
assert_contains "$output" "Uninstall Complete" "Prints completion banner"
# 4 mapped files + 2 bin/ scripts (test-script and the uninstall script itself)
assert_contains "$output" "6 symlinks" "Reports six removals"
teardown_uninstall_sandbox
echo ""

# ── Test 3: Foreign symlinks at managed paths are left alone ──
section "Test 3: Foreign symlinks are left alone"
setup_uninstall_sandbox
output=$(bash "$MOCK_DOTFILES/bin/dotfiles-uninstall" --yes 2>&1)
assert_is_symlink "$TEST_HOME/.zshrc-dhh-additions" "Foreign ~/.zshrc-dhh-additions kept"
assert_contains "$output" "Skipped" "Reports the skipped foreign link"
teardown_uninstall_sandbox
echo ""

# ── Test 4: Declining the prompt removes nothing ──
section "Test 4: Declining the prompt removes nothing"
setup_uninstall_sandbox
output=$(echo "n" | bash "$MOCK_DOTFILES/bin/dotfiles-uninstall" 2>&1 || true)
assert_contains "$output" "will be removed" "Preview lists pending removals"
assert_contains "$output" "cancelled" "Reports cancellation"
assert_is_symlink "$TEST_HOME/.zshrc" "~/.zshrc untouched after cancel"
assert_is_symlink "$TEST_HOME/bin/test-script" "~/bin script untouched after cancel"
teardown_uninstall_sandbox
echo ""

# ── Test 5: Idempotent — second run finds nothing ──
section "Test 5: Second run is a no-op"
setup_uninstall_sandbox
bash "$MOCK_DOTFILES/bin/dotfiles-uninstall" --yes >/dev/null 2>&1
output=$(bash "$MOCK_DOTFILES/bin/dotfiles-uninstall" --yes 2>&1)
assert_contains "$output" "Removed:" "Second run still completes"
assert_contains "$output" " 0 symlinks" "Second run removes zero"
teardown_uninstall_sandbox
