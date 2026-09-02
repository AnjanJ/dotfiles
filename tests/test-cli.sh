#!/usr/bin/env bash

# ============================================
# CLI ROUTER TEST SUITE
# ============================================
# Tests bin/dotfiles: filename routing (longest prefix), the
# non-prefixed work-*/repos-clone routes, --help interception that
# never executes the target, the required-args guard, unknown-command
# exit code and suggestion, metadata listings, and `commands --check`.
#
# Uses a sandbox bin/ with fake commands that record their invocation,
# so nothing real runs. The real bin/ is also checked at the end.
# Usage: bash tests/test-cli.sh
# ============================================

set -euo pipefail

REAL_DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

PASS=0
FAIL=0
FAILURES=()

pass() { PASS=$((PASS + 1)); echo -e "  \033[0;32m✓\033[0m $1"; }
fail() { FAIL=$((FAIL + 1)); FAILURES+=("$1"); echo -e "  \033[0;31m✗\033[0m $1"; }

assert_eq() {
    local actual="$1" expected="$2" label="$3"
    if [[ "$actual" == "$expected" ]]; then pass "$label"; else fail "$label (expected '$expected', got '$actual')"; fi
}
assert_contains() {
    local text="$1" pattern="$2" label="$3"
    if echo "$text" | /usr/bin/grep -qF -- "$pattern"; then pass "$label"; else fail "$label ('$pattern' not found)"; fi
}

# ── Sandbox ───────────────────────────────────

MOCK=$(mktemp -d)
trap 'rm -rf "$MOCK"' EXIT
mkdir -p "$MOCK/bin"
cp "$REAL_DOTFILES_DIR/bin/dotfiles" "$MOCK/bin/dotfiles"
LOG="$MOCK/calls.log"

# fake_command <filename> <summary> [args-meta] [hidden]
fake_command() {
    local name="$1" summary="$2" args="${3:-}" hidden="${4:-}"
    {
        echo '#!/usr/bin/env bash'
        echo "# dotfiles:summary=$summary"
        [[ -n "$args" ]] && echo "# dotfiles:args=$args"
        [[ -n "$hidden" ]] && echo "# dotfiles:hidden=true"
        echo "echo \"$name \$*\" >> \"$LOG\""
        echo 'echo "ran '"$name"'"'
    } > "$MOCK/bin/$name"
    chmod +x "$MOCK/bin/$name"
}

fake_command dotfiles-backup "Snapshot state" "[--list] [--restore <name>]"
fake_command dotfiles-add-theme "Scaffold a theme" "<name>"
fake_command dotfiles-add "Generic add" ""
fake_command dotfiles-theme "Switch theme" "<name>"
fake_command dotfiles-secret "Hidden plumbing" "" hidden
fake_command work-setup "Configure work identity" ""
fake_command repos-clone "Clone repos" "[--all]"
# A helper with no summary must not be listed or routable
printf '#!/usr/bin/env bash\necho helper\n' > "$MOCK/bin/_helpers"; chmod +x "$MOCK/bin/_helpers"
printf '#!/usr/bin/env bash\necho nometa\n' > "$MOCK/bin/nometa"; chmod +x "$MOCK/bin/nometa"

D="$MOCK/bin/dotfiles"

echo ""
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║   CLI Router Tests                                        ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""

echo "Test 1: Filename routing"
: > "$LOG"
out=$("$D" backup --list 2>&1)
assert_eq "$out" "ran dotfiles-backup" "dotfiles backup runs bin/dotfiles-backup"
assert_eq "$(tail -1 "$LOG")" "dotfiles-backup --list" "leftover args passed through"

: > "$LOG"
"$D" add theme dracula >/dev/null
assert_eq "$(tail -1 "$LOG")" "dotfiles-add-theme dracula" "longest prefix: 'add theme' → dotfiles-add-theme"
: > "$LOG"
"$D" add-theme dracula >/dev/null
assert_eq "$(tail -1 "$LOG")" "dotfiles-add-theme dracula" "hyphenated route works too"
: > "$LOG"
"$D" add widget >/dev/null
assert_eq "$(tail -1 "$LOG")" "dotfiles-add widget" "shorter prefix wins when longer does not exist"

: > "$LOG"
"$D" work setup >/dev/null
assert_eq "$(tail -1 "$LOG")" "work-setup " "non-prefixed scripts route: work setup → work-setup"
: > "$LOG"
"$D" repos clone --all >/dev/null
assert_eq "$(tail -1 "$LOG")" "repos-clone --all" "repos clone → repos-clone with args"
echo ""

echo "Test 2: --help never executes the target"
: > "$LOG"
out=$("$D" backup --help)
assert_contains "$out" "Usage: dotfiles backup [--list] [--restore <name>]" "--help prints usage from metadata"
assert_contains "$out" "Snapshot state" "--help prints the summary"
assert_eq "$(wc -l < "$LOG" | tr -d ' ')" "0" "target not executed for --help"
: > "$LOG"
"$D" backup --restore x --help >/dev/null
assert_eq "$(wc -l < "$LOG" | tr -d ' ')" "0" "--help anywhere in the arguments is intercepted"
: > "$LOG"
"$D" backup -- --help >/dev/null
assert_eq "$(tail -1 "$LOG")" "dotfiles-backup -- --help" "-- ends the scan; --help after it is forwarded"
echo ""

echo "Test 3: Required-args guard"
: > "$LOG"
set +e; out=$("$D" theme 2>&1); rc=$?; set -e
assert_eq "$rc" "1" "bare command with required <name> exits 1"
assert_contains "$out" "Usage: dotfiles theme <name>" "bare command prints usage"
assert_eq "$(wc -l < "$LOG" | tr -d ' ')" "0" "bare command not executed"
: > "$LOG"
"$D" backup >/dev/null
assert_eq "$(tail -1 "$LOG")" "dotfiles-backup " "command with only optional args runs bare"
echo ""

echo "Test 4: Unknown commands"
set +e; out=$("$D" nope 2>&1); rc=$?; set -e
assert_eq "$rc" "127" "unknown command exits 127"
assert_contains "$out" "unknown command 'nope'" "unknown command named"
set +e; out=$("$D" bac 2>&1); rc=$?; set -e
assert_contains "$out" "Did you mean: dotfiles backup" "prefix suggestion offered"
set +e; out=$("$D" nometa 2>&1); rc=$?; set -e
assert_eq "$rc" "127" "script without metadata is not routable"
set +e; "$D" _helpers >/dev/null 2>&1; rc=$?; set -e
assert_eq "$rc" "127" "underscore helpers are not routable"
echo ""

echo "Test 5: Listings"
out=$("$D")
assert_contains "$out" "add theme" "bare dotfiles lists routes"
assert_contains "$out" "Snapshot state" "listing shows summaries"
assert_contains "$out" "work setup" "listing includes non-prefixed routes"
if echo "$out" | /usr/bin/grep -q "secret"; then fail "hidden command shown in listing"; else pass "hidden command not listed"; fi
out=$("$D" commands --all)
assert_contains "$out" "secret" "--all includes hidden commands"
out=$("$D" commands --plain)
assert_contains "$out" "$(printf 'add theme\tScaffold a theme\t<name>')" "--plain is route<TAB>summary<TAB>args"
if command -v python3 &>/dev/null; then
    count=$("$D" commands --json | python3 -c 'import json,sys; d=json.load(sys.stdin); print(len(d))')
    assert_eq "$count" "6" "--json is valid JSON with one entry per visible command"
    route=$("$D" commands --json | python3 -c 'import json,sys; d=json.load(sys.stdin); print([x["binary"] for x in d if x["route"]=="add theme"][0])')
    assert_eq "$route" "dotfiles-add-theme" "--json carries the binary name"
fi
echo ""

echo "Test 6: commands --check"
out=$("$D" commands --check)
assert_contains "$out" "carry metadata" "--check passes when every dotfiles-* has a summary"
printf '#!/usr/bin/env bash\necho x\n' > "$MOCK/bin/dotfiles-bare"; chmod +x "$MOCK/bin/dotfiles-bare"
set +e; out=$("$D" commands --check 2>&1); rc=$?; set -e
assert_eq "$rc" "1" "--check fails for a dotfiles-* without a summary"
assert_contains "$out" "dotfiles-bare" "--check names the offender"
rm "$MOCK/bin/dotfiles-bare"
echo ""

echo "Test 7: Built-ins and the real repo"
assert_eq "$("$D" dir)" "$(cd "$MOCK" && pwd -P)" "dir prints the repo root"
out=$("$REAL_DOTFILES_DIR/bin/dotfiles" commands --check)
assert_contains "$out" "carry metadata" "real bin/ passes --check"
out=$(/bin/bash "$REAL_DOTFILES_DIR/bin/dotfiles" commands --plain)
assert_contains "$out" "theme" "router runs under /bin/bash 3.2"
echo ""

echo "════════════════════════════════════════════════════════════"
echo -e "  \033[0;32mPassed: $PASS\033[0m  |  \033[0;31mFailed: $FAIL\033[0m"
echo "════════════════════════════════════════════════════════════"
if [[ ${#FAILURES[@]} -gt 0 ]]; then
    echo ""
    for f in "${FAILURES[@]}"; do echo -e "    \033[0;31m✗\033[0m $f"; done
fi
echo ""
[[ $FAIL -eq 0 ]]
