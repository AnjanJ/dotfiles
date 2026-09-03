#!/usr/bin/env bash

# ============================================
# SETUP-GIT TEST SUITE
# ============================================
# Tests that setup-git.sh correctly configures
# Git identity, defaults, and work identity.
#
# Uses a temporary HOME — no real configs touched.
# Usage: tests/run setup-git   (or /opt/homebrew/bin/bash tests/setup-git-test.sh)
# ============================================

set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

REAL_DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REAL_HOME="$HOME"

# ── Mock Setup ────────────────────────────────

setup_git_sandbox() {
    TEST_HOME=$(mktemp -d)
    export HOME="$TEST_HOME"

    DOTFILES_DIR="$REAL_DOTFILES_DIR"
    export DOTFILES_DIR

    # Set non-interactive mode
    INTERACTIVE=false
    export INTERACTIVE
    FORCE_INSTALL=false
    export FORCE_INSTALL

    # Source helpers and the setup-git script
    # shellcheck source=/dev/null
    source "$DOTFILES_DIR/scripts/_helpers.sh"
    # shellcheck source=/dev/null
    source "$DOTFILES_DIR/scripts/setup-git.sh"
}

teardown_git_sandbox() {
    export HOME="$REAL_HOME"
    unset DOTFILES_DIR INTERACTIVE FORCE_INSTALL
    # Clean up any test git config
    rm -rf "$TEST_HOME"
}

# ── Tests ─────────────────────────────────────

echo ""
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║   Setup-Git Tests                                         ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""

# ── Test 1: Defaults are not written ──
# The tracked .gitconfig (symlinked into $HOME) owns the defaults;
# setup_git must not write them through the symlink.
section "Test 1: setup_git leaves git defaults to the tracked .gitconfig"
setup_git_sandbox

GIT_NAME="Test User"
GIT_EMAIL="test@example.com"
EDITOR="nvim"
export GIT_NAME GIT_EMAIL EDITOR

setup_git >/dev/null 2>&1

assert_eq "$(git config --global core.editor 2>/dev/null || true)" "" \
    "core.editor not written by setup_git"
assert_eq "$(git config --global diff.algorithm 2>/dev/null || true)" "" \
    "diff.algorithm not written by setup_git"
assert_eq "$(git config --global core.excludesfile 2>/dev/null || true)" "" \
    "core.excludesfile not written by setup_git"
assert_eq "$(git config --global user.name)" "Test User" \
    "identity is still written"

unset GIT_NAME GIT_EMAIL EDITOR
teardown_git_sandbox
echo ""

# ── Test 2: Tracked .gitconfig stays byte-identical ──
section "Test 2: a re-run over the symlinked .gitconfig does not rewrite it"
setup_git_sandbox

# Mirror install.sh: ~/.gitconfig is a symlink to a tracked copy.
tracked_dir="$TEST_HOME/repo"
mkdir -p "$tracked_dir"
cp "$REAL_DOTFILES_DIR/.gitconfig" "$tracked_dir/.gitconfig"
ln -s "$tracked_dir/.gitconfig" "$TEST_HOME/.gitconfig"
before=$(shasum "$tracked_dir/.gitconfig")

GIT_NAME=$(git config --file "$tracked_dir/.gitconfig" user.name)
GIT_EMAIL=$(git config --file "$tracked_dir/.gitconfig" user.email)
unset EDITOR
export GIT_NAME GIT_EMAIL

setup_git >/dev/null 2>&1

assert_eq "$(shasum "$tracked_dir/.gitconfig")" "$before" \
    "tracked .gitconfig unchanged after setup_git"
assert_eq "$(readlink "$TEST_HOME/.gitconfig")" "$tracked_dir/.gitconfig" \
    "~/.gitconfig is still the symlink"
assert_eq "$(git config --global core.editor)" "nvim" \
    "core.editor still comes from the tracked file"
assert_eq "$(git config --global --path core.excludesfile)" "$TEST_HOME/.gitignore_global" \
    "core.excludesfile still comes from the tracked file"

unset GIT_NAME GIT_EMAIL
teardown_git_sandbox
echo ""

# ── Test 3: Existing editor preserved ──
section "Test 3: setup_git does not clobber a user's core.editor"
setup_git_sandbox

git config --global core.editor "vim"
GIT_NAME="Test User"
GIT_EMAIL="test@example.com"
export GIT_NAME GIT_EMAIL

setup_git >/dev/null 2>&1

assert_eq "$(git config --global core.editor)" "vim" \
    "core.editor left as the user set it"

unset GIT_NAME GIT_EMAIL
teardown_git_sandbox
echo ""

# ── Test 4: Personal identity from env vars ──
section "Test 4: Personal identity set from GIT_NAME and GIT_EMAIL"
setup_git_sandbox

GIT_NAME="Jane Doe"
GIT_EMAIL="jane@personal.com"
export GIT_NAME GIT_EMAIL

setup_git >/dev/null 2>&1

assert_eq "$(git config --global user.name)" "Jane Doe" \
    "user.name set from GIT_NAME"
assert_eq "$(git config --global user.email)" "jane@personal.com" \
    "user.email set from GIT_EMAIL"

unset GIT_NAME GIT_EMAIL
teardown_git_sandbox
echo ""

# ── Test 5: Work identity from env vars ──
section "Test 5: Work identity configured from GIT_WORK_EMAIL"
setup_git_sandbox

GIT_NAME="Jane Doe"
GIT_EMAIL="jane@personal.com"
GIT_WORK_EMAIL="jane@work.com"
WORK_DIR="$TEST_HOME/work"
export GIT_NAME GIT_EMAIL GIT_WORK_EMAIL WORK_DIR

setup_git >/dev/null 2>&1

# shellcheck disable=SC2088
assert_file_exists "$TEST_HOME/.gitconfig-work" \
    "~/.gitconfig-work created"  # tilde is display text
assert_file_contains "$TEST_HOME/.gitconfig-work" "jane@work.com" \
    "Work email in gitconfig-work"

# Verify includeIf was set
includeif_value=$(git config --global "includeIf.gitdir:$TEST_HOME/work/.path" 2>/dev/null || echo "")
# shellcheck disable=SC2088
assert_eq "$includeif_value" "~/.gitconfig-work" \
    "includeIf configured for work directory"  # tilde is literal git config value

# Verify work directory created
if [[ -d "$TEST_HOME/work" ]]; then
    pass "Work directory created"
else
    fail "Work directory not created"
fi

unset GIT_NAME GIT_EMAIL GIT_WORK_EMAIL WORK_DIR
teardown_git_sandbox
echo ""

# ── Test 6: Idempotent — run twice ──
section "Test 6: setup_git is idempotent"
setup_git_sandbox

GIT_NAME="Test User"
GIT_EMAIL="test@example.com"
GIT_WORK_EMAIL="test@work.com"
WORK_DIR="$TEST_HOME/work"
export GIT_NAME GIT_EMAIL GIT_WORK_EMAIL WORK_DIR

setup_git >/dev/null 2>&1

# Snapshot after first run
config1=$(git config --global --list 2>/dev/null | sort)
work1=$(cat "$TEST_HOME/.gitconfig-work")

# Run again
setup_git >/dev/null 2>&1

config2=$(git config --global --list 2>/dev/null | sort)
work2=$(cat "$TEST_HOME/.gitconfig-work")

assert_eq "$config2" "$config1" \
    "Global git config unchanged after second run"
assert_eq "$work2" "$work1" \
    "Work git config unchanged after second run"

unset GIT_NAME GIT_EMAIL GIT_WORK_EMAIL WORK_DIR
teardown_git_sandbox
echo ""

# ── Test 7: No work email skips work setup ──
section "Test 7: No work email skips work identity setup"
setup_git_sandbox

GIT_NAME="Test User"
GIT_EMAIL="test@example.com"
export GIT_NAME GIT_EMAIL

setup_git >/dev/null 2>&1

if [[ ! -f "$TEST_HOME/.gitconfig-work" ]]; then
    pass "No gitconfig-work created without work email"
else
    fail "gitconfig-work should not exist without work email"
fi

unset GIT_NAME GIT_EMAIL
teardown_git_sandbox
echo ""

# ── Test 8: Tilde expansion in work dir ──
section "Test 8: Work directory handles tilde expansion"
setup_git_sandbox

GIT_NAME="Test User"
GIT_EMAIL="test@example.com"
GIT_WORK_EMAIL="test@work.com"
# shellcheck disable=SC2088
WORK_DIR="~/work-expanded"  # tilde is intentional — testing tilde expansion
export GIT_NAME GIT_EMAIL GIT_WORK_EMAIL WORK_DIR

setup_git >/dev/null 2>&1

if [[ -d "$TEST_HOME/work-expanded" ]]; then
    pass "Tilde expanded correctly in work directory"
else
    fail "Tilde expansion failed ($TEST_HOME/work-expanded not found)"
fi

unset GIT_NAME GIT_EMAIL GIT_WORK_EMAIL WORK_DIR
teardown_git_sandbox
echo ""

# ── Test 9: Projects directory created ──
section "Test 9: Personal projects directory created"
setup_git_sandbox

GIT_NAME="Test User"
GIT_EMAIL="test@example.com"
PROJECTS_DIR="$TEST_HOME/my-code"
export GIT_NAME GIT_EMAIL PROJECTS_DIR

setup_git >/dev/null 2>&1

if [[ -d "$TEST_HOME/my-code" ]]; then
    pass "Custom PROJECTS_DIR created"
else
    fail "Custom PROJECTS_DIR not created"
fi

unset GIT_NAME GIT_EMAIL PROJECTS_DIR
teardown_git_sandbox
echo ""

# ── Test 10: Gitignore global belongs to the symlink map ──
section "Test 10: setup_git does not create ~/.gitignore_global"
setup_git_sandbox

GIT_NAME="Test User"
GIT_EMAIL="test@example.com"
export GIT_NAME GIT_EMAIL

setup_git >/dev/null 2>&1

assert_file_not_exists "$TEST_HOME/.gitignore_global" \
    "~/.gitignore_global is linked by the symlink map, not setup_git"
assert_contains "$(grep -c 'gitignore_global' "$REAL_DOTFILES_DIR/scripts/symlink-map.sh")" "1" \
    "symlink map carries .gitignore_global"

unset GIT_NAME GIT_EMAIL
teardown_git_sandbox
