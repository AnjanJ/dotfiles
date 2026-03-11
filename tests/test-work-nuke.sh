#!/usr/bin/env bash

# ============================================
# WORK-NUKE TEST SUITE
# ============================================
# Tests for work-nuke edge cases: confirmation,
# dry-run, symlinked dirs, malformed markers.
#
# Uses a temporary HOME directory — no real configs touched.
# Usage: bash tests/test-work-nuke.sh
# ============================================

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REAL_HOME="$HOME"

# ── Test Framework ────────────────────────────

PASS=0
FAIL=0
FAILURES=()

pass() {
    ((PASS++))
    echo -e "  \033[0;32m✓\033[0m $1"
}

fail() {
    ((FAIL++))
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

assert_file_not_exists() {
    if [[ ! -f "$1" ]]; then
        pass "$2"
    else
        fail "$2 ($1 still exists)"
    fi
}

assert_dir_exists() {
    if [[ -d "$1" ]]; then
        pass "$2"
    else
        fail "$2 ($1 not found)"
    fi
}

assert_dir_not_exists() {
    if [[ ! -d "$1" ]]; then
        pass "$2"
    else
        fail "$2 ($1 still exists)"
    fi
}

assert_count() {
    local file="$1" pattern="$2" expected="$3" label="$4"
    local count
    count=$(/usr/bin/grep -c "$pattern" "$file" 2>/dev/null || echo 0)
    count=$(echo "$count" | tr -d '[:space:]')
    if [[ "$count" -eq "$expected" ]]; then
        pass "$label"
    else
        fail "$label (expected $expected of '$pattern' in $(basename "$file"), found $count)"
    fi
}

snapshot() {
    local dir="$1" out="$2"
    find "$dir" -type f \
        -not -path '*/.dotfiles_backup*' \
        -not -path '*/.work-nuke-backup-*' \
        -not -name 'snap*' \
        | sort \
        | while read -r f; do
            local rel="${f#$dir}"
            local md5=$(md5 -q "$f" 2>/dev/null || md5sum "$f" | awk '{print $1}')
            local perm=$(stat -f '%Lp' "$f" 2>/dev/null || stat -c '%a' "$f" 2>/dev/null)
            echo "$perm $md5 $rel"
        done > "$out"
}

assert_snapshots_equal() {
    local snap1="$1" snap2="$2" label="$3"
    if diff -q "$snap1" "$snap2" &>/dev/null; then
        pass "$label"
    else
        fail "$label"
        echo "    --- Diff ---"
        diff "$snap1" "$snap2" | head -20 | sed 's/^/    /'
    fi
}

setup_sandbox() {
    TEST_HOME=$(mktemp -d)
    export HOME="$TEST_HOME"
    export GIT_CONFIG_GLOBAL="$TEST_HOME/.gitconfig"
    mkdir -p "$TEST_HOME/.ssh"
    unset _HELPERS_LOADED 2>/dev/null || true
}

teardown_sandbox() {
    export HOME="$REAL_HOME"
    unset GIT_CONFIG_GLOBAL
    rm -rf "$TEST_HOME"
}

# Helper: set up a full work identity in sandbox
setup_work_identity() {
    git config --global user.name "Test User"
    git config --global user.email "test@example.com"

    git config --global "includeIf.gitdir:${TEST_HOME}/work/.path" "~/.gitconfig-work"
    cat > "$TEST_HOME/.gitconfig-work" <<EOF
[user]
    email = work@corp.com
EOF
    mkdir -p "$TEST_HOME/work/repo1/.git"
    mkdir -p "$TEST_HOME/work/repo2/.git"

    cat > "$TEST_HOME/.ssh/config" <<EOF
Host github.com
    HostName github.com
    User git

# === WORK: corp.com ===
Host github.com-work
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519_work
    IdentitiesOnly yes

# === END WORK ===
EOF

    echo "private" > "$TEST_HOME/.ssh/id_ed25519_work"
    echo "ssh-ed25519 AAAA work@corp.com" > "$TEST_HOME/.ssh/id_ed25519_work.pub"

    cat > "$TEST_HOME/.zshrc-work" <<'EOF'
# work config
alias deploy='echo deploying'
EOF
}

# ── Tests ─────────────────────────────────────

test_01_nuke_removes_all_work_config() {
    echo ""
    echo "Test 1: work-nuke removes all work config with --yes"
    setup_sandbox

    unset _HELPERS_LOADED
    setup_work_identity
    source "$DOTFILES_DIR/bin/_work-helpers"

    # Verify setup is complete
    assert_file_exists "$TEST_HOME/.gitconfig-work" "Pre: .gitconfig-work exists"
    assert_file_exists "$TEST_HOME/.zshrc-work" "Pre: .zshrc-work exists"
    assert_dir_exists "$TEST_HOME/work" "Pre: work dir exists"

    # Run nuke with --yes
    bash -c "
        export HOME='$TEST_HOME'
        export GIT_CONFIG_GLOBAL='$TEST_HOME/.gitconfig'
        bash '$DOTFILES_DIR/bin/work-nuke' --yes
    " 2>/dev/null

    assert_file_not_exists "$TEST_HOME/.gitconfig-work" "Post: .gitconfig-work removed"
    assert_file_not_exists "$TEST_HOME/.zshrc-work" "Post: .zshrc-work removed"
    assert_dir_not_exists "$TEST_HOME/work" "Post: work dir removed"

    # Verify includeIf removed
    local include_count=$(git config --global --get-regexp 'includeIf' 2>/dev/null | wc -l | tr -d ' ')
    assert_eq "$include_count" "0" "Post: no includeIf entries remain"

    # Verify work SSH section removed
    assert_count "$TEST_HOME/.ssh/config" "# === WORK:" 0 "Post: no WORK markers"
    assert_count "$TEST_HOME/.ssh/config" "Host github.com-work" 0 "Post: work host removed"

    # Verify personal SSH config survived
    assert_count "$TEST_HOME/.ssh/config" "Host github.com" 1 "Post: personal host preserved"

    teardown_sandbox
}

test_02_nuke_creates_backup() {
    echo ""
    echo "Test 2: work-nuke creates backup before removing"
    setup_sandbox

    unset _HELPERS_LOADED
    setup_work_identity

    bash -c "
        export HOME='$TEST_HOME'
        export GIT_CONFIG_GLOBAL='$TEST_HOME/.gitconfig'
        bash '$DOTFILES_DIR/bin/work-nuke' --yes
    " 2>/dev/null

    # Find backup directory
    local backup_dir
    backup_dir=$(ls -d "$TEST_HOME/.work-nuke-backup-"* 2>/dev/null | head -1)

    if [[ -n "$backup_dir" ]]; then
        pass "Backup directory created"
        assert_file_exists "$backup_dir/.gitconfig-work" "Backup contains .gitconfig-work"
        assert_file_exists "$backup_dir/ssh-config" "Backup contains ssh-config"
        assert_file_exists "$backup_dir/.zshrc-work" "Backup contains .zshrc-work"
    else
        fail "Backup directory not created"
    fi

    teardown_sandbox
}

test_03_nuke_dry_run() {
    echo ""
    echo "Test 3: work-nuke --dry-run changes nothing"
    setup_sandbox

    unset _HELPERS_LOADED
    setup_work_identity

    snapshot "$TEST_HOME" "$TEST_HOME/snap_before"

    bash -c "
        export HOME='$TEST_HOME'
        export GIT_CONFIG_GLOBAL='$TEST_HOME/.gitconfig'
        bash '$DOTFILES_DIR/bin/work-nuke' --dry-run
    " 2>/dev/null

    snapshot "$TEST_HOME" "$TEST_HOME/snap_after"

    assert_snapshots_equal "$TEST_HOME/snap_before" "$TEST_HOME/snap_after" "Dry run: no files modified"
    assert_file_exists "$TEST_HOME/.gitconfig-work" "Dry run: .gitconfig-work still exists"
    assert_file_exists "$TEST_HOME/.zshrc-work" "Dry run: .zshrc-work still exists"
    assert_dir_exists "$TEST_HOME/work" "Dry run: work dir still exists"

    teardown_sandbox
}

test_04_confirm_rejects_wrong_input() {
    echo ""
    echo "Test 4: confirm_destructive rejects partial/wrong input"
    setup_sandbox

    unset _HELPERS_LOADED
    source "$DOTFILES_DIR/bin/_work-helpers"

    # Test wrong inputs (note: bash `read` trims leading/trailing whitespace)
    local wrong_inputs=("nuk" "NUKE" "" "yes" "nuke!")
    for input in "${wrong_inputs[@]}"; do
        if echo "$input" | confirm_destructive "test" "nuke" 2>/dev/null; then
            fail "confirm_destructive accepted '$input'"
        else
            pass "confirm_destructive rejected '$input'"
        fi
    done

    teardown_sandbox
}

test_05_confirm_accepts_exact_match() {
    echo ""
    echo "Test 5: confirm_destructive accepts exact match"
    setup_sandbox

    unset _HELPERS_LOADED
    source "$DOTFILES_DIR/bin/_work-helpers"

    if echo "nuke" | confirm_destructive "test" "nuke" 2>/dev/null; then
        pass "confirm_destructive accepted 'nuke'"
    else
        fail "confirm_destructive rejected 'nuke'"
    fi

    if echo "myword" | confirm_destructive "test" "myword" 2>/dev/null; then
        pass "confirm_destructive accepted custom word 'myword'"
    else
        fail "confirm_destructive rejected custom word 'myword'"
    fi

    teardown_sandbox
}

test_06_nuke_symlinked_work_dir() {
    echo ""
    echo "Test 6: work-nuke with symlinked work directory"
    setup_sandbox

    unset _HELPERS_LOADED

    git config --global user.name "Test User"
    git config --global user.email "test@example.com"

    # Create real directory and symlink
    local real_dir="$TEST_HOME/real-projects"
    mkdir -p "$real_dir/repo1/.git"
    ln -s "$real_dir" "$TEST_HOME/work"

    git config --global "includeIf.gitdir:${TEST_HOME}/work/.path" "~/.gitconfig-work"
    cat > "$TEST_HOME/.gitconfig-work" <<EOF
[user]
    email = work@corp.com
EOF

    cat > "$TEST_HOME/.ssh/config" <<EOF
# === WORK: corp.com ===
Host github.com-work
    HostName github.com
    User git
# === END WORK ===
EOF

    bash -c "
        export HOME='$TEST_HOME'
        export GIT_CONFIG_GLOBAL='$TEST_HOME/.gitconfig'
        bash '$DOTFILES_DIR/bin/work-nuke' --yes
    " 2>/dev/null

    # work-nuke uses rm -rf which follows through symlinks
    assert_file_not_exists "$TEST_HOME/.gitconfig-work" "Post: .gitconfig-work removed"

    # The symlink should be gone (rm -rf removes the symlink target)
    if [[ ! -e "$TEST_HOME/work" ]]; then
        pass "Symlink or target removed"
    else
        fail "Symlink still exists"
    fi

    teardown_sandbox
}

test_07_nuke_preserves_personal_ssh() {
    echo ""
    echo "Test 7: work-nuke preserves personal SSH config outside WORK markers"
    setup_sandbox

    unset _HELPERS_LOADED
    setup_work_identity

    # Add extra personal SSH config
    cat > "$TEST_HOME/.ssh/config" <<EOF
Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519_personal

Host gitlab.com
    HostName gitlab.com
    User git
    IdentityFile ~/.ssh/id_ed25519_personal

# === WORK: corp.com ===
Host github.com-work
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519_work
    IdentitiesOnly yes

# === END WORK ===
EOF

    bash -c "
        export HOME='$TEST_HOME'
        export GIT_CONFIG_GLOBAL='$TEST_HOME/.gitconfig'
        bash '$DOTFILES_DIR/bin/work-nuke' --yes
    " 2>/dev/null

    assert_count "$TEST_HOME/.ssh/config" "Host github.com$" 1 "Personal github.com preserved"
    assert_count "$TEST_HOME/.ssh/config" "Host gitlab.com" 1 "Personal gitlab.com preserved"
    assert_count "$TEST_HOME/.ssh/config" "id_ed25519_personal" 2 "Personal key references preserved"
    assert_count "$TEST_HOME/.ssh/config" "# === WORK:" 0 "No WORK markers remain"
    assert_count "$TEST_HOME/.ssh/config" "github.com-work" 0 "Work host removed"

    teardown_sandbox
}

test_08_nuke_dirty_repos_backup() {
    echo ""
    echo "Test 8: work-nuke with dirty repos still creates backup"
    setup_sandbox

    unset _HELPERS_LOADED
    setup_work_identity

    # Make a real git repo with dirty state
    cd "$TEST_HOME/work/repo1"
    git init 2>/dev/null
    echo "file" > test.txt
    git add test.txt
    git commit -m "init" 2>/dev/null
    echo "dirty" > uncommitted.txt
    cd "$REAL_HOME"

    bash -c "
        export HOME='$TEST_HOME'
        export GIT_CONFIG_GLOBAL='$TEST_HOME/.gitconfig'
        bash '$DOTFILES_DIR/bin/work-nuke' --yes
    " 2>/dev/null

    # Backup should still be created
    local backup_dir
    backup_dir=$(ls -d "$TEST_HOME/.work-nuke-backup-"* 2>/dev/null | head -1)

    if [[ -n "$backup_dir" ]]; then
        pass "Backup created despite dirty repos"
    else
        fail "Backup not created"
    fi

    teardown_sandbox
}

test_09_malformed_work_markers() {
    echo ""
    echo "Test 9: SSH config with nested/malformed WORK markers"
    setup_sandbox

    unset _HELPERS_LOADED

    git config --global user.name "Test User"
    git config --global user.email "test@example.com"
    git config --global "includeIf.gitdir:${TEST_HOME}/work/.path" "~/.gitconfig-work"
    cat > "$TEST_HOME/.gitconfig-work" <<EOF
[user]
    email = work@corp.com
EOF

    # Create SSH config with nested markers (malformed)
    cat > "$TEST_HOME/.ssh/config" <<EOF
Host github.com
    HostName github.com
    User git

# === WORK: corp.com ===
Host github.com-work
    HostName github.com
    User git
# === WORK: nested-bad ===
Host extra-host
    HostName extra.com
# === END WORK ===
# === END WORK ===
EOF

    cat > "$TEST_HOME/.zshrc-work" <<'EOF'
# work config
EOF

    bash -c "
        export HOME='$TEST_HOME'
        export GIT_CONFIG_GLOBAL='$TEST_HOME/.gitconfig'
        bash '$DOTFILES_DIR/bin/work-nuke' --yes
    " 2>/dev/null

    # Personal config should survive
    assert_count "$TEST_HOME/.ssh/config" "Host github.com" 1 "Personal host preserved with malformed markers"

    # All WORK markers should be removed
    assert_count "$TEST_HOME/.ssh/config" "# === WORK:" 0 "All WORK start markers removed"
    assert_count "$TEST_HOME/.ssh/config" "# === END WORK ===" 0 "All END WORK markers removed"
    assert_count "$TEST_HOME/.ssh/config" "Host github.com-work" 0 "Work host removed"
    assert_count "$TEST_HOME/.ssh/config" "Host extra-host" 0 "Nested work host removed"

    teardown_sandbox
}

# ── Run All Tests ─────────────────────────────

echo ""
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║   Work-Nuke Test Suite                                     ║"
echo "╚═══════════════════════════════════════════════════════════╝"

test_01_nuke_removes_all_work_config
test_02_nuke_creates_backup
test_03_nuke_dry_run
test_04_confirm_rejects_wrong_input
test_05_confirm_accepts_exact_match
test_06_nuke_symlinked_work_dir
test_07_nuke_preserves_personal_ssh
test_08_nuke_dirty_repos_backup
test_09_malformed_work_markers

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
