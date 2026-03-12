#!/usr/bin/env bash

# ============================================
# SETUP-GIT TEST SUITE
# ============================================
# Tests that setup-git.sh correctly configures
# Git identity, defaults, and work identity.
#
# Uses a temporary HOME — no real configs touched.
# Usage: bash tests/test-setup-git.sh
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

assert_file_exists() {
    if [[ -f "$1" ]]; then
        pass "$2"
    else
        fail "$2 ($1 not found)"
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

    # Create gitignore_global so the symlink works
    touch "$DOTFILES_DIR/.gitignore_global"

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

# ── Test 1: Git defaults configured ──
echo "Test 1: Git defaults are configured correctly"
setup_git_sandbox

GIT_NAME="Test User"
GIT_EMAIL="test@example.com"
export GIT_NAME GIT_EMAIL

setup_git >/dev/null 2>&1

assert_eq "$(git config --global pull.rebase)" "false" \
    "pull.rebase set to false"
assert_eq "$(git config --global diff.algorithm)" "histogram" \
    "diff.algorithm set to histogram"
assert_eq "$(git config --global rerere.enabled)" "true" \
    "rerere.enabled set to true"
assert_eq "$(git config --global push.autoSetupRemote)" "true" \
    "push.autoSetupRemote set to true"
assert_eq "$(git config --global branch.sort)" "-committerdate" \
    "branch.sort set to -committerdate"
assert_eq "$(git config --global commit.verbose)" "true" \
    "commit.verbose set to true"

unset GIT_NAME GIT_EMAIL
teardown_git_sandbox
echo ""

# ── Test 2: Respects $EDITOR ──
echo "Test 2: Respects EDITOR environment variable"
setup_git_sandbox

GIT_NAME="Test User"
GIT_EMAIL="test@example.com"
EDITOR="nvim"
export GIT_NAME GIT_EMAIL EDITOR

setup_git >/dev/null 2>&1

assert_eq "$(git config --global core.editor)" "nvim" \
    "core.editor respects EDITOR=nvim"

unset GIT_NAME GIT_EMAIL EDITOR
teardown_git_sandbox
echo ""

# ── Test 3: Default editor without $EDITOR ──
echo "Test 3: Falls back to zed --wait without EDITOR"
setup_git_sandbox

GIT_NAME="Test User"
GIT_EMAIL="test@example.com"
unset EDITOR
export GIT_NAME GIT_EMAIL

setup_git >/dev/null 2>&1

assert_eq "$(git config --global core.editor)" "zed --wait" \
    "core.editor defaults to zed --wait"

unset GIT_NAME GIT_EMAIL
teardown_git_sandbox
echo ""

# ── Test 4: Personal identity from env vars ──
echo "Test 4: Personal identity set from GIT_NAME and GIT_EMAIL"
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
echo "Test 5: Work identity configured from GIT_WORK_EMAIL"
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
assert_contains "$TEST_HOME/.gitconfig-work" "jane@work.com" \
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
echo "Test 6: setup_git is idempotent"
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
echo "Test 7: No work email skips work identity setup"
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
echo "Test 8: Work directory handles tilde expansion"
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
echo "Test 9: Personal projects directory created"
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

# ── Test 10: Gitignore global symlinked ──
echo "Test 10: Global gitignore symlink configured"
setup_git_sandbox

GIT_NAME="Test User"
GIT_EMAIL="test@example.com"
export GIT_NAME GIT_EMAIL

setup_git >/dev/null 2>&1

excludes=$(git config --global core.excludesfile 2>/dev/null || echo "")
assert_eq "$excludes" "$TEST_HOME/.gitignore_global" \
    "core.excludesfile set to ~/.gitignore_global"

unset GIT_NAME GIT_EMAIL
teardown_git_sandbox
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

[[ $FAIL -eq 0 ]]
