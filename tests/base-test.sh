#!/usr/bin/env bash
# ============================================
# TEST CONTRACT — shared by every tests/*-test.sh
# ============================================
# Source this at the top of a suite, after `set -euo pipefail`:
#
#   source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"
#
# What it gives a suite:
#   ROOT        the repo checkout, so files are "$ROOT/bin/..." and never
#               depend on the caller's cwd or an installed dotfiles
#   HOME        a fresh temporary directory. Nothing a suite does can
#               reach the developer's real configs.
#   TMPDIR      also under the temporary directory, so every `mktemp`
#               inside a suite is removed on exit without a trap per file
#   pass/fail   TAP lines: `ok - desc` / `not ok - desc`. fail EXITS the
#               file. There is no counting-and-continuing: later
#               assertions would run against state the failure already
#               invalidated. tests/run compensates by continuing past a
#               failing file and listing the failures at the end.
#
# Bash 3.2 compatible on purpose: tests/e2e/install-e2e.sh sources this
# under /bin/bash to exercise the curl-bootstrap path.
# ============================================

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    echo "source tests/base-test.sh from a suite; do not run it directly" >&2
    exit 1
fi

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export ROOT
_TEST_FILE="${BASH_SOURCE[1]##*/}"

# ── Sandbox ───────────────────────────────────

# macOS sets TMPDIR with a trailing slash; strip it so paths built on
# TEST_TMP compare equal to what scripts compute via `cd && pwd`.
_test_tmp_parent="${TMPDIR:-/tmp}"
TEST_TMP="$(mktemp -d "${_test_tmp_parent%/}/dotfiles-test.XXXXXX")"
export TEST_TMP
export TMPDIR="$TEST_TMP"
export HOME="$TEST_TMP/home"
# Applying a theme in a suite must never flip the live macOS appearance
# or desktop picture; the theme suites unset these where they stub
# dark-mode/desktoppr/osascript.
export DOTFILES_NO_APPEARANCE=1
export DOTFILES_NO_BACKGROUND=1
mkdir -p "$HOME"

_TEST_PASSED=0
_TEST_FAILED=false

# A suite that dies through `set -e` (not through fail) would otherwise
# end with no `not ok` line at all, and the runner's "exit N" is a poor
# clue. Report it, then print the plan on success so TAP consumers can
# tell a complete run from a truncated one.
_test_on_exit() {
    local rc=$?
    if [[ $rc -ne 0 && "$_TEST_FAILED" != true ]]; then
        printf 'not ok - %s exited %d before finishing\n' "$_TEST_FILE" "$rc" >&2
    elif [[ $rc -eq 0 ]]; then
        printf '1..%d\n' "$_TEST_PASSED"
    fi
    rm -rf "$TEST_TMP"
    exit "$rc"
}
trap _test_on_exit EXIT

# ── Reporting ─────────────────────────────────

pass() {
    _TEST_PASSED=$((_TEST_PASSED + 1))
    printf 'ok - %s\n' "$1"
}

fail() {
    local description="$1" detail="${2:-}"
    _TEST_FAILED=true
    [[ -n "$detail" ]] && printf '%s\n' "$detail" >&2
    printf 'not ok - %s\n' "$description" >&2
    exit 1
}

# A comment line between groups of assertions; TAP consumers ignore it.
section() {
    printf '# %s\n' "$1"
}

require_command() {
    command -v "$1" >/dev/null 2>&1 || fail "required command is available: $1"
}

# ── Assertions ────────────────────────────────
# Argument order is always (subject..., label). The label is what shows
# up in the TAP line, so make it read as a claim: "config has one Host".

assert_eq() {
    local actual="$1" expected="$2" label="$3"
    if [[ "$actual" == "$expected" ]]; then
        pass "$label"
    else
        fail "$label" "expected: $expected
actual:   $actual"
    fi
}

# Substring match on text (fixed string, not a regex).
assert_contains() {
    local text="$1" needle="$2" label="$3"
    if [[ "$text" == *"$needle"* ]]; then
        pass "$label"
    else
        fail "$label" "'$needle' not found in:
$text"
    fi
}

assert_not_contains() {
    local text="$1" needle="$2" label="$3"
    if [[ "$text" != *"$needle"* ]]; then
        pass "$label"
    else
        fail "$label" "'$needle' unexpectedly present in:
$text"
    fi
}

# Basic regular expression (grep) on text.
assert_matches() {
    local text="$1" pattern="$2" label="$3"
    if printf '%s\n' "$text" | /usr/bin/grep -q -- "$pattern"; then
        pass "$label"
    else
        fail "$label" "/$pattern/ did not match:
$text"
    fi
}

assert_not_matches() {
    local text="$1" pattern="$2" label="$3"
    if printf '%s\n' "$text" | /usr/bin/grep -q -- "$pattern"; then
        fail "$label" "/$pattern/ unexpectedly matched:
$text"
    else
        pass "$label"
    fi
}

# Basic regular expression (grep) on a file's contents.
assert_file_contains() {
    local file="$1" pattern="$2" label="$3"
    if /usr/bin/grep -q -- "$pattern" "$file" 2>/dev/null; then
        pass "$label"
    else
        fail "$label" "/$pattern/ not found in $file"
    fi
}

assert_file_not_contains() {
    local file="$1" pattern="$2" label="$3"
    if /usr/bin/grep -q -- "$pattern" "$file" 2>/dev/null; then
        fail "$label" "/$pattern/ unexpectedly found in $file"
    else
        pass "$label"
    fi
}

# Number of lines in a file matching a pattern.
assert_count() {
    local file="$1" pattern="$2" expected="$3" label="$4"
    local count
    count=$(/usr/bin/grep -c -- "$pattern" "$file" 2>/dev/null || echo 0)
    count=$(echo "$count" | tr -d '[:space:]')
    if [[ "$count" -eq "$expected" ]]; then
        pass "$label"
    else
        fail "$label" "expected $expected matches of /$pattern/ in $file, got $count"
    fi
}

assert_file_exists() {
    local path="$1" label="$2"
    if [[ -f "$path" ]]; then
        pass "$label"
    else
        fail "$label" "no regular file at $path"
    fi
}

# Nothing at the path: no file, directory, or (even dangling) symlink.
assert_file_not_exists() {
    local path="$1" label="$2"
    if [[ ! -e "$path" && ! -L "$path" ]]; then
        pass "$label"
    else
        fail "$label" "$path still exists"
    fi
}

assert_dir_exists() {
    local path="$1" label="$2"
    if [[ -d "$path" ]]; then
        pass "$label"
    else
        fail "$label" "no directory at $path"
    fi
}

assert_dir_not_exists() {
    local path="$1" label="$2"
    if [[ ! -d "$path" ]]; then
        pass "$label"
    else
        fail "$label" "directory $path still exists"
    fi
}

# A symlink whose target is exactly the expected path.
assert_symlink() {
    local link="$1" expected_target="$2" label="$3"
    if [[ -L "$link" && "$(readlink "$link")" == "$expected_target" ]]; then
        pass "$label"
    else
        fail "$label" "expected $link -> $expected_target, got: $(readlink "$link" 2>/dev/null || echo '(not a symlink)')"
    fi
}

assert_is_symlink() {
    local path="$1" label="$2"
    if [[ -L "$path" ]]; then
        pass "$label"
    else
        fail "$label" "$path is not a symlink"
    fi
}

# Octal permission bits, e.g. 600 or 700.
assert_perm() {
    local file="$1" expected="$2" label="$3"
    local actual
    actual=$(stat -f '%Lp' "$file" 2>/dev/null || echo "???")
    if [[ "$actual" == "$expected" ]]; then
        pass "$label"
    else
        fail "$label" "expected mode $expected on $file, got $actual"
    fi
}

assert_snapshots_equal() {
    local snap1="$1" snap2="$2" label="$3"
    if diff -q "$snap1" "$snap2" >/dev/null 2>&1; then
        pass "$label"
    else
        fail "$label" "$(diff "$snap1" "$snap2" 2>&1 || true)"
    fi
}

# assert_succeeds <label> <command...> / assert_fails <label> <command...>
assert_succeeds() {
    local label="$1"
    shift
    if "$@"; then
        pass "$label"
    else
        fail "$label" "command failed: $*"
    fi
}

assert_fails() {
    local label="$1"
    shift
    if "$@"; then
        fail "$label" "command unexpectedly succeeded: $*"
    else
        pass "$label"
    fi
}
