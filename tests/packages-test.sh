#!/usr/bin/env bash

# ============================================
# PACKAGE GROUP SELECTION TEST SUITE
# ============================================
# Tests that package-utils.sh correctly parses groups,
# filters Brewfiles, persists state, and handles edge cases.
#
# Uses a temporary directory — no real configs touched.
# Usage: tests/run packages   (or /opt/homebrew/bin/bash tests/packages-test.sh)
# ============================================

set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

REAL_DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REAL_HOME="$HOME"

# ── Test Setup ────────────────────────────────

setup_test_env() {
    TEST_HOME=$(mktemp -d)
    TEST_DOTFILES=$(mktemp -d)
    export HOME="$TEST_HOME"
    export DOTFILES_DIR="$TEST_DOTFILES"

    # Copy package-utils.sh and helpers
    mkdir -p "$TEST_DOTFILES/scripts"
    cp "$REAL_DOTFILES_DIR/scripts/package-utils.sh" "$TEST_DOTFILES/scripts/"
    cp "$REAL_DOTFILES_DIR/scripts/_helpers.sh" "$TEST_DOTFILES/scripts/"

    # Create a test Brewfile with known groups
    cat > "$TEST_DOTFILES/Brewfile" << 'EOF'
# @group taps — Homebrew tap registries (always included)
tap "example/tap"

# @group core — Essential CLI tools (always installed)
brew "git"
brew "fzf"
brew "ripgrep"

# @group editors — Code editors & terminals
brew "neovim"
cask "ghostty"
cask "zed"

# @group work — Enterprise & work apps
cask "slack"
cask "zoom"
mas "Okta Verify", id: 490179405

# @group databases — Database engines & GUI clients
brew "postgresql@14", restart_service: :changed
brew "redis", restart_service: :changed
cask "postico"

# @group fonts — Nerd Fonts collection
cask "font-jetbrains-mono"
cask "font-fira-code"
EOF

    # Source package-utils
    source "$TEST_DOTFILES/scripts/_helpers.sh"
    source "$TEST_DOTFILES/scripts/package-utils.sh"
}

teardown_test_env() {
    export HOME="$REAL_HOME"
    rm -rf "$TEST_HOME" "$TEST_DOTFILES"
}

# ── Tests: Group Parsing ─────────────────────

test_parse_groups() {
    echo ""
    echo "Group Parsing"
    echo "─────────────────────────────────────"

    setup_test_env

    local groups
    groups=$(_parse_brewfile_groups "$TEST_DOTFILES/Brewfile")

    local count
    count=$(echo "$groups" | wc -l | tr -d ' ')
    assert_eq "$count" "6" "Brewfile has 6 groups"

    assert_matches "$groups" "^taps$" "Found taps group"
    assert_matches "$groups" "^core$" "Found core group"
    assert_matches "$groups" "^editors$" "Found editors group"
    assert_matches "$groups" "^work$" "Found work group"
    assert_matches "$groups" "^databases$" "Found databases group"
    assert_matches "$groups" "^fonts$" "Found fonts group"

    teardown_test_env
}

# ── Tests: Group Entries ─────────────────────

test_get_group_entries() {
    echo ""
    echo "Group Entries"
    echo "─────────────────────────────────────"

    setup_test_env

    local core_entries
    core_entries=$(_get_group_entries "$TEST_DOTFILES/Brewfile" "core")
    local core_count
    core_count=$(echo "$core_entries" | wc -l | tr -d ' ')
    assert_eq "$core_count" "3" "Core group has 3 entries"

    assert_matches "$core_entries" 'brew "git"' "Core contains git"

    local work_entries
    work_entries=$(_get_group_entries "$TEST_DOTFILES/Brewfile" "work")
    local work_count
    work_count=$(echo "$work_entries" | wc -l | tr -d ' ')
    assert_eq "$work_count" "3" "Work group has 3 entries"

    assert_matches "$work_entries" 'cask "slack"' "Work contains slack"
    assert_matches "$work_entries" 'cask "zoom"' "Work contains zoom"
    assert_matches "$work_entries" 'mas "Okta Verify"' "Work contains Okta Verify"

    local editors_entries
    editors_entries=$(_get_group_entries "$TEST_DOTFILES/Brewfile" "editors")
    local editors_count
    editors_count=$(echo "$editors_entries" | wc -l | tr -d ' ')
    assert_eq "$editors_count" "3" "Editors group has 3 entries"

    teardown_test_env
}

# ── Tests: Package Count ─────────────────────

test_package_count() {
    echo ""
    echo "Package Count"
    echo "─────────────────────────────────────"

    setup_test_env

    local count
    count=$(_get_group_package_count "$TEST_DOTFILES/Brewfile" "core")
    assert_eq "$count" "3" "Core package count is 3"

    count=$(_get_group_package_count "$TEST_DOTFILES/Brewfile" "work")
    assert_eq "$count" "3" "Work package count is 3"

    count=$(_get_group_package_count "$TEST_DOTFILES/Brewfile" "fonts")
    assert_eq "$count" "2" "Fonts package count is 2"

    teardown_test_env
}

# ── Tests: Required Groups ───────────────────

test_required_groups() {
    echo ""
    echo "Required Groups"
    echo "─────────────────────────────────────"

    setup_test_env

    assert_succeeds "core is required" _is_required_group "core"
    assert_succeeds "taps is required" _is_required_group "taps"
    assert_fails "work is not required" _is_required_group "work"
    assert_fails "editors is not required" _is_required_group "editors"
    assert_fails "fonts is not required" _is_required_group "fonts"

    teardown_test_env
}

# ── Tests: Group Descriptions ────────────────

test_group_descriptions() {
    echo ""
    echo "Group Descriptions"
    echo "─────────────────────────────────────"

    setup_test_env

    local desc
    desc=$(_get_group_description "core")
    assert_eq "$desc" "Essential CLI tools" "Core description correct"

    desc=$(_get_group_description "work")
    assert_eq "$desc" "Enterprise & work apps" "Work description correct"

    desc=$(_get_group_description "editors")
    assert_eq "$desc" "Code editors & terminals" "Editors description correct"

    desc=$(_get_group_description "databases")
    assert_eq "$desc" "Database engines & GUI clients" "Databases description correct"

    desc=$(_get_group_description "unknown-group")
    assert_eq "$desc" "unknown-group" "Unknown group returns name as fallback"

    teardown_test_env
}

# ── Tests: Filtered Brewfile Generation ──────

test_filtered_brewfile_all_selected() {
    echo ""
    echo "Filtered Brewfile — All Selected"
    echo "─────────────────────────────────────"

    setup_test_env

    local selections
    selections=$(printf "+editors\n+work\n+databases\n+fonts")
    local filtered
    filtered=$(generate_filtered_brewfile "$TEST_DOTFILES/Brewfile" "$selections")

    assert_file_exists "$filtered" "Filtered Brewfile created"

    # Required groups always included
    assert_file_contains "$filtered" 'tap "example/tap"' "Taps included (required)"
    assert_file_contains "$filtered" 'brew "git"' "Core git included (required)"
    assert_file_contains "$filtered" 'brew "fzf"' "Core fzf included (required)"

    # Selected groups included
    assert_file_contains "$filtered" 'brew "neovim"' "Editors neovim included"
    assert_file_contains "$filtered" 'cask "slack"' "Work slack included"
    assert_file_contains "$filtered" 'brew "postgresql@14"' "Databases postgresql included"
    assert_file_contains "$filtered" 'cask "font-jetbrains-mono"' "Fonts jetbrains-mono included"

    rm -f "$filtered"
    teardown_test_env
}

test_filtered_brewfile_some_excluded() {
    echo ""
    echo "Filtered Brewfile — Some Groups Excluded"
    echo "─────────────────────────────────────"

    setup_test_env

    # Include editors and databases, exclude work and fonts
    local selections
    selections=$(printf "+editors\n+databases")
    local filtered
    filtered=$(generate_filtered_brewfile "$TEST_DOTFILES/Brewfile" "$selections")

    assert_file_exists "$filtered" "Filtered Brewfile created"

    # Required groups always present
    assert_file_contains "$filtered" 'brew "git"' "Core git always included"

    # Selected groups present
    assert_file_contains "$filtered" 'brew "neovim"' "Editors included"
    assert_file_contains "$filtered" 'brew "postgresql@14"' "Databases included"

    # Excluded groups absent
    assert_file_not_contains "$filtered" 'cask "slack"' "Work slack excluded"
    assert_file_not_contains "$filtered" 'cask "zoom"' "Work zoom excluded"
    assert_file_not_contains "$filtered" 'Okta Verify' "Work Okta excluded"
    assert_file_not_contains "$filtered" 'font-jetbrains-mono' "Fonts excluded"

    rm -f "$filtered"
    teardown_test_env
}

test_filtered_brewfile_individual_exclusion() {
    echo ""
    echo "Filtered Brewfile — Individual Package Exclusion"
    echo "─────────────────────────────────────"

    setup_test_env

    # Include work group but exclude zoom individually
    local selections
    selections=$(printf "+editors\n+work\n+databases\n+fonts\n-work:zoom")
    local filtered
    filtered=$(generate_filtered_brewfile "$TEST_DOTFILES/Brewfile" "$selections")

    assert_file_exists "$filtered" "Filtered Brewfile created"

    # Work group included but zoom excluded
    assert_file_contains "$filtered" 'cask "slack"' "Work slack still included"
    assert_file_not_contains "$filtered" 'cask "zoom"' "Zoom individually excluded"
    assert_file_contains "$filtered" 'Okta Verify' "Okta Verify still included"

    rm -f "$filtered"
    teardown_test_env
}

test_filtered_brewfile_only_core() {
    echo ""
    echo "Filtered Brewfile — Only Core (empty selection)"
    echo "─────────────────────────────────────"

    setup_test_env

    # Empty selections — only required groups
    local selections=""
    local filtered
    filtered=$(generate_filtered_brewfile "$TEST_DOTFILES/Brewfile" "$selections")

    assert_file_exists "$filtered" "Filtered Brewfile created"

    # Only required groups
    assert_file_contains "$filtered" 'tap "example/tap"' "Taps present"
    assert_file_contains "$filtered" 'brew "git"' "Core git present"

    # Everything else absent
    assert_file_not_contains "$filtered" 'brew "neovim"' "Editors absent"
    assert_file_not_contains "$filtered" 'cask "slack"' "Work absent"
    assert_file_not_contains "$filtered" 'brew "postgresql@14"' "Databases absent"
    assert_file_not_contains "$filtered" 'font-jetbrains-mono' "Fonts absent"

    rm -f "$filtered"
    teardown_test_env
}

# ── Tests: State Persistence ─────────────────

test_state_persistence() {
    echo ""
    echo "State Persistence"
    echo "─────────────────────────────────────"

    setup_test_env

    local selections
    selections=$(printf "+editors\n-work\n+databases\n-fonts\n-work:zoom")

    save_selected_groups "$selections"

    assert_file_exists "$PACKAGES_STATE_FILE" "State file created"

    local loaded
    loaded=$(get_saved_groups)

    assert_matches "$loaded" "^+editors$" "Loaded +editors"
    assert_matches "$loaded" "^-work$" "Loaded -work"
    assert_matches "$loaded" "^+databases$" "Loaded +databases"
    assert_matches "$loaded" "^-fonts$" "Loaded -fonts"
    assert_matches "$loaded" "^-work:zoom$" "Loaded -work:zoom exclusion"

    teardown_test_env
}

test_state_no_file() {
    echo ""
    echo "State — No File"
    echo "─────────────────────────────────────"

    setup_test_env

    local exit_code=0
    get_saved_groups 2>/dev/null || exit_code=$?
    assert_eq "$exit_code" "1" "get_saved_groups returns 1 when no state file"

    teardown_test_env
}

# ── Tests: Idempotency ───────────────────────

test_idempotency() {
    echo ""
    echo "Idempotency"
    echo "─────────────────────────────────────"

    setup_test_env

    local selections
    selections=$(printf "+editors\n+work\n-databases\n+fonts")

    local filtered1
    filtered1=$(generate_filtered_brewfile "$TEST_DOTFILES/Brewfile" "$selections")
    local content1
    content1=$(cat "$filtered1")

    local filtered2
    filtered2=$(generate_filtered_brewfile "$TEST_DOTFILES/Brewfile" "$selections")
    local content2
    content2=$(cat "$filtered2")

    assert_eq "$content1" "$content2" "Same selections produce identical Brewfiles"

    rm -f "$filtered1" "$filtered2"
    teardown_test_env
}

# ── Tests: Real Brewfile ─────────────────────

test_real_brewfile_groups() {
    echo ""
    echo "Real Brewfile Groups"
    echo "─────────────────────────────────────"

    # Use the actual Brewfile from the repo
    local real_brewfile="$REAL_DOTFILES_DIR/Brewfile"

    if [[ ! -f "$real_brewfile" ]]; then
        fail "Real Brewfile not found at $real_brewfile"
        return
    fi

    # Temporarily source package-utils with real dotfiles dir
    export DOTFILES_DIR="$REAL_DOTFILES_DIR"
    source "$REAL_DOTFILES_DIR/scripts/package-utils.sh"

    local groups
    groups=$(_parse_brewfile_groups "$real_brewfile")

    # Verify expected groups exist
    local expected_groups=("taps" "core" "editors" "window-mgmt" "terminal-tools" "ai" "databases" "cloud-deploy" "media" "communication" "productivity" "work" "languages" "browsers" "utilities" "fonts" "vscode-ext" "extras")

    for g in "${expected_groups[@]}"; do
        assert_matches "$groups" "^${g}$" "Real Brewfile has group: $g"
    done

    # Verify work group contains expected enterprise apps
    local work_entries
    work_entries=$(_get_group_entries "$real_brewfile" "work")

    assert_matches "$work_entries" "slack" "Work group contains slack"
    assert_matches "$work_entries" "zoom" "Work group contains zoom"

    # Verify browsers group (mixes casks and mas entries)
    local browser_entries
    browser_entries=$(_get_group_entries "$real_brewfile" "browsers")

    assert_matches "$browser_entries" "firefox" "Browsers group contains firefox"
    assert_matches "$browser_entries" "DuckDuckGo" "Browsers group contains DuckDuckGo (mas)"

    # Verify core group has essential tools
    local core_entries
    core_entries=$(_get_group_entries "$real_brewfile" "core")

    assert_matches "$core_entries" '"git"' "Core group contains git"
    assert_matches "$core_entries" '"fzf"' "Core group contains fzf"
    assert_matches "$core_entries" '"mise"' "Core group contains mise"

    export DOTFILES_DIR=""
}

# ── Run All Tests ────────────────────────────

echo ""
echo "  Package Group Selection Tests"
echo "  =========================================="

test_parse_groups
test_get_group_entries
test_package_count
test_required_groups
test_group_descriptions
test_filtered_brewfile_all_selected
test_filtered_brewfile_some_excluded
test_filtered_brewfile_individual_exclusion
test_filtered_brewfile_only_core
test_state_persistence
test_state_no_file
test_idempotency
test_real_brewfile_groups
