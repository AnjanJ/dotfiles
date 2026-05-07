#!/usr/bin/env bash
# shellcheck disable=SC2155,SC2015,SC2295,SC2016,SC2129

# ============================================
# IDEMPOTENCY TEST SUITE
# ============================================
# Tests that all scripts produce identical state
# when run twice with the same inputs.
#
# Uses a temporary HOME directory — no real configs touched.
# Usage: bash tests/test-idempotency.sh
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

assert_count() {
    local file="$1" pattern="$2" expected="$3" label="$4"
    local count
    count=$(/usr/bin/grep -c "$pattern" "$file" 2>/dev/null || echo 0)
    # Trim whitespace/newlines from count
    count=$(echo "$count" | tr -d '[:space:]')
    if [[ "$count" -eq "$expected" ]]; then
        pass "$label"
    else
        fail "$label (expected $expected of '$pattern' in $(basename "$file"), found $count)"
    fi
}

assert_perm() {
    local file="$1" expected="$2" label="$3"
    local actual=$(stat -f '%Lp' "$file" 2>/dev/null || echo "???")
    if [[ "$actual" == "$expected" ]]; then
        pass "$label"
    else
        fail "$label (expected $expected, got $actual)"
    fi
}

# Snapshot: capture file list + checksums under HOME
snapshot() {
    local dir="$1" out="$2"
    find "$dir" -type f \
        -not -path '*/.dotfiles_backup*' \
        -not -path '*/.work-nuke-backup-*' \
        -not -name 'snap*' \
        -not -name 'config_snap*' \
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

# Sandbox: create a temporary HOME
setup_sandbox() {
    TEST_HOME=$(mktemp -d)
    export HOME="$TEST_HOME"
    export GIT_CONFIG_GLOBAL="$TEST_HOME/.gitconfig"
    mkdir -p "$TEST_HOME/.ssh"
    mkdir -p "$TEST_HOME/.dotfiles_backup"
    BACKUP_DIR="$TEST_HOME/.dotfiles_backup"

    # Reset source guard so _helpers.sh can be re-sourced
    unset _HELPERS_LOADED 2>/dev/null || true
}

teardown_sandbox() {
    export HOME="$REAL_HOME"
    unset GIT_CONFIG_GLOBAL
    rm -rf "$TEST_HOME"
}

# ── Tests ─────────────────────────────────────

test_01_helpers_source_guard() {
    echo ""
    echo "Test 1: _helpers.sh source guard"
    setup_sandbox

    unset _HELPERS_LOADED
    source "$DOTFILES_DIR/scripts/_helpers.sh"
    assert_eq "$_HELPERS_LOADED" "1" "_HELPERS_LOADED set to 1"

    # Source again — should be a no-op
    source "$DOTFILES_DIR/scripts/_helpers.sh"
    assert_eq "$_HELPERS_LOADED" "1" "_HELPERS_LOADED still 1 after double-source"

    # Verify functions exist
    declare -f print_step &>/dev/null && pass "print_step defined" || fail "print_step missing"
    declare -f print_fail &>/dev/null && pass "print_fail defined" || fail "print_fail missing"

    teardown_sandbox
}

test_02_setup_git_personal_only() {
    echo ""
    echo "Test 2: setup_git — personal identity only"
    setup_sandbox

    # Need a .gitignore_global to symlink to
    touch "$DOTFILES_DIR/.gitignore_global" 2>/dev/null || true

    unset _HELPERS_LOADED
    source "$DOTFILES_DIR/scripts/setup-git.sh"

    # Use variables instead of piped stdin (new non-interactive API)
    export INTERACTIVE=false
    GIT_NAME="Test User"
    GIT_EMAIL="test@example.com"
    GIT_WORK_EMAIL=""

    # Run 1
    setup_git 2>/dev/null
    snapshot "$TEST_HOME" "$TEST_HOME/snap1"

    # Run 2
    setup_git 2>/dev/null
    snapshot "$TEST_HOME" "$TEST_HOME/snap2"

    assert_snapshots_equal "$TEST_HOME/snap1" "$TEST_HOME/snap2" "State identical after 2 runs"
    assert_eq "$(git config --global user.name)" "Test User" "user.name correct"
    assert_eq "$(git config --global user.email)" "test@example.com" "user.email correct"
    assert_eq "$(git config --global core.editor)" "zed --wait" "core.editor correct"
    assert_eq "$(git config --global diff.algorithm)" "histogram" "diff.algorithm correct"
    assert_eq "$(git config --global rerere.enabled)" "true" "rerere.enabled correct"
    assert_eq "$(git config --global push.autoSetupRemote)" "true" "push.autoSetupRemote correct"
    assert_eq "$(git config --global branch.sort)" "-committerdate" "branch.sort correct"
    assert_eq "$(git config --global commit.verbose)" "true" "commit.verbose correct"

    # No includeIf should exist
    local include_count=$(git config --global --get-regexp 'includeIf' 2>/dev/null | wc -l | tr -d ' ')
    assert_eq "$include_count" "0" "No includeIf entries (personal only)"

    teardown_sandbox
}

test_03_setup_git_with_work() {
    echo ""
    echo "Test 3: setup_git — with work identity"
    setup_sandbox

    touch "$DOTFILES_DIR/.gitignore_global" 2>/dev/null || true
    unset _HELPERS_LOADED
    source "$DOTFILES_DIR/scripts/setup-git.sh"

    # Use variables (new non-interactive API)
    export INTERACTIVE=false
    GIT_NAME="Test User"
    GIT_EMAIL="test@example.com"
    GIT_WORK_EMAIL="work@corp.com"
    WORK_DIR="$TEST_HOME/work"

    # Run 1
    setup_git 2>/dev/null
    snapshot "$TEST_HOME" "$TEST_HOME/snap1"

    # Run 2 (identical input)
    setup_git 2>/dev/null
    snapshot "$TEST_HOME" "$TEST_HOME/snap2"

    assert_snapshots_equal "$TEST_HOME/snap1" "$TEST_HOME/snap2" "State identical after 2 runs"

    # Verify .gitconfig-work
    assert_file_exists "$TEST_HOME/.gitconfig-work" "~/.gitconfig-work created"
    assert_count "$TEST_HOME/.gitconfig-work" "email" 1 "Exactly 1 email in .gitconfig-work"

    # Verify includeIf — exactly ONE entry
    local include_count=$(git config --global --get-all "includeIf.gitdir:${TEST_HOME}/work/.path" 2>/dev/null | wc -l | tr -d ' ')
    assert_eq "$include_count" "1" "Exactly 1 includeIf entry"

    # Verify work directory created
    [[ -d "$TEST_HOME/work" ]] && pass "Work directory created" || fail "Work directory missing"
    teardown_sandbox
}

test_04_setup_git_custom_work_dir() {
    echo ""
    echo "Test 4: setup_git — custom work directory"
    setup_sandbox

    touch "$DOTFILES_DIR/.gitignore_global" 2>/dev/null || true
    unset _HELPERS_LOADED
    source "$DOTFILES_DIR/scripts/setup-git.sh"

    # Use variables (new non-interactive API)
    export INTERACTIVE=false
    GIT_NAME="Test User"
    GIT_EMAIL="test@example.com"
    GIT_WORK_EMAIL="work@acme.com"
    WORK_DIR="$TEST_HOME/projects/acme"

    # Run 1
    setup_git 2>/dev/null
    snapshot "$TEST_HOME" "$TEST_HOME/snap1"

    # Run 2
    setup_git 2>/dev/null
    snapshot "$TEST_HOME" "$TEST_HOME/snap2"

    assert_snapshots_equal "$TEST_HOME/snap1" "$TEST_HOME/snap2" "State identical after 2 runs"

    local include_count=$(git config --global --get-all "includeIf.gitdir:${TEST_HOME}/projects/acme/.path" 2>/dev/null | wc -l | tr -d ' ')
    assert_eq "$include_count" "1" "Exactly 1 includeIf for custom dir"

    [[ -d "$TEST_HOME/projects/acme" ]] && pass "Custom work dir created" || fail "Custom work dir missing"

    teardown_sandbox
}

test_05_ssh_config_overwrite() {
    echo ""
    echo "Test 5: _build_ssh_config — overwrite not append"
    setup_sandbox

    unset _HELPERS_LOADED
    source "$DOTFILES_DIR/scripts/setup-ssh.sh"

    SSH_HOSTS=("github.com|github.com|git|22|id_ed25519_personal")

    # Run 1
    _build_ssh_config "false" 2>/dev/null
    snapshot "$TEST_HOME" "$TEST_HOME/snap1"

    # Run 2
    _build_ssh_config "false" 2>/dev/null
    snapshot "$TEST_HOME" "$TEST_HOME/snap2"

    assert_snapshots_equal "$TEST_HOME/snap1" "$TEST_HOME/snap2" "SSH config identical after 2 runs"
    assert_count "$TEST_HOME/.ssh/config" "Host github.com" 1 "Exactly 1 Host github.com block"
    assert_count "$TEST_HOME/.ssh/config" "^Host \*" 1 "Exactly 1 Host * block"
    assert_perm "$TEST_HOME/.ssh/config" "644" "config permissions 644"

    teardown_sandbox
}

test_06_ssh_config_1password() {
    echo ""
    echo "Test 6: _build_ssh_config — 1Password mode"
    setup_sandbox

    unset _HELPERS_LOADED
    source "$DOTFILES_DIR/scripts/setup-ssh.sh"

    SSH_HOSTS=("github.com|github.com|git|22|")

    # Run 1
    _build_ssh_config "true" 2>/dev/null
    snapshot "$TEST_HOME" "$TEST_HOME/snap1"

    # Run 2
    _build_ssh_config "true" 2>/dev/null
    snapshot "$TEST_HOME" "$TEST_HOME/snap2"

    assert_snapshots_equal "$TEST_HOME/snap1" "$TEST_HOME/snap2" "1Password config identical after 2 runs"
    assert_count "$TEST_HOME/.ssh/config" "IdentityAgent" 1 "Exactly 1 IdentityAgent line"
    assert_count "$TEST_HOME/.ssh/config" "AddKeysToAgent" 0 "No AddKeysToAgent in 1Password mode"
    assert_count "$TEST_HOME/.ssh/config" "UseKeychain" 0 "No UseKeychain in 1Password mode"

    teardown_sandbox
}

test_07_ssh_config_multi_host() {
    echo ""
    echo "Test 7: _build_ssh_config — multiple hosts with aliases"
    setup_sandbox

    unset _HELPERS_LOADED
    source "$DOTFILES_DIR/scripts/setup-ssh.sh"

    SSH_HOSTS=(
        "github.com|github.com|git|22|id_ed25519_personal"
        "github.com-work|github.com|git|22|id_ed25519_work"
        "gitlab.com|gitlab.com|git|22|id_ed25519_personal"
        "gerrit.example.com|gerrit.example.com|review|29418|id_ed25519_work"
    )

    # Run 1
    _build_ssh_config "false" 2>/dev/null
    snapshot "$TEST_HOME" "$TEST_HOME/snap1"

    # Run 2
    _build_ssh_config "false" 2>/dev/null
    snapshot "$TEST_HOME" "$TEST_HOME/snap2"

    assert_snapshots_equal "$TEST_HOME/snap1" "$TEST_HOME/snap2" "Multi-host config identical after 2 runs"
    assert_count "$TEST_HOME/.ssh/config" "Host github.com$" 1 "Exactly 1 Host github.com"
    assert_count "$TEST_HOME/.ssh/config" "Host github.com-work" 1 "Exactly 1 Host github.com-work"
    assert_count "$TEST_HOME/.ssh/config" "Host gitlab.com" 1 "Exactly 1 Host gitlab.com"
    assert_count "$TEST_HOME/.ssh/config" "Host gerrit.example.com" 1 "Exactly 1 Host gerrit.example.com"
    assert_count "$TEST_HOME/.ssh/config" "Port 29418" 1 "Custom port for Gerrit"
    assert_count "$TEST_HOME/.ssh/config" "User review" 1 "Custom user for Gerrit"

    # Verify alias has correct HostName
    local hostname_for_alias=$(/usr/bin/grep -A1 "Host github.com-work" "$TEST_HOME/.ssh/config" | /usr/bin/grep "HostName" | awk '{print $2}')
    assert_eq "$hostname_for_alias" "github.com" "Alias HostName resolves to github.com"

    teardown_sandbox
}

test_08_ssh_permissions() {
    echo ""
    echo "Test 8: _fix_ssh_permissions"
    setup_sandbox

    unset _HELPERS_LOADED
    source "$DOTFILES_DIR/scripts/setup-ssh.sh"

    # Create files with WRONG permissions
    echo "private" > "$TEST_HOME/.ssh/id_ed25519_personal"
    chmod 644 "$TEST_HOME/.ssh/id_ed25519_personal"
    echo "public" > "$TEST_HOME/.ssh/id_ed25519_personal.pub"
    chmod 600 "$TEST_HOME/.ssh/id_ed25519_personal.pub"
    echo "config" > "$TEST_HOME/.ssh/config"
    chmod 777 "$TEST_HOME/.ssh/config"
    echo "hosts" > "$TEST_HOME/.ssh/known_hosts"
    chmod 777 "$TEST_HOME/.ssh/known_hosts"

    # Run 1
    _fix_ssh_permissions 2>/dev/null
    snapshot "$TEST_HOME" "$TEST_HOME/snap1"

    # Run 2
    _fix_ssh_permissions 2>/dev/null
    snapshot "$TEST_HOME" "$TEST_HOME/snap2"

    assert_snapshots_equal "$TEST_HOME/snap1" "$TEST_HOME/snap2" "Permissions identical after 2 runs"
    assert_perm "$TEST_HOME/.ssh" "700" "~/.ssh directory 700"
    assert_perm "$TEST_HOME/.ssh/id_ed25519_personal" "600" "Private key 600"
    assert_perm "$TEST_HOME/.ssh/id_ed25519_personal.pub" "644" "Public key 644"
    assert_perm "$TEST_HOME/.ssh/config" "644" "Config 644"
    assert_perm "$TEST_HOME/.ssh/known_hosts" "644" "known_hosts 644"

    teardown_sandbox
}

test_09_zprofile_guard() {
    echo ""
    echo "Test 9: .zprofile Homebrew PATH guard"
    setup_sandbox

    # Simulate the guard from install.sh
    run_guard() {
        if ! /usr/bin/grep -q '/opt/homebrew/bin/brew shellenv' "$HOME/.zprofile" 2>/dev/null; then
            echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> "$HOME/.zprofile"
        fi
    }

    # Run 1 (no .zprofile exists)
    run_guard
    local count1=$(/usr/bin/grep -c 'brew shellenv' "$HOME/.zprofile")
    assert_eq "$count1" "1" "1 brew line after first run"

    # Run 2
    run_guard
    local count2=$(/usr/bin/grep -c 'brew shellenv' "$HOME/.zprofile")
    assert_eq "$count2" "1" "Still 1 brew line after second run"

    # Run 3
    run_guard
    local count3=$(/usr/bin/grep -c 'brew shellenv' "$HOME/.zprofile")
    assert_eq "$count3" "1" "Still 1 brew line after third run"

    teardown_sandbox
}

test_10_work_setup_sentinel_markers() {
    echo ""
    echo "Test 10: work-setup SSH sentinel markers"
    setup_sandbox

    unset _HELPERS_LOADED

    # Pre-create personal git identity
    git config --global user.name "Test User"
    git config --global user.email "test@example.com"

    # Pre-create a personal SSH config with existing content
    cat > "$TEST_HOME/.ssh/config" <<'EOF'
Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519_personal
EOF

    # Create mock SSH keys
    echo "private" > "$TEST_HOME/.ssh/id_ed25519_work"
    echo "ssh-ed25519 AAAA work@corp.com" > "$TEST_HOME/.ssh/id_ed25519_work.pub"

    # Source work-setup's helpers
    source "$DOTFILES_DIR/bin/_work-helpers"

    # Simulate what work-setup does for SSH (the sentinel marker section)
    add_work_ssh_block() {
        local keyfile="id_ed25519_work"

        # Remove existing work section
        if [[ -f "$HOME/.ssh/config" ]] && /usr/bin/grep -q "# === WORK:" "$HOME/.ssh/config"; then
            local tmpfile=$(mktemp)
            local in_block=false
            while IFS= read -r line; do
                if [[ "$line" =~ ^#\ ===\ WORK: ]]; then
                    in_block=true
                elif [[ "$line" == "# === END WORK ===" ]]; then
                    in_block=false
                elif [[ "$in_block" == false ]]; then
                    echo "$line" >> "$tmpfile"
                fi
            done < "$HOME/.ssh/config"
            # Strip trailing blank lines to prevent accumulation
            sed -e :a -e '/^\n*$/{$d;N;ba' -e '}' "$tmpfile" > "$tmpfile.clean"
            mv "$tmpfile.clean" "$HOME/.ssh/config"
            rm -f "$tmpfile"
        fi

        # Append work section
        echo "" >> "$HOME/.ssh/config"
        echo "# === WORK: corp.com ===" >> "$HOME/.ssh/config"
        echo "Host github.com-work" >> "$HOME/.ssh/config"
        echo "    HostName github.com" >> "$HOME/.ssh/config"
        echo "    User git" >> "$HOME/.ssh/config"
        echo "    IdentityFile ~/.ssh/$keyfile" >> "$HOME/.ssh/config"
        echo "    IdentitiesOnly yes" >> "$HOME/.ssh/config"
        echo "" >> "$HOME/.ssh/config"
        echo "# === END WORK ===" >> "$HOME/.ssh/config"
        chmod 644 "$HOME/.ssh/config"
    }

    # Run 1
    add_work_ssh_block
    cp "$TEST_HOME/.ssh/config" "$TEST_HOME/config_snap1"

    # Run 2
    add_work_ssh_block
    cp "$TEST_HOME/.ssh/config" "$TEST_HOME/config_snap2"

    if diff -q "$TEST_HOME/config_snap1" "$TEST_HOME/config_snap2" &>/dev/null; then
        pass "SSH config identical after 2 runs"
    else
        fail "SSH config differs after 2 runs"
        diff "$TEST_HOME/config_snap1" "$TEST_HOME/config_snap2" | head -10 | sed 's/^/    /'
    fi

    assert_count "$TEST_HOME/.ssh/config" "# === WORK:" 1 "Exactly 1 WORK start marker"
    assert_count "$TEST_HOME/.ssh/config" "# === END WORK ===" 1 "Exactly 1 WORK end marker"
    assert_count "$TEST_HOME/.ssh/config" "Host github.com-work" 1 "Exactly 1 work host block"

    # Verify personal block preserved
    assert_count "$TEST_HOME/.ssh/config" "Host github.com$" 1 "Personal Host block preserved"

    teardown_sandbox
}

test_11_work_nuke_no_work() {
    echo ""
    echo "Test 11: work-nuke when no work configured"
    setup_sandbox

    unset _HELPERS_LOADED

    # Only personal identity
    git config --global user.name "Test User"
    git config --global user.email "test@example.com"

    snapshot "$TEST_HOME" "$TEST_HOME/snap_before"

    # Run work-nuke — should be a no-op (exits after "nothing to nuke")
    bash -c "
        export HOME='$TEST_HOME'
        export GIT_CONFIG_GLOBAL='$TEST_HOME/.gitconfig'
        source '$DOTFILES_DIR/bin/_work-helpers'
        # Inline the check from work-nuke
        if ! is_work_configured; then
            echo 'No work identity configured. Nothing to nuke.'
            exit 0
        fi
    " 2>/dev/null
    local exit_code=$?

    snapshot "$TEST_HOME" "$TEST_HOME/snap_after"

    assert_eq "$exit_code" "0" "Exit code 0"
    assert_snapshots_equal "$TEST_HOME/snap_before" "$TEST_HOME/snap_after" "No files modified"

    teardown_sandbox
}

test_12_includeif_no_duplicates() {
    echo ""
    echo "Test 12: includeIf — no duplicates across 5 runs"
    setup_sandbox

    touch "$DOTFILES_DIR/.gitignore_global" 2>/dev/null || true
    unset _HELPERS_LOADED
    source "$DOTFILES_DIR/scripts/setup-git.sh"

    export INTERACTIVE=false
    GIT_NAME="Test User"
    GIT_EMAIL="test@example.com"
    GIT_WORK_EMAIL="work@corp.com"
    WORK_DIR="$TEST_HOME/work"

    # Run 5 times
    for i in 1 2 3 4 5; do
        setup_git 2>/dev/null
    done

    local include_count=$(git config --global --get-all "includeIf.gitdir:${TEST_HOME}/work/.path" 2>/dev/null | wc -l | tr -d ' ')
    assert_eq "$include_count" "1" "Still exactly 1 includeIf after 5 runs"

    local total_includes=$(/usr/bin/grep -c 'includeIf' "$TEST_HOME/.gitconfig" 2>/dev/null || echo 0)
    assert_eq "$total_includes" "1" "Total includeIf lines in .gitconfig = 1"

    teardown_sandbox
}

test_13_zshrc_work_preserved() {
    echo ""
    echo "Test 13: ~/.zshrc-work customizations preserved"
    setup_sandbox

    # Create initial .zshrc-work with the template
    cat > "$TEST_HOME/.zshrc-work" <<'EOF'
# WORK-SPECIFIC CONFIGURATION
alias deploy='echo deploying'
export CUSTOM_VAR=123
EOF

    # Simulate work-setup's step 5 logic
    if [[ -f "$HOME/.zshrc-work" ]]; then
        echo "  ~/.zshrc-work already exists (keeping your customizations)" > /dev/null
    else
        echo "# TEMPLATE" > "$HOME/.zshrc-work"
    fi

    # Verify custom content preserved
    assert_count "$TEST_HOME/.zshrc-work" "alias deploy" 1 "Custom alias preserved"
    assert_count "$TEST_HOME/.zshrc-work" "CUSTOM_VAR" 1 "Custom env var preserved"
    assert_count "$TEST_HOME/.zshrc-work" "TEMPLATE" 0 "Template not written over existing"

    teardown_sandbox
}

test_14_git_config_defaults_idempotent() {
    echo ""
    echo "Test 14: git config defaults — values unchanged on re-run"
    setup_sandbox

    unset _HELPERS_LOADED
    source "$DOTFILES_DIR/scripts/setup-git.sh"

    export INTERACTIVE=false
    GIT_NAME="Test User"
    GIT_EMAIL="test@example.com"
    GIT_WORK_EMAIL=""

    # Run 1: set everything
    setup_git 2>/dev/null

    # User manually changes a setting
    git config --global core.editor "vim"
    assert_eq "$(git config --global core.editor)" "vim" "User changed editor to vim"

    # Run 2: setup_git overwrites it back
    setup_git 2>/dev/null
    assert_eq "$(git config --global core.editor)" "zed --wait" "Editor reset to zed --wait (expected: setup_git is authoritative)"

    teardown_sandbox
}

test_15_nuke_setup_cycle() {
    echo ""
    echo "Test 15: work-nuke + work-setup cycle"
    setup_sandbox

    unset _HELPERS_LOADED

    git config --global user.name "Test User"
    git config --global user.email "test@example.com"

    # Create mock SSH keys
    echo "private" > "$TEST_HOME/.ssh/id_ed25519_work"
    echo "ssh-ed25519 AAAA work@corp.com" > "$TEST_HOME/.ssh/id_ed25519_work.pub"

    source "$DOTFILES_DIR/bin/_work-helpers"

    # Simulate work-setup: create work identity
    git config --global "includeIf.gitdir:${TEST_HOME}/work/.path" "~/.gitconfig-work"
    cat > "$TEST_HOME/.gitconfig-work" <<EOF
[user]
    email = work@corp.com
EOF
    mkdir -p "$TEST_HOME/work"

    # Add SSH work section
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

    cat > "$TEST_HOME/.zshrc-work" <<'EOF'
# work config
EOF

    # Verify setup
    assert_file_exists "$TEST_HOME/.gitconfig-work" "Setup: .gitconfig-work exists"
    assert_file_exists "$TEST_HOME/.zshrc-work" "Setup: .zshrc-work exists"

    # Simulate work-nuke
    rm "$TEST_HOME/.gitconfig-work"
    git config --global --unset-all "includeIf.gitdir:${TEST_HOME}/work/.path" 2>/dev/null || true
    rm "$TEST_HOME/.zshrc-work"

    # Remove SSH work section
    tmpfile=$(mktemp)
    in_block=false
    while IFS= read -r line; do
        if [[ "$line" =~ ^#\ ===\ WORK: ]]; then
            in_block=true
        elif [[ "$line" == "# === END WORK ===" ]]; then
            in_block=false
        elif [[ "$in_block" == false ]]; then
            echo "$line" >> "$tmpfile"
        fi
    done < "$TEST_HOME/.ssh/config"
    mv "$tmpfile" "$TEST_HOME/.ssh/config"

    # Verify nuke
    assert_file_not_exists "$TEST_HOME/.gitconfig-work" "Nuke: .gitconfig-work removed"
    assert_file_not_exists "$TEST_HOME/.zshrc-work" "Nuke: .zshrc-work removed"
    local include_count=$(git config --global --get-regexp 'includeIf' 2>/dev/null | wc -l | tr -d ' ')
    assert_eq "$include_count" "0" "Nuke: no includeIf entries remain"
    assert_count "$TEST_HOME/.ssh/config" "# === WORK:" 0 "Nuke: no WORK markers in SSH config"
    assert_count "$TEST_HOME/.ssh/config" "Host github.com-work" 0 "Nuke: work host block removed"

    # Verify personal config survived
    assert_count "$TEST_HOME/.ssh/config" "Host github.com" 1 "Nuke: personal host block survived"

    # Re-setup (same as before)
    git config --global "includeIf.gitdir:${TEST_HOME}/work/.path" "~/.gitconfig-work"
    cat > "$TEST_HOME/.gitconfig-work" <<EOF
[user]
    email = work@corp.com
EOF

    assert_file_exists "$TEST_HOME/.gitconfig-work" "Re-setup: .gitconfig-work recreated"
    include_count=$(git config --global --get-all "includeIf.gitdir:${TEST_HOME}/work/.path" 2>/dev/null | wc -l | tr -d ' ')
    assert_eq "$include_count" "1" "Re-setup: exactly 1 includeIf entry"

    teardown_sandbox
}

test_16_ssh_config_no_key_field() {
    echo ""
    echo "Test 16: _build_ssh_config — host with no key (1Password)"
    setup_sandbox

    unset _HELPERS_LOADED
    source "$DOTFILES_DIR/scripts/setup-ssh.sh"

    # Empty keyfile field (5th field empty)
    SSH_HOSTS=(
        "github.com|github.com|git|22|"
        "gitlab.com|gitlab.com|git|22|"
    )

    _build_ssh_config "true" 2>/dev/null

    # Should NOT have any IdentityFile lines
    assert_count "$TEST_HOME/.ssh/config" "IdentityFile" 0 "No IdentityFile in 1Password mode"
    # But should still have IdentitiesOnly
    assert_count "$TEST_HOME/.ssh/config" "IdentitiesOnly yes" 2 "IdentitiesOnly on each host"

    teardown_sandbox
}

test_17_work_helpers_functions_with_no_config() {
    echo ""
    echo "Test 17: _work-helpers functions — graceful with no config"
    setup_sandbox

    unset _HELPERS_LOADED
    source "$DOTFILES_DIR/bin/_work-helpers"

    # get_work_email with no .gitconfig-work
    local email=$(get_work_email)
    assert_eq "$email" "" "get_work_email returns empty when no config"

    # get_work_dir with no includeIf
    local dir=$(get_work_dir)
    assert_eq "$dir" "" "get_work_dir returns empty when no includeIf"

    # is_work_configured should return false
    if is_work_configured; then
        fail "is_work_configured should be false"
    else
        pass "is_work_configured returns false correctly"
    fi

    # get_work_ssh_hosts with no SSH config
    rm -f "$TEST_HOME/.ssh/config"
    local hosts=$(get_work_ssh_hosts)
    assert_eq "$hosts" "" "get_work_ssh_hosts returns empty with no config"

    # count_repos on non-existent directory
    local count=$(count_repos "$TEST_HOME/nonexistent")
    assert_eq "$count" "0" "count_repos returns 0 for nonexistent dir"

    teardown_sandbox
}

test_18_work_helpers_functions_with_config() {
    echo ""
    echo "Test 18: _work-helpers functions — correct with config"
    setup_sandbox

    unset _HELPERS_LOADED
    source "$DOTFILES_DIR/bin/_work-helpers"

    # Set up personal identity
    git config --global user.name "Test User"
    git config --global user.email "test@example.com"

    # Set up work identity
    git config --global "includeIf.gitdir:${TEST_HOME}/work/.path" "~/.gitconfig-work"
    cat > "$TEST_HOME/.gitconfig-work" <<EOF
[user]
    email = work@corp.com
EOF
    mkdir -p "$TEST_HOME/work"

    # Set up SSH config with work markers
    cat > "$TEST_HOME/.ssh/config" <<EOF
# === WORK: corp.com ===
Host github.com-work
    HostName github.com
# === END WORK ===
EOF

    assert_eq "$(get_work_email)" "work@corp.com" "get_work_email returns correct email"
    assert_eq "$(get_personal_email)" "test@example.com" "get_personal_email returns correct email"
    assert_eq "$(get_personal_name)" "Test User" "get_personal_name returns correct name"

    local work_dir=$(get_work_dir)
    assert_eq "$work_dir" "${TEST_HOME}/work" "get_work_dir returns correct path"

    if is_work_configured; then
        pass "is_work_configured returns true"
    else
        fail "is_work_configured should be true"
    fi

    local hosts=$(get_work_ssh_hosts)
    assert_eq "$hosts" "github.com-work" "get_work_ssh_hosts finds work host"

    teardown_sandbox
}

# ── Run All Tests ─────────────────────────────

echo ""
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║   Idempotency Test Suite                                   ║"
echo "╚═══════════════════════════════════════════════════════════╝"

test_19_llm_ollama_plugin_idempotent() {
    echo ""
    echo "Test 19: install.sh step 7b — llm-ollama plugin install is idempotent"
    setup_sandbox

    # Stub `llm` so the test never touches the real CLI
    local STUB_DIR="$HOME/stubs"
    mkdir -p "$STUB_DIR"
    local CALL_LOG="$HOME/llm-calls.log"
    : > "$CALL_LOG"

    /bin/cat > "$STUB_DIR/llm" <<EOF
#!/usr/bin/env bash
echo "\$*" >> "$CALL_LOG"
case "\$1" in
    plugins)
        # First run: empty (no plugins). After install: report plugin present.
        if [[ -f "$HOME/.plugin-installed" ]]; then
            echo "llm-ollama  0.16.0"
        else
            echo ""
        fi
        ;;
    install)
        touch "$HOME/.plugin-installed"
        echo "installed: \$2"
        ;;
esac
exit 0
EOF
    chmod +x "$STUB_DIR/llm"

    # Reproduce the install.sh step 7b logic
    run_step_7b() {
        PATH="$STUB_DIR:$PATH" bash -c '
            if command -v llm &>/dev/null; then
                if ! llm plugins 2>/dev/null | grep -q llm-ollama; then
                    llm install llm-ollama >/dev/null
                fi
            fi
        '
    }

    # Run 1 (fresh — should call install)
    run_step_7b
    local installs_after_1=$(/usr/bin/grep -c "^install llm-ollama" "$CALL_LOG")
    assert_eq "$installs_after_1" "1" "Run 1: plugin installed once"
    assert_file_exists "$HOME/.plugin-installed" "Run 1: install marker created"

    # Run 2 (already installed — should NOT call install)
    run_step_7b
    local installs_after_2=$(/usr/bin/grep -c "^install llm-ollama" "$CALL_LOG")
    assert_eq "$installs_after_2" "1" "Run 2: still 1 install (idempotent)"

    # Run 3 (sanity)
    run_step_7b
    local installs_after_3=$(/usr/bin/grep -c "^install llm-ollama" "$CALL_LOG")
    assert_eq "$installs_after_3" "1" "Run 3: still 1 install (idempotent)"

    teardown_sandbox
}

test_01_helpers_source_guard
test_02_setup_git_personal_only
test_03_setup_git_with_work
test_04_setup_git_custom_work_dir
test_05_ssh_config_overwrite
test_06_ssh_config_1password
test_07_ssh_config_multi_host
test_08_ssh_permissions
test_09_zprofile_guard
test_10_work_setup_sentinel_markers
test_11_work_nuke_no_work
test_12_includeif_no_duplicates
test_13_zshrc_work_preserved
test_14_git_config_defaults_idempotent
test_15_nuke_setup_cycle
test_16_ssh_config_no_key_field
test_17_work_helpers_functions_with_no_config
test_18_work_helpers_functions_with_config
test_19_llm_ollama_plugin_idempotent

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
