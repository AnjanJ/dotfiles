#!/usr/bin/env bash

# ============================================
# WORK STATUS & WORK SWITCH TEST SUITE
# ============================================
# Tests work-status and work-switch scripts.
#
# Uses a temporary HOME — no real configs touched.
# Usage: bash tests/test-work-status.sh
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

assert_contains() {
    local text="$1" pattern="$2" label="$3"
    if echo "$text" | /usr/bin/grep -q "$pattern" 2>/dev/null; then
        pass "$label"
    else
        fail "$label ('$pattern' not found)"
    fi
}

assert_not_contains() {
    local text="$1" pattern="$2" label="$3"
    if ! echo "$text" | /usr/bin/grep -q "$pattern" 2>/dev/null; then
        pass "$label"
    else
        fail "$label ('$pattern' unexpectedly found)"
    fi
}

# ── Mock Setup ────────────────────────────────

setup_work_sandbox() {
    TEST_HOME=$(mktemp -d)
    export HOME="$TEST_HOME"
    mkdir -p "$TEST_HOME/.ssh"
    mkdir -p "$TEST_HOME/bin"

    # Create symlinks for work scripts so they can find _work-helpers
    ln -sf "$REAL_DOTFILES_DIR/bin/_work-helpers" "$TEST_HOME/bin/_work-helpers"
    ln -sf "$REAL_DOTFILES_DIR/bin/work-status" "$TEST_HOME/bin/work-status"
    ln -sf "$REAL_DOTFILES_DIR/bin/work-switch" "$TEST_HOME/bin/work-switch"
    ln -sf "$REAL_DOTFILES_DIR/bin/work-nuke" "$TEST_HOME/bin/work-nuke"
    ln -sf "$REAL_DOTFILES_DIR/bin/work-setup" "$TEST_HOME/bin/work-setup"

    # Initialize minimal git config
    git config --global user.name "Test User"
    git config --global user.email "test@personal.com"
}

setup_work_identity() {
    # Create work identity
    cat > "$TEST_HOME/.gitconfig-work" <<EOF
[user]
    email = test@work.com
EOF
    mkdir -p "$TEST_HOME/work"
    # shellcheck disable=SC2088
    git config --global "includeIf.gitdir:$TEST_HOME/work/.path" "~/.gitconfig-work"  # tilde is literal git config value
}

setup_work_ssh() {
    cat > "$TEST_HOME/.ssh/config" <<EOF
# === WORK: TestCorp ===
Host github.com-work
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519_work
# === END WORK ===
EOF
}

teardown_work_sandbox() {
    export HOME="$REAL_HOME"
    rm -rf "$TEST_HOME"
}

# ── Tests ─────────────────────────────────────

echo ""
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║   Work Status & Switch Tests                              ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""

# ── Test 1: work-status with no work config ──
echo "Test 1: work-status shows warning when no work config"
setup_work_sandbox

output=$(bash "$TEST_HOME/bin/work-status" 2>&1) || true

assert_contains "$output" "No work identity configured" \
    "Shows no work identity message"
assert_contains "$output" "work-setup" \
    "Suggests running work-setup"

teardown_work_sandbox
echo ""

# ── Test 2: work-status with work identity ──
echo "Test 2: work-status shows configured identity"
setup_work_sandbox
setup_work_identity

output=$(bash "$TEST_HOME/bin/work-status" 2>&1) || true

assert_contains "$output" "test@work.com" \
    "Shows work email"
assert_contains "$output" "test@personal.com" \
    "Shows personal email"
assert_contains "$output" "Test User" \
    "Shows personal name"
assert_contains "$output" "$TEST_HOME/work" \
    "Shows work directory"

teardown_work_sandbox
echo ""

# ── Test 3: work-status shows SSH hosts ──
echo "Test 3: work-status shows SSH host configuration"
setup_work_sandbox
setup_work_identity
setup_work_ssh

output=$(bash "$TEST_HOME/bin/work-status" 2>&1) || true

assert_contains "$output" "github.com-work" \
    "Shows work SSH host"

teardown_work_sandbox
echo ""

# ── Test 4: work-status shows .zshrc-work presence ──
echo "Test 4: work-status detects .zshrc-work"
setup_work_sandbox
setup_work_identity

# Without .zshrc-work
output=$(bash "$TEST_HOME/bin/work-status" 2>&1) || true
assert_contains "$output" "not found" \
    "Reports .zshrc-work missing"

# With .zshrc-work
echo "# work config" > "$TEST_HOME/.zshrc-work"
output=$(bash "$TEST_HOME/bin/work-status" 2>&1) || true
assert_contains "$output" "zshrc-work exists" \
    "Reports .zshrc-work present"

teardown_work_sandbox
echo ""

# ── Test 5: work-status counts repos ──
echo "Test 5: work-status counts repos in work directory"
setup_work_sandbox
setup_work_identity

# Create mock repos
mkdir -p "$TEST_HOME/work/repo1/.git"
mkdir -p "$TEST_HOME/work/repo2/.git"
mkdir -p "$TEST_HOME/work/repo3/.git"

output=$(bash "$TEST_HOME/bin/work-status" 2>&1) || true

assert_contains "$output" "3" \
    "Counts 3 repos in work directory"

teardown_work_sandbox
echo ""

# ── Test 6: _work-helpers functions ──
echo "Test 6: _work-helpers config reader functions"
setup_work_sandbox
setup_work_identity

# Test helper functions directly
result=$(bash -c "
    source '$TEST_HOME/bin/_work-helpers'
    echo \"email=\$(get_work_email)\"
    echo \"personal=\$(get_personal_email)\"
    echo \"name=\$(get_personal_name)\"
    echo \"dir=\$(get_work_dir)\"
    echo \"configured=\$(is_work_configured && echo yes || echo no)\"
")

assert_contains "$result" "email=test@work.com" \
    "get_work_email returns work email"
assert_contains "$result" "personal=test@personal.com" \
    "get_personal_email returns personal email"
assert_contains "$result" "name=Test User" \
    "get_personal_name returns name"
assert_contains "$result" "configured=yes" \
    "is_work_configured returns true"

teardown_work_sandbox
echo ""

# ── Test 7: _work-helpers when not configured ──
echo "Test 7: _work-helpers returns empty when no work config"
setup_work_sandbox

result=$(bash -c "
    source '$TEST_HOME/bin/_work-helpers'
    echo \"email=\$(get_work_email)\"
    echo \"configured=\$(is_work_configured && echo yes || echo no)\"
")

assert_contains "$result" "email=" \
    "get_work_email returns empty"
assert_contains "$result" "configured=no" \
    "is_work_configured returns false"

teardown_work_sandbox
echo ""

# ── Test 8: get_work_ssh_hosts extracts hosts ──
echo "Test 8: get_work_ssh_hosts parses SSH config markers"
setup_work_sandbox
setup_work_ssh

result=$(bash -c "
    source '$TEST_HOME/bin/_work-helpers'
    get_work_ssh_hosts
")

assert_contains "$result" "github.com-work" \
    "Extracts host from work SSH markers"

teardown_work_sandbox
echo ""

# ── Test 9: get_work_ssh_hosts with no markers ──
echo "Test 9: get_work_ssh_hosts returns empty without markers"
setup_work_sandbox

cat > "$TEST_HOME/.ssh/config" <<EOF
Host github.com
    HostName github.com
    User git
EOF

result=$(bash -c "
    source '$TEST_HOME/bin/_work-helpers'
    get_work_ssh_hosts
" 2>&1) || true

assert_not_contains "$result" "github.com" \
    "No hosts returned without work markers"

teardown_work_sandbox
echo ""

# ── Test 10: count_repos and list_dirty_repos ──
echo "Test 10: count_repos and list_dirty_repos"
setup_work_sandbox

mkdir -p "$TEST_HOME/projects/clean-repo/.git"
mkdir -p "$TEST_HOME/projects/dirty-repo/.git"

# Init dirty repo with uncommitted changes
(cd "$TEST_HOME/projects/dirty-repo" && git init -q && echo "test" > file.txt && git add file.txt && git commit -q -m "init" && echo "dirty" >> file.txt)
# Init clean repo
(cd "$TEST_HOME/projects/clean-repo" && git init -q && echo "test" > file.txt && git add file.txt && git commit -q -m "init")

result=$(bash -c "
    source '$TEST_HOME/bin/_work-helpers'
    echo \"count=\$(count_repos '$TEST_HOME/projects')\"
    echo \"dirty=\$(list_dirty_repos '$TEST_HOME/projects')\"
")

assert_contains "$result" "count=2" \
    "count_repos finds 2 repos"
assert_contains "$result" "dirty-repo" \
    "list_dirty_repos finds dirty repo"
assert_not_contains "$result" "clean-repo" \
    "list_dirty_repos excludes clean repo"

teardown_work_sandbox
echo ""

# ── Test 11: work-switch --help ──
echo "Test 11: work-switch --help shows usage"
setup_work_sandbox

output=$(bash "$TEST_HOME/bin/work-switch" --help 2>&1) || true

assert_contains "$output" "Usage: work-switch" \
    "Shows usage information"
assert_contains "$output" "Change employer" \
    "Describes purpose"

teardown_work_sandbox
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
