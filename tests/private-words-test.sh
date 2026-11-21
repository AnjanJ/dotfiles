#!/usr/bin/env bash
# doc: Private words — `scripts/git-hooks`: a commit whose added lines, file names or message contain a word from ~/.config/dotfiles/private-words is stopped; removals, comments, `-v` diffs and --no-verify pass; the migration that turns the hooks on

# Commits go to a throwaway repo wired to the real hooks, under a
# temporary HOME; no real repo, config or word list is touched.
# Usage: tests/run private-words

set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

HOOKS="$ROOT/scripts/git-hooks"
MIGRATION=$(ls "$ROOT"/migrations/*-private-words-hook.sh)
printf '[user]\n\tname = Test\n\temail = test@example.com\n[commit]\n\tgpgsign = false\n[init]\n\tdefaultBranch = main\n' > "$HOME/.gitconfig"
mkdir -p "$HOME/.config/dotfiles"
LIST="$HOME/.config/dotfiles/private-words"
cat > "$LIST" <<'EOF'
# Names that must never reach the public repo
  Secret Project

acme_internal
EOF

REPO="$TEST_TMP/repo"
git init -q "$REPO"
git -C "$REPO" config core.hooksPath "$HOOKS"
cd "$REPO"

# try <message> — commits what is staged; prints the hooks' output, then rc=N.
try() {
    local rc=0 out
    out=$(git commit -q -m "$1" 2>&1) || rc=$?
    printf '%s\nrc=%s\n' "$out" "$rc"
}

section "allowed"
echo "nothing to hide" > notes.txt && git add notes.txt
assert_contains "$(try "docs: add notes")" "rc=0" "a clean commit goes through"

section "stopped"
echo "built for the SECRET PROJECT team" >> notes.txt && git add notes.txt
out=$(try "docs: more notes")
assert_contains "$out" "rc=1" "an added line with a private word stops the commit"
assert_contains "$out" "notes.txt: built for the SECRET PROJECT team" "and names the file and line"
assert_contains "$out" "commit with --no-verify" "and says how to override"
assert_contains "$out" "$LIST" "and which list matched"
git reset -q --hard

echo "fine" > ok.txt && git add ok.txt
out=$(try "feat: port the acme_internal billing fix")
assert_contains "$out" "rc=1" "a private word in the message stops the commit"
assert_contains "$out" "the commit message contains a word" "and says it was the message"
git reset -q

mkdir -p docs && echo "x" > docs/Acme_Internal-notes.md && git add docs
out=$(try "docs: add a page")
assert_contains "$out" "rc=1" "a private word in a new file's name stops the commit"
git reset -q && rm -rf docs ok.txt

section "removals, comments and overrides"
echo "acme_internal" > legacy.txt && git add legacy.txt
assert_contains "$(git commit -q --no-verify -m "chore: legacy" 2>&1; echo "rc=$?")" "rc=0" "--no-verify overrides"
git rm -q legacy.txt
assert_contains "$(try "chore: drop legacy")" "rc=0" "removing a private word is allowed"

printf 'docs: tidy\n\n# acme_internal appears only in a comment\n' > "$TEST_TMP/msg"
assert_eq "$(bash "$HOOKS/private-words" message "$TEST_TMP/msg"; echo $?)" "0" "comment lines in the message are ignored"
printf 'docs: tidy\n# ------------------------ >8 ------------------------\ndiff --git a/x b/x\n-acme_internal\n' > "$TEST_TMP/msg"
assert_eq "$(bash "$HOOKS/private-words" message "$TEST_TMP/msg"; echo $?)" "0" "the diff below git commit -v's scissors line is ignored"

section "no list"
echo "secret project" > other.txt && git add other.txt
out=$(DOTFILES_PRIVATE_WORDS="$TEST_TMP/absent" try "docs: other")
assert_contains "$out" "rc=0" "without a list nothing is checked"
printf '# only comments\n\n' > "$TEST_TMP/empty-list"
echo "secret project again" >> other.txt && git add other.txt
out=$(DOTFILES_PRIVATE_WORDS="$TEST_TMP/empty-list" try "docs: other again")
assert_contains "$out" "rc=0" "nor with a list of only comments"

section "bash 3.2"
echo "acme_internal" > b.txt && git add b.txt
rc=0; /bin/bash "$HOOKS/private-words" staged >/dev/null 2>&1 || rc=$?
assert_eq "$rc" "1" "/bin/bash runs the staged check"
git reset -q && rm -f b.txt
for f in "$HOOKS"/*; do
    /bin/bash -n "$f" || fail "$(basename "$f") parses under /bin/bash"
done
pass "every hook parses under /bin/bash"

section "migration"
cd "$TEST_TMP"
FAKE="$TEST_TMP/dotfiles"
git init -q "$FAKE"
out=$(DOTFILES_DIR="$FAKE" bash "$MIGRATION")
assert_eq "$(git -C "$FAKE" config --local core.hooksPath)" "scripts/git-hooks" "the migration points core.hooksPath at scripts/git-hooks"
assert_contains "$out" "private-words" "and says what changed"
assert_eq "$(DOTFILES_DIR="$FAKE" bash "$MIGRATION")" "" "a second run is silent"
assert_eq "$(git config --global core.hooksPath || echo unset)" "unset" "only the checkout is configured, not every repo"
git -C "$FAKE" config --local core.hooksPath .githooks
out=$(DOTFILES_DIR="$FAKE" bash "$MIGRATION")
assert_eq "$(git -C "$FAKE" config --local core.hooksPath)" ".githooks" "a hooksPath set to something else is left alone"
assert_contains "$out" "left alone" "with a note"
assert_eq "$(DOTFILES_DIR="$TEST_TMP/not-a-repo" bash "$MIGRATION"; echo $?)" "0" "a DOTFILES_DIR that is not a checkout is skipped"
