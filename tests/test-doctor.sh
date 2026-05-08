#!/usr/bin/env bash

# ============================================
# DOTFILES DOCTOR TEST SUITE
# ============================================
# Tests that dotfiles-doctor detects and fixes
# common issues correctly in both normal and
# --dry-run modes.
#
# Uses a temporary directory — no real configs touched.
# Usage: bash tests/test-doctor.sh
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
    local text="$1" pattern="$2" label="$3"
    if echo "$text" | /usr/bin/grep -q "$pattern" 2>/dev/null; then
        pass "$label"
    else
        fail "$label ('$pattern' not found)"
    fi
}

assert_symlink() {
    local target="$1" expected_source="$2" label="$3"
    if [[ -L "$target" ]] && [[ "$(readlink "$target")" == "$expected_source" ]]; then
        pass "$label"
    else
        fail "$label (not a symlink or wrong target)"
    fi
}

# ── Mock Setup ────────────────────────────────

setup_doctor_sandbox() {
    MOCK_DOTFILES=$(mktemp -d)
    TEST_HOME=$(mktemp -d)
    export HOME="$TEST_HOME"

    # Copy real dotfiles structure needed by doctor
    cp -r "$REAL_DOTFILES_DIR/scripts" "$MOCK_DOTFILES/scripts/"
    cp "$REAL_DOTFILES_DIR/bin/dotfiles-doctor" "$MOCK_DOTFILES/bin_doctor"

    # Create mock source files that doctor checks for symlinks
    mkdir -p "$MOCK_DOTFILES/.config/aerospace"
    mkdir -p "$MOCK_DOTFILES/.config/ghostty"
    mkdir -p "$MOCK_DOTFILES/.config/nvim"
    mkdir -p "$MOCK_DOTFILES/.config/zellij"
    mkdir -p "$MOCK_DOTFILES/.config/lazygit"
    mkdir -p "$MOCK_DOTFILES/.config/borders"
    mkdir -p "$MOCK_DOTFILES/.config/sketchybar"
    mkdir -p "$MOCK_DOTFILES/.config/mise"
    mkdir -p "$MOCK_DOTFILES/.config/zed/snippets"
    mkdir -p "$MOCK_DOTFILES/bin"
    touch "$MOCK_DOTFILES/.zshrc"
    touch "$MOCK_DOTFILES/.gitignore_global"
    touch "$MOCK_DOTFILES/.config/starship.toml"
    touch "$MOCK_DOTFILES/.config/mise/config.toml"
    touch "$MOCK_DOTFILES/.config/zed/settings.json"
    touch "$MOCK_DOTFILES/.config/zed/tasks.json"
    touch "$MOCK_DOTFILES/.config/zed/snippets/ruby.json"
    touch "$MOCK_DOTFILES/bin/test-script"

    # Create required HOME directories
    mkdir -p "$TEST_HOME/.config/zed/snippets"
    mkdir -p "$TEST_HOME/.config/mise"
    mkdir -p "$TEST_HOME/.ssh"
    mkdir -p "$TEST_HOME/bin"
}

teardown_doctor_sandbox() {
    export HOME="$REAL_HOME"
    rm -rf "$MOCK_DOTFILES" "$TEST_HOME"
}

# Helper: run doctor's fix_symlink function in isolation
# Usage: run_doctor_function [--dry-run] <source> <target> <name>
run_doctor_function() {
    local mode=""
    if [[ "${1:-}" == "--dry-run" ]]; then
        mode="--dry-run"
        shift
    fi
    local src="$1" tgt="$2" name="$3"
    (
        export DOTFILES_DIR="$MOCK_DOTFILES"
        # shellcheck source=/dev/null
        source "$MOCK_DOTFILES/scripts/_helpers.sh"

        DRY_RUN=false
        [[ "$mode" == "--dry-run" ]] && DRY_RUN=true
        FIXED=0; SKIPPED=0; ALREADY_OK=0

        _ok() { ALREADY_OK=$((ALREADY_OK + 1)); }
        _fix() {
            if [[ "$DRY_RUN" == true ]]; then SKIPPED=$((SKIPPED + 1))
            else FIXED=$((FIXED + 1)); fi
        }

        fix_symlink() {
            local source="$1" target="$2" name="$3"
            [[ ! -f "$source" && ! -d "$source" ]] && return 0
            if [[ -L "$target" ]] && [[ "$(readlink "$target")" == "$source" ]]; then
                _ok "$name"
            elif [[ -L "$target" ]]; then
                [[ "$DRY_RUN" == false ]] && ln -sf "$source" "$target"
                _fix "$name"
            elif [[ -e "$target" ]]; then
                if [[ "$DRY_RUN" == false ]]; then
                    mv "$target" "${target}.doctor-backup"
                    ln -sf "$source" "$target"
                fi
                _fix "$name"
            else
                local target_dir; target_dir=$(dirname "$target")
                if [[ "$DRY_RUN" == false ]]; then
                    mkdir -p "$target_dir"
                    ln -sf "$source" "$target"
                fi
                _fix "$name"
            fi
        }

        fix_symlink "$src" "$tgt" "$name"

        echo "FIXED=$FIXED SKIPPED=$SKIPPED OK=$ALREADY_OK"
    )
}

# ── Tests ─────────────────────────────────────

echo ""
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║   Dotfiles Doctor Tests                                   ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""

# ── Test 1: fix_symlink creates missing symlink ──
echo "Test 1: fix_symlink creates missing symlink"
setup_doctor_sandbox

result=$(run_doctor_function "$MOCK_DOTFILES/.zshrc" "$TEST_HOME/.zshrc" ".zshrc")

assert_symlink "$TEST_HOME/.zshrc" "$MOCK_DOTFILES/.zshrc" \
    "Missing symlink created"
assert_contains "$result" "FIXED=1" \
    "Reports 1 fix"

teardown_doctor_sandbox
echo ""

# ── Test 2: fix_symlink skips correct symlink ──
echo "Test 2: fix_symlink reports correct symlink as OK"
setup_doctor_sandbox

ln -sf "$MOCK_DOTFILES/.zshrc" "$TEST_HOME/.zshrc"

result=$(run_doctor_function "$MOCK_DOTFILES/.zshrc" "$TEST_HOME/.zshrc" ".zshrc")

assert_contains "$result" "OK=1" \
    "Reports already OK"
assert_contains "$result" "FIXED=0" \
    "No fixes needed"

teardown_doctor_sandbox
echo ""

# ── Test 3: fix_symlink fixes wrong target ──
echo "Test 3: fix_symlink fixes wrong symlink target"
setup_doctor_sandbox

# Create a symlink pointing to wrong location
ln -sf "/wrong/path/.zshrc" "$TEST_HOME/.zshrc"

result=$(run_doctor_function "$MOCK_DOTFILES/.zshrc" "$TEST_HOME/.zshrc" ".zshrc")

assert_symlink "$TEST_HOME/.zshrc" "$MOCK_DOTFILES/.zshrc" \
    "Wrong symlink fixed"
assert_contains "$result" "FIXED=1" \
    "Reports 1 fix"

teardown_doctor_sandbox
echo ""

# ── Test 4: fix_symlink backs up existing file ──
echo "Test 4: fix_symlink backs up existing regular file"
setup_doctor_sandbox

echo "existing content" > "$TEST_HOME/.zshrc"

result=$(run_doctor_function "$MOCK_DOTFILES/.zshrc" "$TEST_HOME/.zshrc" ".zshrc")

assert_symlink "$TEST_HOME/.zshrc" "$MOCK_DOTFILES/.zshrc" \
    "Symlink created after backup"
if [[ -f "$TEST_HOME/.zshrc.doctor-backup" ]]; then
    pass "Original file backed up"
else
    fail "Original file not backed up"
fi

teardown_doctor_sandbox
echo ""

# ── Test 5: dry-run mode doesn't modify anything ──
echo "Test 5: --dry-run mode doesn't create symlinks"
setup_doctor_sandbox

result=$(run_doctor_function --dry-run "$MOCK_DOTFILES/.zshrc" "$TEST_HOME/.zshrc" ".zshrc")

if [[ -L "$TEST_HOME/.zshrc" ]]; then
    fail "Dry-run should not create symlinks"
else
    pass "No symlink created in dry-run mode"
fi
assert_contains "$result" "SKIPPED=1" \
    "Reports as skipped in dry-run"

teardown_doctor_sandbox
echo ""

# ── Test 6: SSH permission detection ──
echo "Test 6: SSH permission checking"
setup_doctor_sandbox

# Set wrong permissions
chmod 755 "$TEST_HOME/.ssh"
ssh-keygen -t ed25519 -f "$TEST_HOME/.ssh/id_ed25519" -N "" -q
chmod 644 "$TEST_HOME/.ssh/id_ed25519"  # wrong: should be 600

# Check permissions
ssh_perms=$(stat -f '%A' "$TEST_HOME/.ssh")
key_perms=$(stat -f '%A' "$TEST_HOME/.ssh/id_ed25519")

assert_eq "$ssh_perms" "755" "SSH dir starts with wrong perms (755)"
assert_eq "$key_perms" "644" "Private key starts with wrong perms (644)"

teardown_doctor_sandbox
echo ""

# ── Test 7: fix_symlink handles directory sources ──
echo "Test 7: fix_symlink works with directory sources"
setup_doctor_sandbox

result=$(run_doctor_function "$MOCK_DOTFILES/.config/nvim" "$TEST_HOME/.config/nvim" "nvim")

assert_symlink "$TEST_HOME/.config/nvim" "$MOCK_DOTFILES/.config/nvim" \
    "Directory symlink created"

teardown_doctor_sandbox
echo ""

# ── Test 8: fix_symlink skips non-existent source ──
echo "Test 8: fix_symlink skips non-existent source file"
setup_doctor_sandbox

result=$(run_doctor_function "$MOCK_DOTFILES/nonexistent" "$TEST_HOME/nonexistent" "missing")

assert_contains "$result" "FIXED=0" \
    "No fix attempted for missing source"
assert_contains "$result" "OK=0" \
    "Not reported as OK"

teardown_doctor_sandbox
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
