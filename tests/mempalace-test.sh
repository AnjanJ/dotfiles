#!/usr/bin/env bash
# doc: MemPalace — `dotfiles mempalace setup`: installs the uv tool when missing, registers the MCP server with Claude Code once, writes and loads the shared-hub LaunchAgent and leaves a healthy hub alone, --no-hub and --remove-hub, a hub that is slow to start, `dotfiles restart mempalace-hub`, bash 3.2

# Every external command is a stub that records its arguments; HOME, the
# LaunchAgents folder and ~/.claude.json are temporary. Nothing real is
# installed, registered or loaded.
# Usage: tests/run mempalace

set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

SETUP="$ROOT/bin/dotfiles-mempalace-setup"
RESTART="$ROOT/bin/dotfiles-restart"
STUB="$TEST_TMP/stub"
CALLS="$TEST_TMP/calls"
mkdir -p "$STUB"
: > "$CALLS"
export DOTFILES_LAUNCH_AGENTS_DIR="$TEST_TMP/LaunchAgents"
export DOTFILES_STATE_DIR="$TEST_TMP/state"
export DOTFILES_CLAUDE_JSON="$TEST_TMP/claude.json"
export DOTFILES_MEMPALACE_WAIT=2
PLIST="$DOTFILES_LAUNCH_AGENTS_DIR/com.dotfiles.mempalace-hub.plist"

# uv installs a stub mempalace into ~/.local/bin, where the real one goes.
cat > "$STUB/uv" <<EOF
#!/bin/bash
echo "uv \$*" >> "$CALLS"
if [[ "\$1 \$2 \$3" == "tool install mempalace" ]]; then
    mkdir -p "\$HOME/.local/bin"
    printf '#!/bin/bash\necho "MemPalace 9.9.9"\n' > "\$HOME/.local/bin/mempalace"
    chmod +x "\$HOME/.local/bin/mempalace"
fi
EOF
cat > "$STUB/claude" <<EOF
#!/bin/bash
echo "claude \$*" >> "$CALLS"
EOF
# launchctl: bootout fails when nothing is loaded, like the real one;
# print succeeds once bootstrap has run.
cat > "$STUB/launchctl" <<EOF
#!/bin/bash
echo "launchctl \$*" >> "$CALLS"
case "\$1" in
    bootstrap) touch "$TEST_TMP/loaded" ;;
    bootout) [[ -f "$TEST_TMP/loaded" ]] || exit 3; rm -f "$TEST_TMP/loaded" ;;
    print) [[ -f "$TEST_TMP/loaded" ]] || exit 113 ;;
esac
exit 0
EOF
# The hub answers /healthz once "hub-up" exists.
cat > "$STUB/curl" <<EOF
#!/bin/bash
[[ -f "$TEST_TMP/hub-up" ]]
EOF
chmod +x "$STUB"/*
# The machine's own ~/.local/bin (the real mempalace) must not be found.
PATH=$(printf '%s' "$PATH" | tr ':' '\n' | /usr/bin/grep -v '/\.local/bin$' | paste -sd: -)
export PATH="$STUB:$PATH"
command -v mempalace >/dev/null 2>&1 && fail "the test PATH still finds a real mempalace"
# Cases that remove a stub run with PATH="$STUB:/usr/bin:/bin", so the
# real uv and claude in Homebrew's bin can never run in their place.

run() { bash "$SETUP" "$@" 2>&1; }
called() { /usr/bin/grep -c -F -- "$1" "$CALLS" || true; }

section "a fresh machine"
touch "$TEST_TMP/hub-up"
out=$(run)
assert_eq "$(called "uv tool install mempalace")" "1" "MemPalace is installed with uv when missing"
assert_contains "$out" "MemPalace 9.9.9" "and its version is reported"
assert_eq "$(stat -f %Lp "$HOME/.mempalace")" "700" "~/.mempalace is private"
assert_eq "$(called "claude mcp add --scope user mempalace -- mempalace-mcp")" "1" "the MCP server is registered with Claude Code, user scope"
assert_file_exists "$PLIST" "the hub's LaunchAgent is written"
plutil -lint "$PLIST" >/dev/null || fail "the LaunchAgent is a valid plist"
pass "the LaunchAgent is a valid plist"
assert_eq "$(plutil -extract ProgramArguments.0 raw -o - "$PLIST")" "$HOME/.local/bin/mempalace" "it runs the installed mempalace"
assert_eq "$(plutil -extract ProgramArguments.1 raw -o - "$PLIST")" "serve" "as the hub (serve)"
assert_eq "$(plutil -extract RunAtLoad raw -o - "$PLIST")" "true" "from login"
assert_eq "$(plutil -extract KeepAlive raw -o - "$PLIST")" "true" "and restarted if it exits"
assert_eq "$(plutil -extract StandardErrorPath raw -o - "$PLIST")" "$DOTFILES_STATE_DIR/mempalace-hub.log" "logging into the private state dir"
assert_eq "$(stat -f %Lp "$DOTFILES_STATE_DIR")" "700" "which is 700"
assert_eq "$(called "launchctl bootstrap gui/$(id -u) $PLIST")" "1" "the agent is loaded"
assert_contains "$out" "shared by every Claude Code session" "and the hub is reported running"

section "a second run changes nothing"
printf '{"mcpServers":{"mempalace":{"command":"mempalace-mcp"}}}\n' > "$DOTFILES_CLAUDE_JSON"
: > "$CALLS"
out=$(run)
assert_eq "$(called "uv tool install")" "0" "an installed MemPalace is not reinstalled"
assert_eq "$(called "claude mcp add")" "0" "an existing registration is kept"
assert_eq "$(called "launchctl")" "0" "a healthy hub with an unchanged agent is left running"
assert_contains "$out" "running on 127.0.0.1:8765" "and reported"

section "a changed agent or a hub that is down is reloaded"
: > "$CALLS"
rm -f "$TEST_TMP/hub-up"
out=$(DOTFILES_MEMPALACE_WAIT=1 run)
assert_eq "$(called "launchctl bootout")" "1" "the old agent is unloaded"
assert_eq "$(called "launchctl bootstrap")" "1" "and loaded again"
assert_contains "$out" "did not answer within 1s" "a hub that does not come up is a warning"
assert_contains "$out" "launchd keeps retrying" "with the likely reason"
rc=0; DOTFILES_MEMPALACE_WAIT=1 bash "$SETUP" >/dev/null 2>&1 || rc=$?
assert_eq "$rc" "0" "not a failure, so install.sh carries on"
touch "$TEST_TMP/hub-up"

section "options"
rm -f "$PLIST"
: > "$CALLS"
out=$(run --no-hub)
assert_file_not_exists "$PLIST" "--no-hub writes no agent"
assert_eq "$(called "launchctl")" "0" "and loads nothing"
run >/dev/null
assert_file_exists "$PLIST" "(agent back for the next check)"
: > "$CALLS"
out=$(run --remove-hub)
assert_file_not_exists "$PLIST" "--remove-hub deletes the agent"
assert_eq "$(called "launchctl bootout")" "1" "and stops the hub"
assert_eq "$(called "uv")$(called "claude")" "00" "and touches nothing else"
rc=0; run --bogus >/dev/null || rc=$?
assert_eq "$rc" "1" "an unknown option is refused"

section "missing tools"
rm -f "$HOME/.local/bin/mempalace" "$STUB/uv"
# Only the stubs and the system folders: Homebrew's real uv must not run.
rc=0; out=$(PATH="$STUB:/usr/bin:/bin" run) || rc=$?
assert_eq "$rc" "1" "no MemPalace and no uv stops the setup"
assert_contains "$out" "brew install uv" "and says how to get uv"
cat > "$STUB/uv" <<EOF
#!/bin/bash
echo "uv \$*" >> "$CALLS"
mkdir -p "\$HOME/.local/bin"
printf '#!/bin/bash\necho "MemPalace 9.9.9"\n' > "\$HOME/.local/bin/mempalace"
chmod +x "\$HOME/.local/bin/mempalace"
EOF
chmod +x "$STUB/uv"
rm -f "$DOTFILES_CLAUDE_JSON" "$STUB/claude"
out=$(PATH="$STUB:/usr/bin:/bin" run --no-hub)
assert_contains "$out" "claude mcp add --scope user mempalace -- mempalace-mcp" "without Claude Code, the registration command is printed for later"

section "dotfiles restart mempalace-hub"
: > "$CALLS"
rm -f "$TEST_TMP/loaded"
out=$(bash "$RESTART" mempalace-hub 2>&1)
assert_contains "$out" "not installed" "nothing to restart when the agent is not loaded"
touch "$TEST_TMP/loaded"
out=$(bash "$RESTART" mempalace-hub 2>&1)
assert_eq "$(called "launchctl kickstart -k gui/$(id -u)/com.dotfiles.mempalace-hub")" "1" "a loaded hub is restarted with kickstart -k"
assert_contains "$out" "mempalace-hub: restarted" "and reported"

section "bash 3.2"
rc=0; /bin/bash "$SETUP" --no-hub >/dev/null 2>&1 || rc=$?
assert_eq "$rc" "0" "/bin/bash runs the setup"
assert_eq "$(/bin/bash -n "$SETUP" && echo ok)" "ok" "and parses it"
