#!/usr/bin/env bash
# ============================================
# SHELL SUITE — the zsh helper functions
# ============================================
# The functions live in .zshrc-terminal-enhancements and are zsh, so
# each case runs `zsh -c` with just that file's section 13 sourced,
# against stubs for mise, ssh, pkill and pgrep.
# ============================================
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"
require_command zsh

FNS="$TEST_TMP/fns.zsh"
# Only section 13: the rest of the file initialises tools this sandbox lacks
awk '/^# 13\. WORKTREES/{p=1} /^# END OF TERMINAL ENHANCEMENTS/{p=0} p' "$ROOT/.zshrc-terminal-enhancements" > "$FNS"
[[ -s "$FNS" ]] || fail "section 13 extracted from .zshrc-terminal-enhancements"
pass "section 13 extracted from .zshrc-terminal-enhancements"

STUB="$TEST_TMP/stub"
CALLS="$TEST_TMP/calls"
mkdir -p "$STUB"
: > "$CALLS"
for c in mise ssh pkill pgrep; do
    # shellcheck disable=SC2016  # $* and STUB_RC are for the stub, not this shell
    printf '#!/bin/bash\necho "%s $*" >> "%s"\nexit "${STUB_RC:-0}"\n' "$c" "$CALLS" > "$STUB/$c"
    chmod +x "$STUB/$c"
done
z() { PATH="$STUB:$PATH" zsh -c "source '$FNS'; $*" 2>&1; }

section "worktrees"
REPO="$TEST_TMP/proj"
mkdir -p "$REPO" && (cd "$REPO" && git init -q -b main && git config user.name t && git config user.email t@t && echo a > a && git add a && git commit -qm init)
out=$(z "cd '$REPO' && gwa feature-x && pwd && git branch --show-current")
assert_contains "$out" "$TEST_TMP/proj--feature-x" "gwa creates <repo>--<branch> beside the repo and cds into it"
assert_contains "$out" "feature-x" "on the new branch"
assert_file_contains "$CALLS" "^mise trust .*/proj--feature-x$" "mise trust called on the worktree"
assert_dir_exists "$TEST_TMP/proj--feature-x" "worktree directory exists"
out=$(z "cd '$REPO' && gwa fix/slash && pwd")
assert_contains "$out" "$TEST_TMP/proj--fix-slash" "a slash in the branch becomes a dash in the directory"
set +e; out=$(z "cd '$TEST_TMP' && gwa nope"); rc=$?; set -e
assert_eq "$rc" "1" "gwa outside a repo fails"
assert_contains "$out" "Not in a git repository" "and says why"
set +e; out=$(z "cd '$REPO' && gwa"); rc=$?; set -e
assert_eq "$rc" "1" "gwa without a branch is a usage error"

out=$(z "cd '$TEST_TMP/proj--feature-x' && GWR_YES=1 gwr && pwd && git branch --list feature-x")
assert_contains "$out" "$TEST_TMP/proj" "gwr returns to the main checkout"
assert_dir_not_exists "$TEST_TMP/proj--feature-x" "worktree removed"
assert_eq "$(z "cd '$REPO' && git branch --list feature-x")" "" "branch deleted"
set +e; out=$(z "cd '$REPO' && GWR_YES=1 gwr"); rc=$?; set -e
assert_eq "$rc" "1" "gwr refuses a directory that is not <repo>--<branch>"
assert_contains "$out" "is not a gwa worktree" "and says why"
set +e; out=$(z "cd '$TEST_TMP/proj--fix-slash' && gwr </dev/null"); rc=$?; set -e
assert_eq "$rc" "1" "gwr without confirmation does nothing"
assert_dir_exists "$TEST_TMP/proj--fix-slash" "worktree kept"

section "archives"
mkdir -p "$TEST_TMP/pack/sub" && echo hello > "$TEST_TMP/pack/sub/file"
out=$(z "cd '$TEST_TMP' && compress pack/")
assert_eq "$out" "pack.tar.gz" "compress names the archive after the directory, trailing slash dropped"
assert_file_exists "$TEST_TMP/pack.tar.gz" "archive written"
mkdir -p "$TEST_TMP/unpack"
z "cd '$TEST_TMP/unpack' && decompress ../pack.tar.gz" >/dev/null
assert_eq "$(cat "$TEST_TMP/unpack/pack/sub/file")" "hello" "decompress restores the tree"
set +e; out=$(z "compress"); rc=$?; set -e
assert_eq "$rc" "1" "compress without an argument is a usage error"

section "ssh port forwards"
: > "$CALLS"
out=$(z "fip nyc-dev 3000 5432")
assert_contains "$out" "Forwarding localhost:3000 -> nyc-dev:3000" "fip reports each port"
assert_contains "$out" "Forwarding localhost:5432 -> nyc-dev:5432" "…every port"
assert_file_contains "$CALLS" "^ssh -f -N -L 3000:localhost:3000 nyc-dev$" "ssh called with a background tunnel"
out=$(z "dip 3000")
assert_eq "$out" "Stopped forwarding port 3000" "dip stops a forward"
assert_file_contains "$CALLS" "^pkill -f ssh.*-L 3000:localhost:3000$" "pkill matched the tunnel"
out=$(STUB_RC=1 z "dip 4000")
assert_eq "$out" "No forwarding on port 4000" "dip reports an absent forward"
out=$(STUB_RC=1 z "lip")
assert_eq "$out" "No active forwards" "lip with nothing running"
set +e; out=$(z "fip host"); rc=$?; set -e
assert_eq "$rc" "1" "fip needs a host and a port"
