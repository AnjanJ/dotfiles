#!/usr/bin/env bash
# shellcheck disable=SC2034,SC2001

# ============================================
# REPOS-CLONE TEST SUITE
# ============================================
# Tests for repos-clone logic: SSH alias detection,
# URL rewriting, range expansion, skip-existing.
#
# Tests the parseable/unit-testable parts only —
# actual git clone + gh/glab calls are not tested.
#
# Uses a temporary HOME directory — no real configs touched.
# Usage: bash tests/test-repos-clone.sh
# ============================================

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
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
    local haystack="$1" needle="$2" label="$3"
    if [[ "$haystack" == *"$needle"* ]]; then
        pass "$label"
    else
        fail "$label ('$needle' not found in output)"
    fi
}

assert_not_contains() {
    local haystack="$1" needle="$2" label="$3"
    if [[ "$haystack" != *"$needle"* ]]; then
        pass "$label"
    else
        fail "$label ('$needle' unexpectedly found in output)"
    fi
}

setup_sandbox() {
    TEST_HOME=$(mktemp -d)
    export HOME="$TEST_HOME"
    mkdir -p "$TEST_HOME/.ssh"
    unset _HELPERS_LOADED 2>/dev/null || true
}

teardown_sandbox() {
    export HOME="$REAL_HOME"
    rm -rf "$TEST_HOME"
}

# ── Helper: extract SSH alias detection logic from repos-clone ──
# This mirrors the alias-detection loop from repos-clone for testing
detect_ssh_aliases() {
    local svc_host="$1"
    local config_file="$2"
    local aliases=()
    local current_host=""
    local current_hostname=""

    while IFS= read -r line; do
        if [[ "$line" =~ ^Host\  ]]; then
            if [[ -n "$current_host" && "$current_hostname" == "$svc_host" && "$current_host" != "$svc_host" ]]; then
                aliases+=("$current_host")
            fi
            current_host="${line#Host }"
            current_hostname=""
        elif [[ "$line" =~ ^[[:space:]]*HostName\  ]]; then
            current_hostname=$(echo "$line" | awk '{print $2}')
        fi
    done < "$config_file"

    # Check last entry
    if [[ -n "$current_host" && "$current_hostname" == "$svc_host" && "$current_host" != "$svc_host" ]]; then
        aliases+=("$current_host")
    fi

    if [[ ${#aliases[@]} -gt 0 ]]; then
        printf '%s\n' "${aliases[@]}"
    fi
}

# ── Helper: range expansion logic from repos-clone ──
expand_selection() {
    local selection="$1"
    local result=""
    for part in $selection; do
        if [[ "$part" =~ ^([0-9]+)-([0-9]+)$ ]]; then
            result+=" $(seq "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}" | tr '\n' ' ')"
        else
            result+=" $part"
        fi
    done
    echo "$result" | tr -s ' ' | sed 's/^ //;s/ $//'
}

# ── Tests ─────────────────────────────────────

test_10_ssh_alias_detection_github() {
    echo ""
    echo "Test 10: SSH alias detection for github.com"
    setup_sandbox

    cat > "$TEST_HOME/.ssh/config" <<EOF
Host github.com
    HostName github.com
    User git

Host github.com-work
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519_work
EOF

    local aliases
    aliases=$(detect_ssh_aliases "github.com" "$TEST_HOME/.ssh/config")
    assert_eq "$aliases" "github.com-work" "Finds github.com-work alias"

    teardown_sandbox
}

test_11_ssh_alias_detection_gitlab() {
    echo ""
    echo "Test 11: SSH alias detection for gitlab.com"
    setup_sandbox

    cat > "$TEST_HOME/.ssh/config" <<EOF
Host gitlab.com
    HostName gitlab.com
    User git

Host gitlab.com-work
    HostName gitlab.com
    User git
    IdentityFile ~/.ssh/id_ed25519_work
EOF

    local aliases
    aliases=$(detect_ssh_aliases "gitlab.com" "$TEST_HOME/.ssh/config")
    assert_eq "$aliases" "gitlab.com-work" "Finds gitlab.com-work alias"

    teardown_sandbox
}

test_12_no_aliases_when_no_match() {
    echo ""
    echo "Test 12: No aliases when SSH config has no matching HostName"
    setup_sandbox

    cat > "$TEST_HOME/.ssh/config" <<EOF
Host github.com
    HostName github.com
    User git

Host myserver
    HostName 192.168.1.100
    User deploy
EOF

    local aliases
    aliases=$(detect_ssh_aliases "github.com" "$TEST_HOME/.ssh/config")
    assert_eq "$aliases" "" "No aliases found for github.com"

    teardown_sandbox
}

test_13_multiple_aliases_same_host() {
    echo ""
    echo "Test 13: Multiple aliases for same host"
    setup_sandbox

    cat > "$TEST_HOME/.ssh/config" <<EOF
Host github.com
    HostName github.com
    User git

Host github.com-work
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519_work

Host github.com-oss
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519_oss
EOF

    local aliases
    aliases=$(detect_ssh_aliases "github.com" "$TEST_HOME/.ssh/config")
    assert_contains "$aliases" "github.com-work" "Finds work alias"
    assert_contains "$aliases" "github.com-oss" "Finds oss alias"

    teardown_sandbox
}

test_14_ssh_url_rewriting() {
    echo ""
    echo "Test 14: SSH URL rewriting with alias substitution"
    setup_sandbox

    local url="git@github.com:org/repo.git"
    local alias="github.com-work"
    local svc_host="github.com"

    local rewritten
    rewritten=$(echo "$url" | sed "s|git@${svc_host}:|git@${alias}:|")
    assert_eq "$rewritten" "git@github.com-work:org/repo.git" "URL rewritten with alias"

    teardown_sandbox
}

test_15_range_expansion() {
    echo ""
    echo "Test 15: Range expansion '1-5 7 9-11'"
    setup_sandbox

    local result
    result=$(expand_selection "1-5 7 9-11")
    assert_eq "$result" "1 2 3 4 5 7 9 10 11" "Range expansion correct"

    # Single numbers
    result=$(expand_selection "3 5 8")
    assert_eq "$result" "3 5 8" "Single numbers pass through"

    # Single range
    result=$(expand_selection "1-3")
    assert_eq "$result" "1 2 3" "Single range expands"

    teardown_sandbox
}

test_16_skip_existing_repos() {
    echo ""
    echo "Test 16: Already-cloned repos are skipped"
    setup_sandbox

    local target="$TEST_HOME/repos"
    mkdir -p "$target/existing-repo"

    # Simulate the skip check from repos-clone
    local dest="$target/existing-repo"
    if [[ -d "$dest" ]]; then
        pass "Existing repo detected for skip"
    else
        fail "Existing repo not detected"
    fi

    # Non-existing should not skip
    dest="$target/new-repo"
    if [[ -d "$dest" ]]; then
        fail "Non-existing repo incorrectly detected"
    else
        pass "New repo allowed to clone"
    fi

    teardown_sandbox
}

test_17_tilde_expansion() {
    echo ""
    echo "Test 17: Target directory with tilde expansion"
    setup_sandbox

    local input="~/projects"
    local expanded="${input/#\~/$HOME}"
    assert_eq "$expanded" "$HOME/projects" "Tilde expanded to \$HOME"

    # Already absolute path should not change
    input="/tmp/repos"
    expanded="${input/#\~/$HOME}"
    assert_eq "$expanded" "/tmp/repos" "Absolute path unchanged"

    teardown_sandbox
}

test_18_unusual_whitespace() {
    echo ""
    echo "Test 18: SSH config with unusual whitespace"
    setup_sandbox

    # Tabs and extra spaces in SSH config
    cat > "$TEST_HOME/.ssh/config" <<EOF
Host github.com
	HostName github.com
	User git

Host github.com-work
	HostName   github.com
	User git
	IdentityFile ~/.ssh/id_ed25519_work
EOF

    local aliases
    aliases=$(detect_ssh_aliases "github.com" "$TEST_HOME/.ssh/config")
    assert_eq "$aliases" "github.com-work" "Handles tabs and extra spaces"

    teardown_sandbox
}

test_19_comments_between_host_hostname() {
    echo ""
    echo "Test 19: SSH config with comments between Host/HostName"
    setup_sandbox

    cat > "$TEST_HOME/.ssh/config" <<EOF
Host github.com
    # Main GitHub account
    HostName github.com
    User git

Host github.com-work
    # Work account
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519_work
EOF

    local aliases
    aliases=$(detect_ssh_aliases "github.com" "$TEST_HOME/.ssh/config")
    assert_eq "$aliases" "github.com-work" "Handles comments between Host/HostName"

    teardown_sandbox
}

# ── Run All Tests ─────────────────────────────

echo ""
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║   Repos-Clone Test Suite                                   ║"
echo "╚═══════════════════════════════════════════════════════════╝"

test_10_ssh_alias_detection_github
test_11_ssh_alias_detection_gitlab
test_12_no_aliases_when_no_match
test_13_multiple_aliases_same_host
test_14_ssh_url_rewriting
test_15_range_expansion
test_16_skip_existing_repos
test_17_tilde_expansion
test_18_unusual_whitespace
test_19_comments_between_host_hostname

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
