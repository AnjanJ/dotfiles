#!/usr/bin/env bash

# ============================================
# DOTFILES BACKUP TEST SUITE
# ============================================
# Tests that dotfiles-backup creates, lists, restores,
# and prunes backups correctly.
#
# Uses temporary directories — no real configs touched.
# Usage: bash tests/test-backup.sh
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
    if echo "$text" | /usr/bin/grep -qF -- "$pattern" 2>/dev/null; then
        pass "$label"
    else
        fail "$label ('$pattern' not found)"
    fi
}

# ── Mock Setup ────────────────────────────────

setup_backup_sandbox() {
    MOCK_DOTFILES=$(mktemp -d)
    TEST_HOME=$(mktemp -d)
    export HOME="$TEST_HOME"

    # Copy scripts needed by dotfiles-backup
    cp -r "$REAL_DOTFILES_DIR/scripts" "$MOCK_DOTFILES/scripts/"
    mkdir -p "$MOCK_DOTFILES/bin"
    cp "$REAL_DOTFILES_DIR/bin/dotfiles-backup" "$MOCK_DOTFILES/bin/dotfiles-backup"

    # Create mock dotfiles that backup will look for
    echo "zshrc content" > "$MOCK_DOTFILES/.zshrc"
    echo "gitignore content" > "$MOCK_DOTFILES/.gitignore_global"
    echo "rubocop" > "$MOCK_DOTFILES/.rubocop.yml"
    mkdir -p "$MOCK_DOTFILES/.config/nvim"
    echo "nvim config" > "$MOCK_DOTFILES/.config/nvim/init.lua"
    mkdir -p "$MOCK_DOTFILES/.config/ghostty"
    echo "ghostty config" > "$MOCK_DOTFILES/.config/ghostty/config"
    echo "starship" > "$MOCK_DOTFILES/.config/starship.toml"
    echo "brewfile" > "$MOCK_DOTFILES/Brewfile"

    # Patch the backup script to use our mock DOTFILES_DIR
    # Replace the readlink resolution line
    sed -i '' "s|DOTFILES_DIR=.*|DOTFILES_DIR=\"$MOCK_DOTFILES\"|" "$MOCK_DOTFILES/bin/dotfiles-backup"
}

teardown_backup_sandbox() {
    export HOME="$REAL_HOME"
    rm -rf "$MOCK_DOTFILES" "$TEST_HOME"
}

# ── Tests ─────────────────────────────────────

echo ""
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║   Dotfiles Backup Tests                                   ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""

# ── Test 1: --help shows usage ──
echo "Test 1: --help shows usage"
setup_backup_sandbox

output=$(bash "$MOCK_DOTFILES/bin/dotfiles-backup" --help 2>&1)

assert_contains "$output" "Usage:" "--help shows usage line"
assert_contains "$output" "--list" "--help mentions --list"
assert_contains "$output" "--restore" "--help mentions --restore"

teardown_backup_sandbox
echo ""

# ── Test 2: Backup creates timestamped directory ──
echo "Test 2: Backup creates timestamped directory"
setup_backup_sandbox

bash "$MOCK_DOTFILES/bin/dotfiles-backup" >/dev/null 2>&1

backup_count=$(find "$TEST_HOME/.dotfiles-backups" -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')
assert_eq "$backup_count" "1" "One backup directory created"

# Check the name matches timestamp pattern (YYYYMMDD_HHMMSS)
backup_name=$(basename "$(find "$TEST_HOME/.dotfiles-backups" -mindepth 1 -maxdepth 1 -type d)")
if [[ "$backup_name" =~ ^[0-9]{8}_[0-9]{6}$ ]]; then
    pass "Backup name matches timestamp pattern"
else
    fail "Backup name '$backup_name' doesn't match YYYYMMDD_HHMMSS"
fi

teardown_backup_sandbox
echo ""

# ── Test 3: Backup includes shell configs ──
echo "Test 3: Backup includes shell configs"
setup_backup_sandbox

bash "$MOCK_DOTFILES/bin/dotfiles-backup" >/dev/null 2>&1
backup_dir=$(find "$TEST_HOME/.dotfiles-backups" -mindepth 1 -maxdepth 1 -type d)

if [[ -f "$backup_dir/.zshrc" ]]; then
    pass "Backup includes .zshrc"
else
    fail "Backup missing .zshrc"
fi

if [[ -f "$backup_dir/.gitignore_global" ]]; then
    pass "Backup includes .gitignore_global"
else
    fail "Backup missing .gitignore_global"
fi

# .rubocop.yml is only known via scripts/symlink-map.sh — proves backup
# walks the map rather than a private list
if [[ -f "$backup_dir/.rubocop.yml" ]]; then
    pass "Backup includes map-only entry .rubocop.yml"
else
    fail "Backup missing .rubocop.yml (backup not reading symlink map?)"
fi

teardown_backup_sandbox
echo ""

# ── Test 4: Backup includes .config directories ──
echo "Test 4: Backup includes .config directories"
setup_backup_sandbox

bash "$MOCK_DOTFILES/bin/dotfiles-backup" >/dev/null 2>&1
backup_dir=$(find "$TEST_HOME/.dotfiles-backups" -mindepth 1 -maxdepth 1 -type d)

if [[ -f "$backup_dir/.config/nvim/init.lua" ]]; then
    pass "Backup includes nvim config"
else
    fail "Backup missing nvim config"
fi

if [[ -f "$backup_dir/.config/ghostty/config" ]]; then
    pass "Backup includes ghostty config"
else
    fail "Backup missing ghostty config"
fi

if [[ -f "$backup_dir/.config/starship.toml" ]]; then
    pass "Backup includes starship.toml"
else
    fail "Backup missing starship.toml"
fi

if [[ -f "$backup_dir/Brewfile" ]]; then
    pass "Backup includes Brewfile"
else
    fail "Backup missing Brewfile"
fi

teardown_backup_sandbox
echo ""

# ── Test 5: Backup prunes old backups (keep 5) ──
echo "Test 5: Backup prunes old backups (keep 5)"
setup_backup_sandbox

# Create 5 existing "old" backups
for i in $(seq 1 5); do
    mkdir -p "$TEST_HOME/.dotfiles-backups/2024010${i}_000000"
    echo "old" > "$TEST_HOME/.dotfiles-backups/2024010${i}_000000/.zshrc"
done

# Create a 6th backup (should trigger pruning)
bash "$MOCK_DOTFILES/bin/dotfiles-backup" >/dev/null 2>&1

backup_count=$(find "$TEST_HOME/.dotfiles-backups" -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')
assert_eq "$backup_count" "5" "Only 5 backups remain after pruning"

# The oldest should be gone
if [[ ! -d "$TEST_HOME/.dotfiles-backups/20240101_000000" ]]; then
    pass "Oldest backup was pruned"
else
    fail "Oldest backup should have been pruned"
fi

teardown_backup_sandbox
echo ""

# ── Test 6: --list shows available backups ──
echo "Test 6: --list shows available backups"
setup_backup_sandbox

# Create a backup first
bash "$MOCK_DOTFILES/bin/dotfiles-backup" >/dev/null 2>&1

output=$(bash "$MOCK_DOTFILES/bin/dotfiles-backup" --list 2>&1)

assert_contains "$output" "Available backups" "--list shows header"
assert_contains "$output" "files)" "--list shows file count"

teardown_backup_sandbox
echo ""

# ── Test 7: --restore restores files correctly ──
echo "Test 7: --restore restores files correctly"
setup_backup_sandbox

# Create a backup
bash "$MOCK_DOTFILES/bin/dotfiles-backup" >/dev/null 2>&1
backup_name=$(basename "$(find "$TEST_HOME/.dotfiles-backups" -mindepth 1 -maxdepth 1 -type d)")

# Modify the source file
echo "modified content" > "$MOCK_DOTFILES/.zshrc"

# Restore with --yes to skip confirmation
bash "$MOCK_DOTFILES/bin/dotfiles-backup" --restore "$backup_name" --yes >/dev/null 2>&1

# Check the file was restored to original content
restored_content=$(cat "$MOCK_DOTFILES/.zshrc")
assert_eq "$restored_content" "zshrc content" "Restored .zshrc has original content"

teardown_backup_sandbox
echo ""

# ── Test 8: --restore with invalid name errors ──
echo "Test 8: --restore with invalid name errors"
setup_backup_sandbox

output=$(bash "$MOCK_DOTFILES/bin/dotfiles-backup" --restore "nonexistent_backup" 2>&1 || true)

assert_contains "$output" "Backup not found" "--restore with bad name shows error"

teardown_backup_sandbox
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
