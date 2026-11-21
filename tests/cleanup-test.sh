#!/usr/bin/env bash
# doc: Cleanup — `dotfiles cleanup` against a fake brew: the dry run never passes `--force`, `--force` does and then runs `brew cleanup`, packages kept in the personal tap reach the Brewfile brew is handed so they are never removed, a clean system says so, a missing Brewfile stops it, and bash 3.2
# ============================================
# CLEANUP TEST SUITE
# ============================================
# bin/dotfiles-cleanup removes Homebrew packages the Brewfile does not
# list, so what it hands `brew bundle cleanup` decides what is
# uninstalled. A fake brew records the arguments and the Brewfile it got.
# Usage: tests/run cleanup   (or /opt/homebrew/bin/bash tests/cleanup-test.sh)
# ============================================
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

C="$ROOT/bin/dotfiles-cleanup"
MOCK="$TEST_TMP/repo"
FAKEBIN="$TEST_TMP/fakebin"
mkdir -p "$MOCK/scripts" "$MOCK/homebrew-tap/Casks" "$FAKEBIN"
cp "$ROOT/scripts/_helpers.sh" "$ROOT/scripts/personal-tap.sh" "$MOCK/scripts/"
printf 'brew "jq"\ncask "ghostty"\n' > "$MOCK/Brewfile"
export DOTFILES_DIR="$MOCK" DOTFILES_TAP="tester/tap"
export FAKE_BREW_LOG="$TEST_TMP/brew.log" FAKE_BREW_HANDED="$TEST_TMP/handed.Brewfile"

cat > "$FAKEBIN/brew" <<'F'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$FAKE_BREW_LOG"
if [[ "$1 $2" == "bundle cleanup" ]]; then
    for a in "$@"; do [[ "$a" == --file=* ]] && cp "${a#--file=}" "$FAKE_BREW_HANDED"; done
    [[ -n "${FAKE_EXTRA:-}" ]] && printf 'Would uninstall formulae:\n%s\n' "$FAKE_EXTRA"
fi
exit 0
F
chmod +x "$FAKEBIN/brew"
export PATH="$FAKEBIN:$PATH"

echo ""
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║   Cleanup Tests                                           ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""

section "Test 1: The dry run only lists"
: > "$FAKE_BREW_LOG"
out=$(FAKE_EXTRA="stray-formula" "$C")
assert_contains "$out" "stray-formula" "extra packages are listed"
assert_contains "$out" "dotfiles cleanup --force" "and how to remove them"
assert_file_contains "$FAKE_BREW_LOG" "^bundle cleanup --file=" "brew bundle cleanup is asked"
assert_file_not_contains "$FAKE_BREW_LOG" "--force" "without --force"
echo ""

section "Test 2: Packages kept in the personal tap are never extra"
touch "$MOCK/homebrew-tap/Casks/qbittorrent.rb"
"$C" >/dev/null
assert_file_contains "$FAKE_BREW_HANDED" '^brew "jq"$' "the Brewfile's own lines are handed over"
assert_file_contains "$FAKE_BREW_HANDED" '^tap "tester/tap"$' "with the personal tap"
assert_file_contains "$FAKE_BREW_HANDED" '^cask "tester/tap/qbittorrent"$' "and its kept cask"
echo ""

section "Test 3: --force removes, then cleans"
: > "$FAKE_BREW_LOG"
"$C" --force >/dev/null
assert_file_contains "$FAKE_BREW_LOG" "^bundle cleanup --file=.* --force$" "--force reaches brew bundle cleanup"
assert_file_contains "$FAKE_BREW_LOG" "^cleanup$" "then brew cleanup runs"
assert_file_contains "$FAKE_BREW_HANDED" '^cask "tester/tap/qbittorrent"$' "kept packages are protected here too"
echo ""

section "Test 4: Clean, missing Brewfile, bash 3.2"
out=$("$C")
assert_contains "$out" "Everything is clean" "nothing extra says so"
mv "$MOCK/Brewfile" "$MOCK/Brewfile.away"
set +e; out=$("$C" 2>&1); rc=$?; set -e
assert_eq "$rc" "1" "a missing Brewfile stops it"
assert_contains "$out" "Brewfile not found" "and says why"
mv "$MOCK/Brewfile.away" "$MOCK/Brewfile"
out=$(FAKE_EXTRA="stray-formula" /bin/bash "$C")
assert_contains "$out" "stray-formula" "runs under /bin/bash 3.2"
echo ""
