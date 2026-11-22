#!/usr/bin/env bash
# doc: Private words — `scripts/git-hooks`: a commit whose added lines, file names or message contain a word from ~/.config/dotfiles/private-words or a shared list in private-words.d/ is stopped; `range` mode for pull requests, with a quiet report that never prints the matched text; removals, comments, `-v` diffs and --no-verify pass; the migration that turns the hooks on

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
assert_contains "$out" "notes.txt:2: built for the SECRET PROJECT team" "and names the file, line number and line"
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

section "shared lists in private-words.d"
TEAM="$TEST_TMP/team-repo"
mkdir -p "$TEAM" "$HOME/.config/dotfiles/private-words.d"
printf '# the team list, kept in a private repo\nclient-zeta\n' > "$TEAM/words"
ln -s "$TEAM/words" "$HOME/.config/dotfiles/private-words.d/team"
echo "for client-zeta" > team.txt && git add team.txt
out=$(try "docs: team note")
assert_contains "$out" "rc=1" "a word from a list linked into private-words.d stops the commit"
assert_contains "$out" "$HOME/.config/dotfiles/private-words.d/team" "and that list is named"
git reset -q
echo "acme_internal again" > team.txt && git add team.txt
assert_contains "$(try "docs: mine")" "rc=1" "your own list still applies alongside it"
git reset -q
out=$(DOTFILES_PRIVATE_WORDS="$TEST_TMP/absent" try "feat: client-zeta export")
assert_contains "$out" "rc=1" "a shared list works without a personal one"
git reset -q
printf 'nightly-thing\n' > "$HOME/.config/dotfiles/private-words.d/team~"
printf 'nightly-thing\n' > "$HOME/.config/dotfiles/private-words.d/.hidden"
printf 'nightly-thing\n' > "$HOME/.config/dotfiles/private-words.d/old.bak"
echo "the nightly-thing job" > team.txt && git add team.txt
assert_contains "$(try "docs: nightly")" "rc=0" "editor backups and hidden files in the folder are not lists"
mkdir -p "$TEST_TMP/other-dir" && printf 'nightly-thing\n' > "$TEST_TMP/other-dir/words"
echo "the nightly-thing job, again" > team.txt && git add team.txt
out=$(DOTFILES_PRIVATE_WORDS_DIR="$TEST_TMP/other-dir" try "docs: nightly again")
assert_contains "$out" "rc=1" "DOTFILES_PRIVATE_WORDS_DIR points the shared folder elsewhere"
git reset -q && rm -f team.txt
rm -rf "$HOME/.config/dotfiles/private-words.d"

section "range (CI on pull requests)"
git switch -q -c feature
echo "plain change" > feature.txt && git add feature.txt && git commit -q -m "feat: plain"
rc=0; out=$(bash "$HOOKS/private-words" range main feature 2>&1) || rc=$?
assert_eq "$rc" "0" "a clean branch passes"
printf 'one\ntwo\nshipped to Secret Project\n' > feature.txt && git add feature.txt && git commit -q --no-verify -m "feat: ship it"
echo "x" > "acme_internal-notes.md" && git add . && git commit -q --no-verify -m "docs: notes for acme_internal"
rc=0; out=$(bash "$HOOKS/private-words" range main feature 2>&1) || rc=$?
assert_eq "$rc" "1" "a branch adding a private word fails"
assert_contains "$out" "feature.txt:3: shipped to Secret Project" "added lines are reported with their line number"
assert_contains "$out" "acme_internal-notes.md (name)" "new file names are checked"
assert_matches "$out" "commit [0-9a-f][0-9a-f]*: docs: notes for acme_internal" "and so are the branch's commit messages"
rc=0; out=$(DOTFILES_PRIVATE_WORDS_QUIET=1 bash "$HOOKS/private-words" range main feature 2>&1) || rc=$?
assert_eq "$rc" "1" "quiet mode still fails"
assert_contains "$out" "feature.txt:3" "and says where"
assert_not_contains "$out" "Secret Project" "but never prints the matched line"
assert_not_contains "$out" "docs: notes for" "or the commit message"
assert_contains "$out" "push again" "and gives advice that fits CI"
assert_not_contains "$out" "--no-verify" "not the local override"
git switch -q main
git rm -q feature.txt 2>/dev/null || true
rc=0; bash "$HOOKS/private-words" range feature main >/dev/null 2>&1 || rc=$?
assert_eq "$rc" "0" "lines a branch removes do not count"
rc=0; bash "$HOOKS/private-words" range main >/dev/null 2>&1 || rc=$?
assert_eq "$rc" "2" "range needs a base and a head"

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
