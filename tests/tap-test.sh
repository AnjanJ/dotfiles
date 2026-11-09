#!/usr/bin/env bash

# ============================================
# PERSONAL TAP TEST SUITE
# ============================================
# Tests scripts/personal-tap.sh and bin/dotfiles-tap-{check,update,list}
# against a stub brew and curl: finding packages Homebrew dropped (the
# install receipt beating the short name, dependencies left out), keep,
# remove and skip, --yes only listing, the download-before-uninstall
# order, version bumps and a failed bump, recipe cleaning, Brewfile line
# removal, the repo folder mirrored into Homebrew's working copy and
# back, and bash 3.2. The folder (DOTFILES_TAP_SRC) and the working copy
# (DOTFILES_TAP_DIR) are temporary; nothing touches Homebrew, the repo's
# homebrew-tap/ or the real Brewfile.
# Usage: tests/run tap   (or /opt/homebrew/bin/bash tests/tap-test.sh)
# ============================================

set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

CHECK="$ROOT/bin/dotfiles-tap-check"
UPDATE="$ROOT/bin/dotfiles-tap-update"
LIST="$ROOT/bin/dotfiles-tap-list"
INSTALL="$ROOT/bin/dotfiles-tap-install"

STUB="$TEST_TMP/stub"
FIX="$TEST_TMP/fixtures"
CALLS="$TEST_TMP/calls.log"
mkdir -p "$STUB" "$FIX"

export DOTFILES_TAP="me/tap"
export DOTFILES_TAP_DIR="$TEST_TMP/tap"
export DOTFILES_TAP_SRC="$TEST_TMP/repo/homebrew-tap"
SRC="$DOTFILES_TAP_SRC"
export DOTFILES_STATE_DIR="$TEST_TMP/state"
export DOTFILES_BREWFILE="$TEST_TMP/Brewfile"
export DOTFILES_CONFIG_DIR="$TEST_TMP/config"
export FIX CALLS
export PATH="$STUB:$PATH"

# brew answers from fixture files and logs every call.
cat > "$STUB/brew" <<'EOF'
#!/bin/bash
echo "brew $*" >> "$CALLS"
case "$*" in
    --repository) echo "$FIX/brew-repo" ;;
    --caskroom) echo "$FIX/caskroom" ;;
    --cellar) echo "$FIX/cellar" ;;
    "list --cask") cat "$FIX/casks" 2>/dev/null ;;
    "list --cask --versions "*|"list --formula --versions "*)
        /usr/bin/grep -qx "${*: -1}" "$FIX/installed" 2>/dev/null && echo "${*: -1} 1.0"
        exit 0 ;;
    "info --cask --json=v2 "*) cat "$FIX/casks.json" ;;
    "info --json=v2 --installed --formula") cat "$FIX/formulae.json" ;;
    trust*) exit 0 ;;
    uninstall*)
        /usr/bin/grep -vx "${*: -1}" "$FIX/installed" > "$FIX/installed.tmp" 2>/dev/null || true
        mv "$FIX/installed.tmp" "$FIX/installed"
        rm -rf "$FIX/caskroom/${*: -1}"
        exit 0 ;;
    install*)
        [[ "${INSTALL_RC:-0}" == 0 ]] || exit 1
        full="${*: -1}"; name="${full##*/}"
        echo "$name" >> "$FIX/installed"
        if [[ "$*" == *--cask* && "$full" == */*/* ]]; then
            mkdir -p "$FIX/caskroom/$name/.metadata"
            echo "{\"source\": {\"tap\": \"${full%/*}\"}}" > "$FIX/caskroom/$name/.metadata/INSTALL_RECEIPT.json"
        fi
        exit 0 ;;
    fetch*) exit "${FETCH_RC:-0}" ;;
    livecheck*) cat "$FIX/livecheck.json" ;;
    bump-*)
        version=""; prev=""
        for a in "$@"; do [[ "$prev" == --version ]] && version="$a"; prev="$a"; done
        name="${*: -1}"; name="${name##*/}"
        for f in "$DOTFILES_TAP_DIR"/Casks/"$name".rb "$DOTFILES_TAP_DIR"/Formula/"$name".rb; do
            [[ -f "$f" ]] && sed -i '' -E "s/version \"[^\"]+\"/version \"$version\"/" "$f"
        done
        # A failing bump may have half-written the recipe already.
        [[ "${BUMP_RC:-0}" == 0 ]] || { echo "bump went wrong"; exit 1; }
        exit 0 ;;
esac
exit 0
EOF
# curl serves the "official" recipe from the fixtures.
cat > "$STUB/curl" <<'EOF'
#!/bin/bash
echo "curl ${*: -1}" >> "$CALLS"
[[ -f "$FIX/recipe.rb" ]] || exit 22
cat "$FIX/recipe.rb"
EOF
chmod +x "$STUB/brew" "$STUB/curl"

reset() {
    rm -rf "$DOTFILES_TAP_DIR" "$SRC" "$DOTFILES_STATE_DIR" "$FIX"
    mkdir -p "$FIX/brew-repo" "$FIX/caskroom" "$DOTFILES_STATE_DIR"
    : > "$CALLS"
    printf 'qbittorrent\nfirefox\n' > "$FIX/casks"
    printf 'qbittorrent\nfirefox\ngemini-cli\njq\n' > "$FIX/installed"
    cat > "$FIX/casks.json" <<'EOF'
{"casks": [
 {"token": "qbittorrent", "tap": "homebrew/cask", "ruby_source_path": "Casks/q/qbittorrent.rb",
  "deprecated": false, "disabled": true, "disable_reason": "fails_gatekeeper_check", "disable_date": "2026-09-01"},
 {"token": "firefox", "tap": "homebrew/cask", "deprecated": false, "disabled": false}
]}
EOF
    cat > "$FIX/formulae.json" <<'EOF'
{"formulae": [
 {"name": "gemini-cli", "tap": "homebrew/core", "ruby_source_path": "Formula/g/gemini-cli.rb",
  "deprecated": true, "disabled": false, "deprecation_reason": "unsupported",
  "deprecation_date": "2026-06-18", "disable_date": "2026-12-18",
  "deprecation_replacement_cask": "antigravity-cli", "installed": [{"installed_on_request": true}]},
 {"name": "icu4c@78", "tap": "homebrew/core", "deprecated": true, "disabled": false,
  "deprecation_reason": "versioned_formula", "installed": [{"installed_on_request": false}]},
 {"name": "jq", "tap": "homebrew/core", "deprecated": false, "disabled": false,
  "installed": [{"installed_on_request": true}]}
]}
EOF
    cat > "$FIX/recipe.rb" <<'EOF'
cask "qbittorrent" do
  version "5.2.3"
  sha256 "abc"

  on_macos do
    disable! date: "2026-09-01", because: :fails_gatekeeper_check

    app "qbittorrent.app", target: "qBittorrent.app"
  end
end
EOF
    printf '# @group utilities\ncask "qbittorrent"  # torrents\ncask "firefox"\nbrew "gemini-cli"\nbrew "jq"\n' > "$DOTFILES_BREWFILE"
}

echo ""
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║   Personal Tap Tests                                      ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""

# ── Library ───────────────────────────────────
section "Library: name, recipe cleaning, Brewfile edits"
# shellcheck source=../scripts/personal-tap.sh
source "$ROOT/scripts/personal-tap.sh"
assert_eq "$(ptap_name)" "me/tap" "DOTFILES_TAP names the tap"
mkdir -p "$DOTFILES_CONFIG_DIR"
printf 'name=from/config\n' > "$DOTFILES_CONFIG_DIR/personal-tap"
assert_eq "$(DOTFILES_TAP='' ptap_name)" "from/config" "the config file names the tap when the env does not"
assert_eq "$(DOTFILES_TAP_SRC='' DOTFILES_DIR=/x ptap_src)" "/x/homebrew-tap" "the recipes live in the repo's homebrew-tap/"
rm -f "$DOTFILES_CONFIG_DIR/personal-tap"
assert_matches "$(DOTFILES_TAP='' ptap_name)" '^[a-z0-9-][a-z0-9-]*/tap$' "the default is <user>/tap"

cleaned=$(ptap_clean_recipe formula <<'EOF'
class Foo < Formula
  url "https://example.com/foo-1.0.tar.gz"

  bottle do
    sha256 arm64_sequoia: "aaa"
  end

  deprecate! date: "2026-01-01",
             because: :unsupported,
             replacement_formula: "bar"

  depends_on "node"
end
EOF
)
assert_not_contains "$cleaned" "deprecate!" "deprecate! is dropped"
assert_not_contains "$cleaned" "replacement_formula" "a wrapped deprecate! is dropped whole"
assert_not_contains "$cleaned" "bottle" "a formula's bottle block is dropped"
assert_contains "$cleaned" 'depends_on "node"' "the rest of the recipe stays"
assert_not_contains "$cleaned" $'\n\n\n' "no runs of blank lines are left"
reset
cask_cleaned=$(ptap_clean_recipe cask < "$FIX/recipe.rb")
assert_not_contains "$cask_cleaned" "disable!" "disable! is dropped from a cask"
assert_not_contains "$cask_cleaned" $'on_macos do\n\n' "no blank line is left at the top of a block"

out=$(ptap_brewfile_drop "$DOTFILES_BREWFILE" cask qbittorrent)
assert_eq "$out" 'cask "qbittorrent"  # torrents' "drop prints the removed line, comment and all"
assert_file_not_contains "$DOTFILES_BREWFILE" "qbittorrent" "the line is gone"
assert_file_contains "$DOTFILES_BREWFILE" '^cask "firefox"$' "other lines stay"
assert_file_contains "$DOTFILES_BREWFILE" '^# @group utilities$' "comments stay"
assert_fails "drop returns 1 when nothing matched" ptap_brewfile_drop "$DOTFILES_BREWFILE" cask qbittorrent
assert_fails "a cask drop leaves a same-named formula alone" ptap_brewfile_drop "$DOTFILES_BREWFILE" cask jq
printf 'brew "someone/tap/jq"\n' >> "$DOTFILES_BREWFILE"
ptap_brewfile_drop "$DOTFILES_BREWFILE" formula jq >/dev/null
assert_file_not_contains "$DOTFILES_BREWFILE" "jq" "tap-prefixed and plain lines for the package both go"
printf 'cask "a"\ncask "b"' > "$TEST_TMP/no-eol"
ptap_brewfile_drop "$TEST_TMP/no-eol" cask a >/dev/null
assert_eq "$(cat "$TEST_TMP/no-eol")" 'cask "b"' "the other line stays"
assert_eq "$(tail -c 1 "$TEST_TMP/no-eol")" '"' "a file without a final newline keeps having none"
mkdir -p "$SRC/Casks"
touch "$SRC/Casks/kept.rb"
assert_eq "$(ptap_with_brewfile "$TEST_TMP/no-eol")" $'cask "b"\ntap "me/tap"\ncask "me/tap/kept"' "the tap's lines start on their own line after a Brewfile with no final newline"
printf 'cask "b"\n' > "$TEST_TMP/eol"
assert_eq "$(ptap_with_brewfile "$TEST_TMP/eol")" $'cask "b"\ntap "me/tap"\ncask "me/tap/kept"' "and no blank line is added after one that has it"
rm -rf "$SRC"
assert_eq "$(ptap_brewfile_lines)" "" "no tap lines when the folder holds nothing"
assert_eq "$(ptap_humanize fails_gatekeeper_check)" "fails gatekeeper check" "reasons read as words"
echo ""

# ── Detection ─────────────────────────────────
section "Check: --yes lists dropped packages and remembers them"
reset
out=$("$CHECK" --yes 2>&1)
assert_contains "$out" "Homebrew dropped 2 package(s)" "two dropped packages found"
assert_contains "$out" "qbittorrent (cask) — disabled on 2026-09-01: fails gatekeeper check" "the cask, its date and reason"
assert_contains "$out" "gemini-cli (formula) — deprecated on 2026-06-18: unsupported" "the formula, its date and reason"
assert_contains "$out" "Homebrew suggests antigravity-cli instead" "Homebrew's replacement is named"
assert_contains "$out" "until Homebrew disables it on 2026-12-18" "a deprecated package says when it stops working"
assert_not_contains "$out" "icu4c" "a dependency nobody asked for is not listed"
assert_not_contains "$out" "firefox" "a healthy cask is not listed"
assert_eq "$(cat "$DOTFILES_STATE_DIR/tap-pending")" $'cask qbittorrent\nformula gemini-cli' "both are pending for the login notice"
assert_file_not_contains "$CALLS" "uninstall" "--yes changes nothing"
assert_file_not_contains "$CALLS" "^brew install" "--yes installs nothing"

section "Check: a terminal-less run behaves like --yes"
reset
out=$("$CHECK" </dev/null 2>&1)
assert_contains "$out" "Run dotfiles update in a terminal" "it says how to answer"
assert_file_exists "$DOTFILES_STATE_DIR/tap-pending" "pending recorded"

section "Check: a cask already installed from the tap is not listed"
reset
mkdir -p "$FIX/caskroom/qbittorrent/.metadata"
echo '{"source": {"tap": "me/tap"}}' > "$FIX/caskroom/qbittorrent/.metadata/INSTALL_RECEIPT.json"
out=$("$CHECK" --yes 2>&1)
assert_not_contains "$out" "qbittorrent" "the receipt beats the short name's official recipe"
assert_contains "$out" "Homebrew dropped 1 package(s)" "only the formula remains"

section "Check: nothing dropped clears the pending file"
reset
echo '{"casks": []}' > "$FIX/casks.json"
echo '{"formulae": []}' > "$FIX/formulae.json"
echo "formula old" > "$DOTFILES_STATE_DIR/tap-pending"
out=$("$CHECK" --yes 2>&1)
assert_eq "$out" "" "silent when nothing is dropped"
assert_file_not_exists "$DOTFILES_STATE_DIR/tap-pending" "stale pending file removed"
echo ""

# ── Answers ───────────────────────────────────
section "Keep: recipe into the tap, download, swap, Brewfile line out"
reset
out=$(printf 'k\ns\n' | DOTFILES_TAP_ASK=1 "$CHECK" 2>&1)
assert_contains "$out" "Kept qbittorrent: installed from me/tap" "keep reports success"
assert_file_exists "$SRC/Casks/qbittorrent.rb" "recipe written into the repo folder"
assert_file_not_contains "$SRC/Casks/qbittorrent.rb" "disable!" "without its disable! line"
assert_eq "$(cat "$DOTFILES_TAP_DIR/Casks/qbittorrent.rb")" "$(cat "$SRC/Casks/qbittorrent.rb")" "and mirrored into Homebrew's working copy"
assert_eq "$(git -C "$DOTFILES_TAP_DIR" status --short)" "" "which is committed, so Homebrew sees a clean tap"
assert_file_contains "$CALLS" "^curl https://raw.githubusercontent.com/Homebrew/homebrew-cask/HEAD/Casks/q/qbittorrent.rb$" "fetched from homebrew-cask by its source path"
assert_file_contains "$CALLS" "^brew trust --tap me/tap$" "the tap is trusted"
order=$(/usr/bin/grep -nE '^brew (fetch|uninstall|install) ' "$CALLS" | cut -d: -f2- | tr '\n' '|')
assert_eq "$order" "brew fetch --cask me/tap/qbittorrent|brew uninstall --cask qbittorrent|brew install --cask me/tap/qbittorrent|" "download first, then swap the install"
assert_file_not_contains "$DOTFILES_BREWFILE" "qbittorrent" "the public Brewfile no longer lists it"
assert_eq "$(cat "$DOTFILES_STATE_DIR/tap-pending")" "formula gemini-cli" "the skipped formula stays pending"

section "Keep: a failed download changes nothing"
reset
out=$(printf 'k\ns\n' | FETCH_RC=1 DOTFILES_TAP_ASK=1 "$CHECK" 2>&1)
assert_contains "$out" "Could not download qbittorrent" "the failure is reported"
assert_file_not_contains "$CALLS" "uninstall" "nothing uninstalled"
assert_file_not_exists "$SRC/Casks/qbittorrent.rb" "the recipe is taken back out of the folder"
assert_file_not_exists "$DOTFILES_TAP_DIR/Casks/qbittorrent.rb" "and out of the working copy"
assert_file_contains "$DOTFILES_BREWFILE" "qbittorrent" "the Brewfile is untouched"
assert_file_contains "$DOTFILES_STATE_DIR/tap-pending" "cask qbittorrent" "it stays pending"

section "Keep: a recipe that cannot be fetched changes nothing"
reset
rm -f "$FIX/recipe.rb"
out=$(printf 'k\ns\n' | DOTFILES_TAP_ASK=1 "$CHECK" 2>&1)
assert_contains "$out" "Could not fetch homebrew/cask's recipe for qbittorrent" "the failure is reported"
assert_file_not_contains "$CALLS" "^brew fetch" "no download attempted"

section "Remove and skip"
reset
out=$(printf 's\nr\n' | DOTFILES_TAP_ASK=1 "$CHECK" 2>&1)
assert_contains "$out" "Skipped; dotfiles update asks again next time" "skip says it will ask again"
assert_contains "$out" "Removed gemini-cli" "remove reports success"
assert_file_contains "$CALLS" "^brew uninstall --formula gemini-cli$" "the formula is uninstalled"
assert_file_not_contains "$DOTFILES_BREWFILE" "gemini-cli" "and dropped from the Brewfile"
assert_eq "$(cat "$DOTFILES_STATE_DIR/tap-pending")" "cask qbittorrent" "only the skipped cask is pending"
assert_dir_not_exists "$DOTFILES_TAP_DIR" "no tap is created when nothing is kept"
assert_dir_not_exists "$SRC" "and no folder"

section "A wrong key asks again"
reset
out=$(printf 'x\ns\ns\n' | DOTFILES_TAP_ASK=1 "$CHECK" 2>&1)
assert_contains "$out" "Type k, r or s" "the prompt repeats"
echo ""

# ── Update ────────────────────────────────────
section "Update: a newer upstream version is written and committed"
reset
printf 'k\ns\n' | DOTFILES_TAP_ASK=1 "$CHECK" >/dev/null 2>&1
echo '[{"cask": "qbittorrent", "version": {"current": "5.2.3", "latest": "5.2.4", "outdated": true}}]' > "$FIX/livecheck.json"
: > "$CALLS"
out=$("$UPDATE" 2>&1)
assert_contains "$out" "Updating qbittorrent 5.2.3 → 5.2.4 in your tap" "the bump is announced"
assert_contains "$out" "Open Anyway" "the Gatekeeper step is named"
assert_file_contains "$CALLS" "^brew livecheck --json --newer-only --quiet --cask me/tap/qbittorrent$" "livecheck asked about the tap's cask"
assert_eq "$(/usr/bin/grep -c '^brew livecheck' "$CALLS")" "1" "once per package, never for a blank name"
assert_file_contains "$CALLS" "^brew bump-cask-pr --write-only --no-audit --no-browse --version 5.2.4 me/tap/qbittorrent$" "the recipe is bumped in place"
assert_file_contains "$SRC/Casks/qbittorrent.rb" 'version "5.2.4"' "the repo folder carries the new version"
assert_file_contains "$DOTFILES_TAP_DIR/Casks/qbittorrent.rb" 'version "5.2.4"' "so does Homebrew's working copy"
assert_eq "$(git -C "$DOTFILES_TAP_DIR" log -1 --format=%s)" "qbittorrent 5.2.4" "which is committed"

section "Update: nothing newer, nothing done"
echo '[]' > "$FIX/livecheck.json"
: > "$CALLS"
out=$("$UPDATE" 2>&1)
assert_eq "$out" "" "silent when everything is current"
assert_file_not_contains "$CALLS" "bump" "no bump attempted"

section "Update: a failed bump leaves the recipe as it was"
echo '[{"cask": "qbittorrent", "version": {"current": "5.2.4", "latest": "5.2.5"}}]' > "$FIX/livecheck.json"
out=$(BUMP_RC=1 "$UPDATE" 2>&1)
assert_contains "$out" "Could not update qbittorrent's recipe; it stays at 5.2.4" "the failure is reported"
assert_contains "$out" "bump went wrong" "with Homebrew's own words"
assert_file_contains "$DOTFILES_TAP_DIR/Casks/qbittorrent.rb" 'version "5.2.4"' "a half-written recipe is rolled back"
assert_file_contains "$SRC/Casks/qbittorrent.rb" 'version "5.2.4"' "the repo folder is untouched"
assert_eq "$(git -C "$DOTFILES_TAP_DIR" status --short)" "" "the working copy is clean again"

section "Update: the folder wins over the working copy"
echo '[]' > "$FIX/livecheck.json"
rm -rf "$DOTFILES_TAP_DIR"
"$UPDATE" >/dev/null 2>&1
assert_file_contains "$DOTFILES_TAP_DIR/Casks/qbittorrent.rb" 'version "5.2.4"' "a machine without a working copy builds it from the folder"
assert_file_contains "$CALLS" "^brew trust --tap me/tap$" "and trusts it"
echo 'cask "gone" do; end' > "$DOTFILES_TAP_DIR/Casks/gone.rb"
sed -i '' 's/version "5.2.4"/version "5.2.6"/' "$SRC/Casks/qbittorrent.rb"
"$UPDATE" >/dev/null 2>&1
assert_file_not_exists "$DOTFILES_TAP_DIR/Casks/gone.rb" "a recipe the folder does not have leaves the working copy"
assert_file_contains "$DOTFILES_TAP_DIR/Casks/qbittorrent.rb" 'version "5.2.6"' "a recipe pulled from another machine reaches the working copy"

section "Update: no tap, nothing to do"
rm -rf "$DOTFILES_TAP_DIR" "$SRC"
: > "$CALLS"
out=$("$UPDATE" 2>&1)
assert_eq "$out" "" "silent without a tap"
assert_file_not_contains "$CALLS" "livecheck" "no livecheck without a tap"
echo ""

section "Update: a recipe nobody here installed from the tap is not bumped"
reset
mkdir -p "$SRC/Casks"
ptap_clean_recipe cask < "$FIX/recipe.rb" > "$SRC/Casks/qbittorrent.rb"
echo '[{"cask": "qbittorrent", "version": {"current": "5.2.3", "latest": "5.2.4"}}]' > "$FIX/livecheck.json"
out=$("$UPDATE" 2>&1)
assert_eq "$out" "" "silent when the installed copy is the official one"
assert_file_not_contains "$CALLS" "livecheck" "no livecheck"
assert_dir_not_exists "$DOTFILES_TAP_DIR" "and no Homebrew copy of the tap"
assert_file_contains "$SRC/Casks/qbittorrent.rb" 'version "5.2.3"' "the folder is untouched"

section "Keep: a recipe another machine already kept is reused"
reset
mkdir -p "$SRC/Casks"
ptap_clean_recipe cask < "$FIX/recipe.rb" | sed 's/version "5.2.3"/version "5.9.0"/' > "$SRC/Casks/qbittorrent.rb"
out=$(printf 'k\ns\n' | FETCH_RC=1 DOTFILES_TAP_ASK=1 "$CHECK" 2>&1)
assert_contains "$out" "Already kept in homebrew-tap/ by another machine" "says it is already kept"
assert_file_not_contains "$CALLS" "^curl" "Homebrew's older recipe is not fetched"
assert_file_exists "$SRC/Casks/qbittorrent.rb" "a failed download does not delete another machine's recipe"
out=$(printf 'k\ns\n' | DOTFILES_TAP_ASK=1 "$CHECK" 2>&1)
assert_contains "$out" "Kept qbittorrent" "the switch then succeeds"
assert_file_contains "$SRC/Casks/qbittorrent.rb" 'version "5.9.0"' "with the newer kept recipe"
echo ""

# ── Install on this machine ───────────────────
seed_kept() {
    reset
    mkdir -p "$SRC/Casks"
    ptap_clean_recipe cask < "$FIX/recipe.rb" > "$SRC/Casks/qbittorrent.rb"
    printf 'firefox\n' > "$FIX/installed"
}

section "Install: --yes lists what is missing and installs nothing"
seed_kept
out=$("$INSTALL" --yes 2>&1)
assert_contains "$out" "keeps 1 package(s) in homebrew-tap/ not installed here: qbittorrent" "names what is missing"
assert_eq "$(cat "$DOTFILES_STATE_DIR/tap-install-pending")" "cask qbittorrent" "pending for the login notice"
assert_file_not_contains "$CALLS" "^brew install" "nothing installed"
assert_dir_not_exists "$DOTFILES_TAP_DIR" "no Homebrew copy before this machine says yes"
assert_file_not_exists "$DOTFILES_STATE_DIR/tap-install" "no answer recorded"

section "Install: yes installs now and every later addition without asking"
out=$(printf 'y\n' | DOTFILES_TAP_ASK=1 "$INSTALL" 2>&1)
assert_contains "$out" "that are not installed here: qbittorrent" "says what it is asking about"
assert_file_contains "$CALLS" "^brew install --cask me/tap/qbittorrent$" "installs from the tap"
assert_eq "$(cat "$DOTFILES_STATE_DIR/tap-install")" "yes" "the answer is remembered"
assert_file_not_exists "$DOTFILES_STATE_DIR/tap-install-pending" "nothing pending"
assert_file_exists "$DOTFILES_TAP_DIR/Casks/qbittorrent.rb" "Homebrew's copy is built"
echo 'cask "other" do; end' > "$SRC/Casks/other.rb"
: > "$CALLS"
out=$("$INSTALL" --yes 2>&1)
assert_not_contains "$out" "that are not installed here" "a later addition is not asked about"
assert_file_contains "$CALLS" "^brew install --cask me/tap/other$" "it is installed, even unattended"
assert_file_not_contains "$CALLS" "me/tap/qbittorrent" "what is installed is left alone"
: > "$CALLS"
out=$("$INSTALL" --yes 2>&1)
assert_eq "$out" "" "silent when nothing is missing"

section "Install: Homebrew's copy follows the folder even with nothing missing"
sed -i '' 's/version "5.2.3"/version "5.2.7"/' "$SRC/Casks/qbittorrent.rb"
"$INSTALL" --yes >/dev/null 2>&1
assert_file_contains "$DOTFILES_TAP_DIR/Casks/qbittorrent.rb" 'version "5.2.7"' "a recipe bumped elsewhere reaches Homebrew"

section "Install: no means never, and never asking again"
seed_kept
out=$(printf 'n\n' | DOTFILES_TAP_ASK=1 "$INSTALL" 2>&1)
assert_eq "$(cat "$DOTFILES_STATE_DIR/tap-install")" "no" "the answer is remembered"
assert_file_not_contains "$CALLS" "^brew install" "nothing installed"
out=$(printf 'y\n' | DOTFILES_TAP_ASK=1 "$INSTALL" 2>&1)
assert_eq "$out" "" "not asked again"
assert_file_not_exists "$DOTFILES_STATE_DIR/tap-install-pending" "nothing pending"

section "Install: an answer given ahead of time"
seed_kept
out=$(DOTFILES_TAP_INSTALL=yes "$INSTALL" --yes 2>&1)
assert_file_contains "$CALLS" "^brew install --cask me/tap/qbittorrent$" "DOTFILES_TAP_INSTALL=yes installs unattended"
assert_eq "$(cat "$DOTFILES_STATE_DIR/tap-install")" "yes" "and holds for later runs"
seed_kept
DOTFILES_TAP_INSTALL=false "$INSTALL" --yes >/dev/null 2>&1
assert_eq "$(cat "$DOTFILES_STATE_DIR/tap-install")" "no" "false means no"

section "Install: a failed install is retried next run"
seed_kept
echo yes > "$DOTFILES_STATE_DIR/tap-install"
out=$(INSTALL_RC=1 "$INSTALL" --yes 2>&1)
assert_contains "$out" "Could not install qbittorrent; dotfiles update tries again next run" "the failure is reported"
out=$("$INSTALL" --yes 2>&1)
assert_contains "$out" "Installed qbittorrent" "and the next run installs it"
echo ""

# ── List ──────────────────────────────────────
section "List"
reset
out=$("$LIST" 2>&1)
assert_contains "$out" "No personal tap yet (me/tap)" "says when there is no tap"
printf 'k\ns\n' | DOTFILES_TAP_ASK=1 "$CHECK" >/dev/null 2>&1
out=$("$LIST" 2>&1)
assert_contains "$out" "Tap:     me/tap" "names the tap"
assert_contains "$out" "Recipes: $SRC" "names the repo folder"
assert_contains "$out" "This machine: not asked yet" "says whether this machine installs kept packages"
assert_matches "$out" 'cask  *qbittorrent  *1\.0' "lists the kept cask with its version"
assert_contains "$out" "formula gemini-cli" "lists what is still waiting for an answer"
echo ""

# ── Bash 3.2 ──────────────────────────────────
section "Bash 3.2"
for f in "$CHECK" "$UPDATE" "$LIST" "$INSTALL" "$ROOT/scripts/personal-tap.sh"; do
    assert_succeeds "$(basename "$f") parses under /bin/bash" /bin/bash -n "$f"
done
reset
out=$(printf 'k\nr\n' | DOTFILES_TAP_ASK=1 /bin/bash "$CHECK" 2>&1)
assert_contains "$out" "Kept qbittorrent" "keep works under /bin/bash"
assert_contains "$out" "Removed gemini-cli" "remove works under /bin/bash"
echo '[{"cask": "qbittorrent", "version": {"current": "5.2.3", "latest": "5.3.0"}}]' > "$FIX/livecheck.json"
out=$(/bin/bash "$UPDATE" 2>&1)
assert_contains "$out" "5.2.3 → 5.3.0" "update works under /bin/bash"
seed_kept
out=$(printf 'y\n' | DOTFILES_TAP_ASK=1 /bin/bash "$INSTALL" 2>&1)
assert_contains "$out" "Installed qbittorrent" "install works under /bin/bash"
echo ""

