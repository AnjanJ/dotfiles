#!/usr/bin/env bash
# doc: AeroSpace — follow-auth-prompts.sh under `/bin/bash` 3.2 against a fake `aerospace`: an open Touch ID / password prompt moves to the workspace switched to and is floated, other windows and a prompt already there are left alone, the workspace comes from the argument or `$AEROSPACE_FOCUSED_WORKSPACE`, and a missing workspace, a stopped AeroSpace or a failed move never errors; aerospace.toml runs it on every workspace change

# ============================================
# AEROSPACE TEST SUITE
# ============================================
# Runs the AeroSpace helper scripts against a fake `aerospace` that serves a
# window list from a file and logs every other call, so no real window moves.
# Usage: tests/run aerospace   (or /opt/homebrew/bin/bash tests/aerospace-test.sh)
# ============================================
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

CONFIG="$ROOT/.config/aerospace/aerospace.toml"
FOLLOW="$ROOT/.config/aerospace/scripts/follow-auth-prompts.sh"

FAKEBIN="$HOME/fakebin"
mkdir -p "$FAKEBIN"
export FAKE_AEROSPACE_LOG="$HOME/aerospace.log"
export FAKE_WINDOWS="$HOME/windows.txt"

# list-windows prints $FAKE_WINDOWS (or fails with FAKE_LIST_FAIL set);
# every other call is logged. A move of window $FAKE_MOVE_FAIL_ID fails.
cat > "$FAKEBIN/aerospace" <<'F'
#!/usr/bin/env bash
case "$1" in
    list-windows)
        [[ -z "${FAKE_LIST_FAIL:-}" ]] || exit 1
        cat "$FAKE_WINDOWS"
        ;;
    *)
        printf '%s\n' "$*" >> "$FAKE_AEROSPACE_LOG"
        if [[ "$1" == "move-node-to-workspace" && " $* " == *" --window-id ${FAKE_MOVE_FAIL_ID:-none} "* ]]; then
            exit 1
        fi
        ;;
esac
F
chmod +x "$FAKEBIN/aerospace"
export PATH="$FAKEBIN:$PATH"

PROMPT="com.apple.LocalAuthentication.UIAgent"

# run_follow [args...]: run the script under /bin/bash 3.2 with a fresh log;
# sets rc.
run_follow() {
    : > "$FAKE_AEROSPACE_LOG"
    set +e
    /bin/bash "$FOLLOW" "$@" >/dev/null 2>&1
    rc=$?
    set -e
}

section "follow-auth-prompts.sh"

cat > "$FAKE_WINDOWS" <<EOF
59|1|dev.warp.Warp-Stable
148|6|io.ente.auth.mac
152|6|$PROMPT
EOF
run_follow 1
assert_eq "$rc" "0" "exits 0 after moving a prompt"
assert_file_contains "$FAKE_AEROSPACE_LOG" "^move-node-to-workspace --window-id 152 1$" "the prompt moves to the workspace switched to"
assert_file_contains "$FAKE_AEROSPACE_LOG" "^layout --window-id 152 floating$" "the moved prompt is floated"
assert_count "$FAKE_AEROSPACE_LOG" "." "2" "nothing else is touched (Ente Auth stays on 6, Warp is not moved)"

cat > "$FAKE_WINDOWS" <<EOF
59|1|dev.warp.Warp-Stable
152|1|$PROMPT
EOF
run_follow 1
assert_eq "$rc" "0" "exits 0 when the prompt is already there"
assert_count "$FAKE_AEROSPACE_LOG" "." "0" "a prompt already on the workspace is left alone"

cat > "$FAKE_WINDOWS" <<EOF
152|6|$PROMPT
160|3|$PROMPT
EOF
: > "$FAKE_AEROSPACE_LOG"
AEROSPACE_FOCUSED_WORKSPACE=4 /bin/bash "$FOLLOW" >/dev/null 2>&1
assert_file_contains "$FAKE_AEROSPACE_LOG" "^move-node-to-workspace --window-id 152 4$" "without an argument the workspace comes from AEROSPACE_FOCUSED_WORKSPACE"
assert_file_contains "$FAKE_AEROSPACE_LOG" "^move-node-to-workspace --window-id 160 4$" "every open prompt is moved"

run_follow
assert_eq "$rc" "0" "no workspace at all exits 0"
assert_count "$FAKE_AEROSPACE_LOG" "." "0" "no workspace at all touches nothing"

FAKE_LIST_FAIL=1 run_follow 2
assert_eq "$rc" "0" "a stopped AeroSpace (list-windows fails) exits 0"
assert_count "$FAKE_AEROSPACE_LOG" "." "0" "a stopped AeroSpace touches nothing"

FAKE_MOVE_FAIL_ID=152 run_follow 2
assert_eq "$rc" "0" "a failed move exits 0"
assert_file_not_contains "$FAKE_AEROSPACE_LOG" "^layout --window-id 152" "a prompt that failed to move is not re-laid out"
assert_file_contains "$FAKE_AEROSPACE_LOG" "^move-node-to-workspace --window-id 160 2$" "a failed move does not stop the next prompt"

section "aerospace.toml"

hook=$(sed -n '/^exec-on-workspace-change/,/^]/p' "$CONFIG")
assert_contains "$hook" "~/.config/aerospace/scripts/follow-auth-prompts.sh" "exec-on-workspace-change runs follow-auth-prompts.sh"
assert_contains "$hook" "sketchybar --trigger aerospace_workspace_change" "exec-on-workspace-change still notifies sketchybar"
assert_succeeds "follow-auth-prompts.sh is executable" test -x "$FOLLOW"
