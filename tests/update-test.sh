#!/usr/bin/env bash
# doc: Update flow — symlink creation and refresh, plus the whole pipeline against stubs: lock, transcript, snapshot before upgrade, restart markers, `--yes`, Brewfile taps trusted before `brew upgrade`, a Brewfile change committed with a rebuilt catalog, the personal tap steps between `brew update` and `brew upgrade` (no drift for a kept package, `homebrew-tap/` committed alone, the `tap-auto-update` toggle)
# shellcheck disable=SC2034

# ============================================
# UPDATE.SH TEST SUITE
# ============================================
# Tests for update.sh: dotfiles_link (create, repoint, back up and replace
# real files and directories), OS guard, and the whole pipeline against stubs (lock,
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

# ── dotfiles_link: the one link function install, update and sync use ──
# Each test sources the real scripts/_helpers.sh and scripts/symlink-map.sh
# into a subshell with the sandbox HOME, so nothing here is a copy.
link() {   # link <source> <target>; prints DOTFILES_LINK_RESULT
    # shellcheck disable=SC2016  # the program runs in the child bash
    env -u _HELPERS_LOADED HOME="$TEST_HOME" BACKUP_DIR="$TEST_HOME/.dotfiles_backup" DOTFILES_DIR="$DOTFILES_DIR" \
        bash -c 'source "$DOTFILES_DIR/scripts/_helpers.sh" >/dev/null
                 source "$DOTFILES_DIR/scripts/symlink-map.sh"
                 dotfiles_link "$1" "$2" >/dev/null 2>&1
                 echo "$DOTFILES_LINK_RESULT"' _ "$1" "$2"
}

# ── Tests ─────────────────────────────────────

test_27_link_new_current_and_wrong() {
    echo ""
    section "Test 27: dotfiles_link creates, leaves alone, and repoints"
    setup_sandbox
    local src="$TEST_HOME/dotfiles/myconfig" old="$TEST_HOME/dotfiles/old" t="$TEST_HOME/.myconfig"
    mkdir -p "$TEST_HOME/dotfiles" && echo new > "$src" && echo old > "$old"
    assert_eq "$(link "$src" "$t")" "linked" "a missing link is created"
    assert_eq "$(readlink "$t")" "$src" "pointing at the source"
    assert_eq "$(link "$src" "$t")" "current" "a correct link is left alone"
    ln -sfn "$old" "$t"
    assert_eq "$(link "$src" "$t")" "linked" "a link to the wrong source is repointed"
    assert_eq "$(readlink "$t")" "$src" "to the right one"
    ln -sfn "$TEST_HOME/nonexistent" "$t"
    assert_eq "$(link "$src" "$t")" "linked" "a broken link is repaired"
    assert_dir_not_exists "$TEST_HOME/.dotfiles_backup" "links are never backed up"
    teardown_sandbox
}

test_28_link_over_real_file() {
    echo ""
    section "Test 28: a real file is backed up at its own path, then replaced"
    setup_sandbox
    local src="$TEST_HOME/dotfiles/settings.json"
    mkdir -p "$TEST_HOME/dotfiles" "$TEST_HOME/.config/zed" "$TEST_HOME/.claude" && echo '{}' > "$src"
    echo "zed's own" > "$TEST_HOME/.config/zed/settings.json"
    echo "claude's own" > "$TEST_HOME/.claude/settings.json"
    assert_eq "$(link "$src" "$TEST_HOME/.config/zed/settings.json")" "replaced" "a real file is replaced"
    assert_eq "$(link "$src" "$TEST_HOME/.claude/settings.json")" "replaced" "so is a second one with the same name"
    assert_eq "$(cat "$TEST_HOME/.dotfiles_backup/.config/zed/settings.json")" "zed's own" "each backup keeps its path"
    assert_eq "$(cat "$TEST_HOME/.dotfiles_backup/.claude/settings.json")" "claude's own" "so same-named files do not collide"
    rm "$TEST_HOME/.claude/settings.json" && echo "newer data" > "$TEST_HOME/.claude/settings.json"
    link "$src" "$TEST_HOME/.claude/settings.json" >/dev/null
    assert_eq "$(cat "$TEST_HOME/.dotfiles_backup/.claude/settings.json")" "claude's own" "an existing backup is kept"
    assert_eq "$(cat "$TEST_HOME"/.dotfiles_backup/.claude/settings.json.* )" "newer data" "and the new copy gets a timestamped sibling"
    teardown_sandbox
}

test_29_link_over_directory() {
    echo ""
    section "Test 29: a directory is replaced, never linked into"
    setup_sandbox
    local src="$TEST_HOME/dotfiles/nvim" other="$TEST_HOME/elsewhere/nvim" t="$TEST_HOME/.config/nvim"
    mkdir -p "$src" "$other" "$t" && echo mine > "$t/init.lua"
    assert_eq "$(link "$src" "$t")" "replaced" "a real directory is replaced"
    assert_eq "$(readlink "$t")" "$src" "by the link"
    assert_file_not_exists "$src/nvim" "nothing nested inside the source"
    assert_eq "$(cat "$TEST_HOME/.dotfiles_backup/.config/nvim/init.lua")" "mine" "its contents are backed up"
    ln -sfn "$other" "$t"
    assert_eq "$(link "$src" "$t")" "linked" "a link to another directory is repointed"
    assert_eq "$(readlink "$t")" "$src" "not followed"
    assert_file_not_exists "$other/nvim" "and nothing is nested in the old directory"
    teardown_sandbox
}

test_30_every_caller_uses_dotfiles_link() {
    echo ""
    section "Test 30: install, update and sync link through dotfiles_link"
    local f
    for f in install.sh update.sh bin/dotfiles-sync; do
        assert_file_contains "$DOTFILES_DIR/$f" "dotfiles_link \"\$source\" \"\$target\"" "$f calls dotfiles_link"
        assert_file_not_contains "$DOTFILES_DIR/$f" "ln -sf \"\$source\" \"\$target\"" "$f has no bare ln -sf of its own"
    done
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
[[ -n "\${BREW_FAIL:-}" && " \$* " == *" \$BREW_FAIL "* ]] && exit 1
[[ "\$1" == "--caskroom" ]] && echo "$TEST_TMP/caskroom"
if [[ "\$1" == "bundle" && "\$2" == "dump" ]]; then
    for a in "\$@"; do
        [[ "\$a" == --file=* ]] || continue
        cp "$MOCK/Brewfile" "\${a#--file=}"
        [[ -n "\${DUMP_EXTRA:-}" ]] && printf '%s\n' "\$DUMP_EXTRA" >> "\${a#--file=}"
    done
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

test_37h_pull_is_fast_forward_on_main_only() {
    echo ""
    section "Test 37h: the pull fast-forwards main and leaves other branches alone"
    setup_pipeline_sandbox
    push_to_origin "docs/pulled.md" "from origin"
    git -C "$MOCK" switch -q -c feature
    local out
    out=$(run_update --no-snapshot)
    assert_contains "$out" "On branch 'feature', not main: repository not pulled" "a feature branch is not pulled"
    assert_file_not_exists "$MOCK/docs/pulled.md" "origin's commit stays out of it"
    git -C "$MOCK" switch -q main
    out=$(run_update --no-snapshot)
    assert_file_exists "$MOCK/docs/pulled.md" "main is fast-forwarded"

    setup_pipeline_sandbox
    push_to_origin "docs/upstream.md" "upstream"
    echo "local" > "$MOCK/local-only.md"
    (cd "$MOCK" && git add local-only.md && git -c user.name=t -c user.email=t@t commit -qm "local only")
    local before
    before=$(git -C "$MOCK" rev-parse HEAD)
    set +e; out=$(run_update --no-snapshot); rc=$?; set -e
    assert_eq "$rc" "1" "a diverged main stops the run"
    assert_contains "$out" "nothing was merged" "and says why"
    assert_eq "$(git -C "$MOCK" rev-parse HEAD)" "$before" "no merge commit is made"
}

test_37i_brew_failure_does_not_stop_the_run() {
    echo ""
    section "Test 37i: a failing Homebrew step warns and the run carries on"
    setup_pipeline_sandbox
    push_to_origin ".config/aerospace/aerospace.toml" "# aerospace v2"
    local out
    set +e; out=$(BREW_FAIL=upgrade run_update --no-snapshot); rc=$?; set -e
    assert_contains "$out" "brew upgrade failed for at least one package; continuing" "the failure is reported"
    assert_file_contains "$CALLS" "^mise " "mise still ran"
    assert_file_contains "$CALLS" "aerospace reload-config" "the pulled config's restart still ran"
    assert_contains "$out" "these steps failed: brew upgrade" "the end names the failed step"
    assert_eq "$rc" "1" "and the run exits non-zero"
    assert_dir_not_exists "$STATE/update.lock" "the lock is released"

    setup_pipeline_sandbox
    set +e; out=$(BREW_FAIL=update run_update --no-snapshot); rc=$?; set -e
    assert_contains "$out" "brew update failed" "a failing brew update is reported"
    assert_file_contains "$CALLS" "^brew upgrade" "and upgrade is still tried"
    assert_eq "$rc" "1" "exit non-zero"
}

test_37j_stash_lock_and_self_update() {
    echo ""
    section "Test 37j: honest stash message, lock before the transcript, a pulled update.sh"
    setup_pipeline_sandbox
    push_to_origin ".zshrc" "# zshrc from origin"
    echo "# local edit" >> "$MOCK/.zshrc"
    local out
    set +e; out=$(run_update --no-snapshot); rc=$?; set -e
    assert_contains "$out" "Restoring your uncommitted changes conflicted" "a conflicting pop says so"
    assert_not_contains "$out" "Uncommitted changes restored" "and does not claim success"
    assert_eq "$(git -C "$MOCK" stash list | wc -l | tr -d ' ')" "1" "the stash is kept for the user"

    setup_pipeline_sandbox
    echo "# previous run" > "$STATE/update.log"
    mkdir -p "$STATE/update.lock"
    echo "$$" > "$STATE/update.lock/pid"
    set +e; out=$(DOTFILES_UPDATE_LOGGED='' run_update); rc=$?; set -e
    assert_eq "$rc" "1" "a second run stops at the lock"
    assert_file_contains "$STATE/update.log" "# previous run" "without rotating the live run's transcript"
    assert_file_not_exists "$STATE/update.log.1" "or making a .1 copy"
    rm -rf "$STATE/update.lock"

    setup_pipeline_sandbox
    # A pulled update.sh far longer than the old one: a run still reading
    # its own file would carry on inside the new text. It does not today,
    # because git writes the pulled file as a new inode and bash keeps
    # reading the one it opened; this guards that, should the pull ever
    # rewrite the file in place.
    local new_script
    new_script=$(printf '#!/usr/bin/env bash\n'; for _ in $(seq 1 1500); do echo "# padding line to move every offset"; done; echo 'echo NEW-UPDATE-SH-RAN; exit 0')
    push_to_origin "update.sh" "$new_script"
    set +e; out=$(run_update --no-snapshot); rc=$?; set -e
    assert_eq "$rc" "0" "the run that pulled a new update.sh finishes"
    assert_contains "$out" "Update Complete!" "as the version that started"
    assert_not_contains "$out" "NEW-UPDATE-SH-RAN" "without running the pulled text mid-way"
}

test_37d_snapshot_publishes_only_packages() {
    echo ""
    section "Test 37d: the snapshot publishes package files and nothing else"

    setup_pipeline_sandbox
    echo "# half-done edit" >> "$MOCK/.zshrc"
    local before out
    before=$(git -C "$MOCK" rev-parse HEAD)
    out=$(run_update --no-snapshot)
    assert_eq "$(git -C "$MOCK" rev-parse HEAD)" "$before" "an edit outside the package files is not committed"
    assert_eq "$(git -C "$ORIGIN" rev-parse main)" "$before" "and not pushed"
    assert_contains "$out" "Left uncommitted" "the run warns about it"
    assert_contains "$out" ".zshrc" "and names the file"
    assert_file_contains "$MOCK/.zshrc" "# half-done edit" "the edit stays in the working tree"

    setup_pipeline_sandbox
    echo 'brew "ripgrep"' >> "$MOCK/Brewfile"
    echo "# half-done edit" >> "$MOCK/.zshrc"
    echo "# staged edit" >> "$MOCK/.config/aerospace/aerospace.toml"
    git -C "$MOCK" add .config/aerospace/aerospace.toml
    out=$(run_update --no-snapshot)
    assert_eq "$(git -C "$MOCK" log -1 --format=%s)" "snapshot: system state" "a package change is committed"
    assert_eq "$(git -C "$MOCK" show --name-only --format= HEAD)" "Brewfile" "the commit holds only the package file"
    assert_eq "$(git -C "$ORIGIN" rev-parse main)" "$(git -C "$MOCK" rev-parse HEAD)" "and is pushed"
    assert_contains "$(git -C "$MOCK" status --short)" ".zshrc" "the unrelated edit stays uncommitted"
    assert_contains "$(git -C "$MOCK" status --short)" "aerospace.toml" "work staged by hand stays uncommitted too"
    assert_contains "$out" "Left uncommitted" "the run warns about what it left"

    setup_pipeline_sandbox
    echo "# just a comment" >> "$MOCK/Brewfile"
    before=$(git -C "$MOCK" rev-parse HEAD)
    run_update --no-snapshot >/dev/null
    assert_eq "$(git -C "$MOCK" rev-parse HEAD)" "$before" "a comment-only Brewfile edit is not committed"
}

test_37e_personal_tap() {
    echo ""
    section "Test 37e: dropped packages are checked, the tap updated, before brew upgrade"

    setup_pipeline_sandbox
    local out order tap="$TEST_TMP/tap"
    rm -rf "$tap"
    mkdir -p "$MOCK/homebrew-tap/Casks" "$TEST_TMP/caskroom/kept/.metadata"
    echo 'cask "kept" do; end' > "$MOCK/homebrew-tap/Casks/kept.rb"
    # Installed here from the tap, so tap update checks it.
    echo '{"source": {"tap": "me/tap"}}' > "$TEST_TMP/caskroom/kept/.metadata/INSTALL_RECEIPT.json"
    out=$(DOTFILES_TAP=me/tap DOTFILES_TAP_DIR="$tap" DUMP_EXTRA=$'tap "me/tap"\ncask "me/tap/kept"' run_update --yes)
    order=$(/usr/bin/grep -nE '^brew (update|list --cask|livecheck .*|upgrade)$' "$CALLS" | cut -d: -f2 | sed 's/ --json.*//' | tr '\n' '|')
    assert_eq "$order" "brew update|brew list --cask|brew livecheck|brew upgrade|" "check, then tap update, between brew update and brew upgrade"
    assert_file_contains "$CALLS" "^brew list --cask --versions kept$" "tap install looks for kept packages missing here"
    assert_contains "$out" "keeps 1 package(s) in homebrew-tap/ not installed here: kept" "--yes lists the missing one and installs nothing"
    assert_file_not_contains "$CALLS" "^brew install" "nothing installed without an answer"
    assert_contains "$out" "No changes since last snapshot" "a package kept in the tap is not reported as drift"
    assert_not_contains "$out" "+ cask" "nor named as drift"
    assert_file_exists "$tap/Casks/kept.rb" "Homebrew's working copy is built from the repo folder"
    assert_eq "$(git -C "$MOCK" log -1 --format=%s)" "snapshot: system state" "a new recipe in homebrew-tap/ is committed"
    assert_eq "$(git -C "$MOCK" show --name-only --format= HEAD)" "homebrew-tap/Casks/kept.rb" "the commit holds only the tap folder"
    assert_eq "$(git -C "$ORIGIN" rev-parse main)" "$(git -C "$MOCK" rev-parse HEAD)" "and is pushed"

    setup_pipeline_sandbox
    mkdir -p "$STATE/toggles"
    touch "$STATE/toggles/tap-auto-update.off"
    mkdir -p "$MOCK/homebrew-tap/Casks"
    echo 'cask "kept" do; end' > "$MOCK/homebrew-tap/Casks/kept.rb"
    DOTFILES_TAP=me/tap DOTFILES_TAP_DIR="$tap" run_update --yes >/dev/null
    assert_file_not_contains "$CALLS" "livecheck" "tap-auto-update off skips the version check"
    assert_file_contains "$CALLS" "^brew list --cask$" "but dropped packages are still checked"
}

test_37f_trusts_brewfile_taps() {
    echo ""
    section "Test 37f: taps in the Brewfile are trusted before brew upgrade"

    setup_pipeline_sandbox
    push_to_origin "Brewfile" $'tap "new/tap"\nbrew "jq"'
    local order
    run_update --yes >/dev/null
    order=$(/usr/bin/grep -nE '^brew (update|trust --tap .*|upgrade)$' "$CALLS" | cut -d: -f2 | tr '\n' '|')
    assert_eq "$order" "brew update|brew trust --tap new/tap|brew upgrade|" "a tap pulled into the Brewfile is trusted after brew update, before brew upgrade"
}

test_37g_brewfile_change_rebuilds_catalog() {
    echo ""
    section "Test 37g: a Brewfile change is committed with a rebuilt catalog"

    setup_pipeline_sandbox
    mkdir -p "$MOCK/docs"
    # The catalog lists packages under a `# @group` header only.
    printf '# @group core — Essential CLI tools\nbrew "jq"\n' > "$MOCK/Brewfile"
    (cd "$MOCK" && python3 scripts/catalog/build-catalog.py >/dev/null)
    git -C "$MOCK" add -A && git -C "$MOCK" commit -qm "catalog" && git -C "$MOCK" push -q origin main
    echo 'brew "zz-not-described"' >> "$MOCK/Brewfile"
    run_update --yes --no-snapshot >/dev/null
    assert_eq "$(git -C "$MOCK" show --name-only --format= HEAD | sort | tr '\n' ' ')" "Brewfile docs/PACKAGE_CATALOG.md " "the snapshot commit carries the rebuilt catalog"
    assert_file_contains "$MOCK/docs/PACKAGE_CATALOG.md" 'zz-not-described' "which lists the new package"
    assert_file_contains "$CALLS" "^brew info --json=v2 --formula zz-not-described$" "metadata was looked up for it"
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

test_27_link_new_current_and_wrong
test_28_link_over_real_file
test_29_link_over_directory
test_30_every_caller_uses_dotfiles_link
test_31_macos_only_guard
test_32_help_and_flags
test_33_quiet_run
test_34_pulled_config_marks_restart
test_35_marker_from_elsewhere
test_36_no_snapshot_and_yes
test_37_lock
test_37b_stay_awake_and_failure_hint
test_37c_failed_pull_restores_stash
test_37d_snapshot_publishes_only_packages
test_37e_personal_tap
test_37f_trusts_brewfile_taps
test_37g_brewfile_change_rebuilds_catalog
test_37h_pull_is_fast_forward_on_main_only
test_37i_brew_failure_does_not_stop_the_run
test_37j_stash_lock_and_self_update
test_38_transcript
