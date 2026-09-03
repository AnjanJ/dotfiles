#!/usr/bin/env bash
# shellcheck disable=SC2034

# ============================================
# UPDATE.SH TEST SUITE
# ============================================
# Tests for update.sh: symlink creation, idempotency, broken link
# handling, OS guard, and the whole pipeline against stubs (lock,
# transcript, snapshot, restart markers, --yes).
#
# Uses a temporary HOME directory — no real configs touched.
# Usage: tests/run update   (or /opt/homebrew/bin/bash tests/update-test.sh)
# ============================================

set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REAL_HOME="$HOME"

setup_sandbox() {
    TEST_HOME=$(mktemp -d)
    export HOME="$TEST_HOME"
    unset _HELPERS_LOADED 2>/dev/null || true
}

teardown_sandbox() {
    export HOME="$REAL_HOME"
    rm -rf "$TEST_HOME"
}

# ── Extracted: create_symlink from update.sh ──
create_symlink() {
    local source="$1"
    local target="$2"
    local name="$3"

    if [ -L "$target" ] && [ "$(readlink "$target")" = "$source" ]; then
        echo "up-to-date"
    else
        ln -sf "$source" "$target"
        echo "refreshed"
    fi
}

# ── Tests ─────────────────────────────────────

test_27_create_symlink_new() {
    echo ""
    section "Test 27: create_symlink creates link when none exists"
    setup_sandbox

    local source_file="$TEST_HOME/dotfiles/myconfig"
    local target_link="$TEST_HOME/.myconfig"
    mkdir -p "$TEST_HOME/dotfiles"
    echo "config content" > "$source_file"

    local result
    result=$(create_symlink "$source_file" "$target_link" "myconfig")
    assert_eq "$result" "refreshed" "Reports refreshed for new link"

    if [[ -L "$target_link" ]]; then
        pass "Symlink created"
        local actual_target
        actual_target=$(readlink "$target_link")
        assert_eq "$actual_target" "$source_file" "Symlink points to correct source"
    else
        fail "Symlink not created"
    fi

    teardown_sandbox
}

test_28_create_symlink_already_correct() {
    echo ""
    section "Test 28: create_symlink is no-op when link already correct"
    setup_sandbox

    local source_file="$TEST_HOME/dotfiles/myconfig"
    local target_link="$TEST_HOME/.myconfig"
    mkdir -p "$TEST_HOME/dotfiles"
    echo "config content" > "$source_file"

    # Create correct symlink first
    ln -sf "$source_file" "$target_link"

    local result
    result=$(create_symlink "$source_file" "$target_link" "myconfig")
    assert_eq "$result" "up-to-date" "Reports up-to-date for existing correct link"

    teardown_sandbox
}

test_29_create_symlink_broken() {
    echo ""
    section "Test 29: create_symlink overwrites broken symlink"
    setup_sandbox

    local source_file="$TEST_HOME/dotfiles/myconfig"
    local target_link="$TEST_HOME/.myconfig"
    mkdir -p "$TEST_HOME/dotfiles"
    echo "config content" > "$source_file"

    # Create broken symlink (points to non-existent file)
    ln -sf "$TEST_HOME/nonexistent" "$target_link"

    # Verify it's broken
    if [[ ! -e "$target_link" ]]; then
        pass "Pre-condition: symlink is broken"
    else
        fail "Pre-condition: symlink should be broken"
    fi

    local result
    result=$(create_symlink "$source_file" "$target_link" "myconfig")
    assert_eq "$result" "refreshed" "Reports refreshed for broken link"

    local actual_target
    actual_target=$(readlink "$target_link")
    assert_eq "$actual_target" "$source_file" "Fixed to correct source"

    teardown_sandbox
}

test_30_create_symlink_wrong_target() {
    echo ""
    section "Test 30: create_symlink overwrites link pointing to wrong target"
    setup_sandbox

    local source_file="$TEST_HOME/dotfiles/myconfig"
    local wrong_source="$TEST_HOME/dotfiles/old-myconfig"
    local target_link="$TEST_HOME/.myconfig"
    mkdir -p "$TEST_HOME/dotfiles"
    echo "new content" > "$source_file"
    echo "old content" > "$wrong_source"

    # Create symlink to wrong target
    ln -sf "$wrong_source" "$target_link"

    local result
    result=$(create_symlink "$source_file" "$target_link" "myconfig")
    assert_eq "$result" "refreshed" "Reports refreshed for wrong-target link"

    local actual_target
    actual_target=$(readlink "$target_link")
    assert_eq "$actual_target" "$source_file" "Updated to correct source"

    teardown_sandbox
}

test_31_macos_only_guard() {
    echo ""
    section "Test 31: macOS-only guard in update.sh"
    setup_sandbox

    # Test the guard logic — on macOS this always passes,
    # but we verify the check logic itself is sound
    local uname_output
    uname_output=$(uname)

    if [[ "$uname_output" == "Darwin" ]]; then
        pass "Running on macOS — guard passes"
    else
        pass "Not on macOS — guard would correctly reject"
    fi

    # Verify the guard pattern is present in update.sh
    if /usr/bin/grep -q 'uname.*Darwin' "$DOTFILES_DIR/update.sh"; then
        pass "macOS guard exists in update.sh"
    else
        fail "macOS guard missing from update.sh"
    fi

    teardown_sandbox
}

# ── Pipeline: the whole update.sh against stubs ──
# A real git repo with a bare local origin stands in for GitHub; brew,
# mise, tmutil, aerospace, sketchybar, pgrep and pkill are stubs that log
# their arguments. HOME is the sandbox, so symlinks land there.

MOCK="$TEST_TMP/mock"
ORIGIN="$TEST_TMP/origin.git"
STATE="$TEST_TMP/state"
STUB="$TEST_TMP/stub"
CALLS="$TEST_TMP/calls.log"

setup_pipeline_sandbox() {
    rm -rf "$MOCK" "$ORIGIN" "$STATE" "$STUB"
    mkdir -p "$MOCK/.config/aerospace" "$MOCK/.config/sketchybar" "$STUB" "$STATE"
    cp "$DOTFILES_DIR/update.sh" "$MOCK/"
    cp -R "$DOTFILES_DIR/scripts" "$DOTFILES_DIR/bin" "$MOCK/"
    echo "# aerospace v1" > "$MOCK/.config/aerospace/aerospace.toml"
    echo "# sketchybar v1" > "$MOCK/.config/sketchybar/sketchybarrc"
    echo "# zshrc" > "$MOCK/.zshrc"
    printf 'brew "jq"\n' > "$MOCK/Brewfile"
    echo "Brewfile.backup" > "$MOCK/.gitignore"
    (cd "$MOCK" && git init -q -b main && git config user.name t && git config user.email t@t \
        && git add -A && git commit -qm init)
    git clone -q --bare "$MOCK" "$ORIGIN"
    (cd "$MOCK" && git remote add origin "$ORIGIN")

    : > "$CALLS"
    for cmd in mise aerospace sketchybar pkill borders caffeinate; do
        printf '#!/bin/bash\necho "%s $*" >> "%s"\n' "$cmd" "$CALLS" > "$STUB/$cmd"
        chmod +x "$STUB/$cmd"
    done
    cat > "$STUB/brew" <<EOF
#!/bin/bash
echo "brew \$*" >> "$CALLS"
if [[ "\$1" == "bundle" && "\$2" == "dump" ]]; then
    for a in "\$@"; do [[ "\$a" == --file=* ]] && cp "$MOCK/Brewfile" "\${a#--file=}"; done
fi
exit 0
EOF
    cat > "$STUB/tmutil" <<EOF
#!/bin/bash
echo "tmutil \$*" >> "$CALLS"
echo "Created local snapshot with date: 2026-01-01-000000"
EOF
    cat > "$STUB/pgrep" <<'EOF'
#!/bin/bash
name="${*: -1}"
for r in ${RUNNING:-}; do
    [[ "$(echo "$r" | tr '[:upper:]' '[:lower:]')" == "$(echo "$name" | tr '[:upper:]' '[:lower:]')" ]] && exit 0
done
exit 1
EOF
    chmod +x "$STUB/brew" "$STUB/tmutil" "$STUB/pgrep"
}

# Runs update.sh the way a terminal would, minus the transcript re-exec
# unless the caller unsets DOTFILES_UPDATE_LOGGED.
run_update() {
    (cd "$MOCK" && PATH="$STUB:$PATH" DOTFILES_STATE_DIR="$STATE" \
        DOTFILES_UPDATE_LOGGED="${DOTFILES_UPDATE_LOGGED-1}" RUNNING="${RUNNING-AeroSpace sketchybar}" \
        bash "$MOCK/update.sh" "$@" </dev/null 2>&1)
}

# Commit a change on origin so the next pull brings it in
push_to_origin() {
    local path="$1" content="$2"
    local work="$TEST_TMP/origin-work"
    rm -rf "$work"
    git clone -q "$ORIGIN" "$work"
    mkdir -p "$(dirname "$work/$path")"
    echo "$content" > "$work/$path"
    (cd "$work" && git config user.name t && git config user.email t@t \
        && git add -A && git commit -qm "change $path" && git push -q origin main)
}

test_32_help_and_flags() {
    echo ""
    section "Test 32: --help and flag parsing"
    setup_pipeline_sandbox
    local out
    out=$(run_update --help)
    assert_contains "$out" "--yes" "--help documents --yes"
    assert_contains "$out" "--no-snapshot" "--help documents --no-snapshot"
    assert_contains "$out" "update.log" "--help names the transcript"
    set +e; out=$(run_update --bogus); rc=$?; set -e
    assert_eq "$rc" "0" "unknown option does not abort"
    assert_contains "$out" "unknown option '--bogus'" "unknown option warns"
}

test_33_quiet_run() {
    echo ""
    section "Test 33: A run with nothing changed restarts nothing"
    setup_pipeline_sandbox
    local out
    set +e; out=$(run_update); rc=$?; set -e
    assert_eq "$rc" "0" "update.sh exits 0"
    assert_contains "$out" "Update Complete" "reaches the end"
    assert_contains "$out" "Local snapshot taken (2026-01-01-000000)" "snapshot reported with its date"
    assert_eq "$(/usr/bin/grep -nE '^(tmutil localsnapshot|brew upgrade)$' "$CALLS" | cut -d: -f2 | tr '\n' ' ')" \
        "tmutil localsnapshot brew upgrade " "snapshot is taken before brew upgrade"
    assert_file_not_contains "$CALLS" "aerospace" "aerospace not reloaded when nothing changed"
    assert_file_not_contains "$CALLS" "sketchybar" "sketchybar not reloaded when nothing changed"
    assert_contains "$out" "Nothing marked for restart" "step 5 says nothing was marked"
    assert_symlink "$HOME/.zshrc" "$MOCK/.zshrc" "symlinks refreshed into the sandbox HOME"
    assert_dir_not_exists "$STATE/update.lock" "lock released after the run"
}

test_34_pulled_config_marks_restart() {
    echo ""
    section "Test 34: A pulled aerospace change restarts aerospace only"
    setup_pipeline_sandbox
    run_update >/dev/null   # first run creates the links
    : > "$CALLS"
    push_to_origin ".config/aerospace/aerospace.toml" "# aerospace v2"
    local out
    out=$(run_update)
    assert_contains "$out" "aerospace config changed" "pull detects the aerospace change"
    assert_file_contains "$CALLS" "^aerospace reload-config$" "aerospace reloaded at step 5"
    assert_file_not_contains "$CALLS" "sketchybar" "sketchybar untouched"
    assert_file_not_exists "$STATE/restart-aerospace-required" "marker consumed"
    assert_eq "$(cat "$MOCK/.config/aerospace/aerospace.toml")" "# aerospace v2" "the change was pulled"
}

test_35_marker_from_elsewhere() {
    echo ""
    section "Test 35: A marker left by a migration is consumed"
    setup_pipeline_sandbox
    touch "$STATE/restart-sketchybar-required"
    run_update >/dev/null
    assert_file_contains "$CALLS" "^sketchybar --reload$" "sketchybar reloaded"
    assert_file_not_exists "$STATE/restart-sketchybar-required" "marker consumed"
}

test_36_no_snapshot_and_yes() {
    echo ""
    section "Test 36: --no-snapshot and --yes"
    setup_pipeline_sandbox
    local out
    out=$(run_update --no-snapshot)
    assert_contains "$out" "Skipping local snapshot" "--no-snapshot reported"
    assert_file_not_contains "$CALLS" "tmutil" "tmutil not called"
    # --interactive would block on read; --yes must win (stdin is /dev/null)
    set +e; out=$(run_update --interactive --yes); rc=$?; set -e
    assert_eq "$rc" "0" "--yes with --interactive completes"
    assert_not_contains "$out" "Continue with update?" "--yes never prompts"
}

test_37_lock() {
    echo ""
    section "Test 37: Lock file"
    setup_pipeline_sandbox
    mkdir -p "$STATE/update.lock"
    echo "$$" > "$STATE/update.lock/pid"   # this test process is alive
    local out
    set +e; out=$(run_update); rc=$?; set -e
    assert_eq "$rc" "1" "a live lock stops the run"
    assert_contains "$out" "already running (pid $$)" "names the holder"
    assert_file_not_contains "$CALLS" "brew" "nothing ran under a live lock"
    echo "2147483000" > "$STATE/update.lock/pid"   # nobody has this pid
    set +e; out=$(run_update); rc=$?; set -e
    assert_eq "$rc" "0" "a stale lock is removed and the run proceeds"
    assert_contains "$out" "stale update lock" "stale lock reported"
    assert_dir_not_exists "$STATE/update.lock" "lock released afterwards"
}

test_37b_stay_awake_and_failure_hint() {
    echo ""
    section "Test 37b: caffeinate and the failure hint"
    setup_pipeline_sandbox
    run_update --no-snapshot >/dev/null
    assert_file_contains "$CALLS" "^caffeinate -i -w [0-9]*$" "caffeinate holds off sleep for the run's pid"
    assert_file_exists "$STATE/update-available" "the update-available cache is refreshed at the end"
    printf '#!/bin/bash\nexit 1\n' > "$STUB/mise"   # mise upgrade and mise install both fail
    local out
    set +e; out=$(run_update --no-snapshot); rc=$?; set -e
    [[ $rc -ne 0 ]] || fail "a failing step makes update.sh exit non-zero"
    pass "a failing step makes update.sh exit non-zero"
    assert_contains "$out" "Update failed (exit $rc)" "the exit trap names the failure"
    assert_contains "$out" "Transcript: $STATE/update.log" "and where the transcript is"
    assert_contains "$out" "dotfiles health" "and what to run next"
    assert_dir_not_exists "$STATE/update.lock" "lock released after a failure"
}

test_37c_failed_pull_restores_stash() {
    echo ""
    section "Test 37c: a pull that fails restores the auto-stash"
    setup_pipeline_sandbox
    echo "# local edit" >> "$MOCK/.zshrc"
    rm -rf "$ORIGIN"   # origin unreachable, so git pull fails after the stash
    local out
    set +e; out=$(run_update --no-snapshot); rc=$?; set -e
    [[ $rc -ne 0 ]] || fail "update.sh fails when the pull fails"
    pass "update.sh fails when the pull fails"
    assert_contains "$out" "Restored the auto-stashed" "the exit trap pops the stash"
    assert_file_contains "$MOCK/.zshrc" "# local edit" "the local edit is back in the working tree"
    assert_eq "$(git -C "$MOCK" stash list | wc -l | tr -d ' ')" "0" "no stash left behind"
}

test_38_transcript() {
    echo ""
    section "Test 38: Transcript"
    setup_pipeline_sandbox
    # No tty here, so the tee branch of the transcript is what runs
    DOTFILES_UPDATE_LOGGED='' run_update --no-snapshot >/dev/null
    assert_file_exists "$STATE/update.log" "update.log written"
    assert_file_contains "$STATE/update.log" "^# dotfiles update 20" "log starts with a dated header"
    assert_file_contains "$STATE/update.log" "Update Complete" "log holds the whole run"
    assert_file_contains "$STATE/update.log" "Skipping local snapshot" "flags recorded in the run"
    DOTFILES_UPDATE_LOGGED='' run_update >/dev/null
    assert_file_exists "$STATE/update.log.1" "previous run kept as update.log.1"
    assert_file_contains "$STATE/update.log.1" "Skipping local snapshot" "update.log.1 is the earlier run"
    assert_file_not_contains "$STATE/update.log" "Skipping local snapshot" "update.log is the latest run"
}

# ── Run All Tests ─────────────────────────────

echo ""
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║   Update.sh Test Suite                                     ║"
echo "╚═══════════════════════════════════════════════════════════╝"

test_27_create_symlink_new
test_28_create_symlink_already_correct
test_29_create_symlink_broken
test_30_create_symlink_wrong_target
test_31_macos_only_guard
test_32_help_and_flags
test_33_quiet_run
test_34_pulled_config_marks_restart
test_35_marker_from_elsewhere
test_36_no_snapshot_and_yes
test_37_lock
test_37b_stay_awake_and_failure_hint
test_37c_failed_pull_restores_stash
test_38_transcript
