#!/usr/bin/env bash
# ============================================
# UPDATE AVAILABLE SUITE — dotfiles update available
# ============================================
# A copy of bin/ and scripts/ inside a git repo with a bare local origin
# stands in for the checkout; brew is a stub whose `outdated` output the
# test controls. Everything lands in the sandbox HOME and a state dir.
# ============================================
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

MOCK="$TEST_TMP/mock"
ORIGIN="$TEST_TMP/origin.git"
STATE="$TEST_TMP/state"
STUB="$TEST_TMP/stub"
CMD="$MOCK/bin/dotfiles-update-available"

setup() {
    rm -rf "$MOCK" "$ORIGIN" "$STATE" "$STUB"
    mkdir -p "$MOCK/migrations" "$STATE" "$STUB"
    cp -R "$ROOT/bin" "$ROOT/scripts" "$MOCK/"
    (cd "$MOCK" && git init -q -b main && git config user.name t && git config user.email t@t \
        && git add -A && git commit -qm init)
    git clone -q --bare "$MOCK" "$ORIGIN"
    (cd "$MOCK" && git remote add origin "$ORIGIN")
    : > "$STUB/outdated"
    cat > "$STUB/brew" <<STUB
#!/bin/bash
[[ "\$1" == "outdated" ]] && cat "$STUB/outdated"
exit 0
STUB
    chmod +x "$STUB/brew"
}

run() {
    (PATH="$STUB:$PATH" DOTFILES_STATE_DIR="$STATE" DOTFILES_FETCH_TIMEOUT=5 bash "$CMD" "$@" 2>"$TEST_TMP/stderr")
}

push_to_origin() {
    local work="$TEST_TMP/origin-work"
    rm -rf "$work"
    git clone -q "$ORIGIN" "$work"
    echo "$RANDOM" > "$work/change-$RANDOM"
    (cd "$work" && git config user.name t && git config user.email t@t \
        && git add -A && git commit -qm "change" && git push -q origin main)
}

section "nothing waiting"
setup
set +e; out=$(run); rc=$?; set -e
assert_eq "$rc" "1" "exit 1 when everything is current"
assert_eq "$out" "Everything is up to date" "says so"
assert_file_exists "$STATE/update-available" "cache written"
assert_file_contains "$STATE/update-available" "^# checked" "cache carries a timestamp"
assert_eq "$(/usr/bin/grep -vc '^#' "$STATE/update-available")" "0" "cache has no items"
set +e; out=$(run --short); rc=$?; set -e
assert_eq "$rc$out" "1" "--short prints nothing and exits 1 when current"
set +e; run --quiet >/dev/null; rc=$?; set -e
assert_eq "$rc" "1" "--quiet exits 1 when current"

section "commits on origin"
push_to_origin
push_to_origin
set +e; out=$(run); rc=$?; set -e
assert_eq "$rc" "0" "exit 0 when something is waiting"
assert_contains "$out" "repo: 2 commits behind origin/main (run: dotfiles update)" "counts commits behind"
assert_file_contains "$STATE/update-available" "repo: 2 commits behind" "cache holds the item"
out=$(run --short)
assert_eq "$out" "2 commits behind origin/main (run: dotfiles update)" "--short joins items on one line"

section "brew, migrations and restarts"
printf 'jq\nripgrep\nfd\n' > "$STUB/outdated"
printf '#!/usr/bin/env bash\n' > "$MOCK/migrations/1700000000-example.sh"
mkdir -p "$STATE"
touch "$STATE/restart-sketchybar-required"
out=$(run)
assert_contains "$out" "brew: 3 packages outdated" "counts outdated packages"
assert_contains "$out" "migrations: 1 migration pending (run: dotfiles migrate)" "counts pending migrations, singular"
assert_contains "$out" "restarts: sketchybar to restart (run: dotfiles restart --pending)" "lists restart markers"
out=$(run --short)
assert_eq "$out" "2 commits behind origin/main, 3 packages outdated, 1 migration pending, sketchybar to restart (run: dotfiles update)" "--short summarises every item"

section "cached reads"
out=$(run --cached)
assert_contains "$out" "brew: 3 packages outdated" "--cached prints the last result"
: > "$STUB/outdated"
out=$(run --cached --short)
assert_contains "$out" "3 packages outdated" "--cached does not re-check"
rm -f "$STATE/update-available"
set +e; out=$(run --cached); rc=$?; set -e
assert_eq "$rc" "1" "--cached with no cache exits 1"
assert_eq "$out" "Everything is up to date" "and does not invent items"

section "origin unreachable"
rm -rf "$ORIGIN"
set +e; out=$(run --short); rc=$?; set -e
assert_contains "$(cat "$TEST_TMP/stderr")" "Could not fetch origin" "a failed fetch is reported on stderr"
assert_not_contains "$out" "behind" "and the repo item is left out rather than guessed"
assert_contains "$out" "1 migration pending" "the other checks still run"

section "arguments"
set +e; out=$(run --bogus); rc=$?; set -e
assert_eq "$rc" "2" "unknown option exits 2"
out=$(run --help)
assert_contains "$out" "--cached" "--help describes the flags"

section "bash 3.2"
assert_succeeds "parses under /bin/bash" /bin/bash -n "$CMD"
set +e; out=$(PATH="$STUB:$PATH" DOTFILES_STATE_DIR="$STATE" /bin/bash "$CMD" --cached --short 2>/dev/null); rc=$?; set -e
assert_contains "$out" "1 migration pending" "runs under /bin/bash 3.2"
