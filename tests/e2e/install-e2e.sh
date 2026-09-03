#!/usr/bin/env bash
# ============================================
# END-TO-END INSTALL
# ============================================
# Runs the real install.sh, under /bin/bash 3.2 (the curl-bootstrap
# interpreter), into a fresh HOME with `--groups core`, then checks the
# machine the way a first login would find it.
#
# Deliberately NOT under tests/*-test.sh: it installs real Homebrew
# packages and takes minutes. CI runs it in its own job; locally it is
# `/bin/bash tests/e2e/install-e2e.sh`.
#
# It installs from a COPY of the checkout, not the checkout itself. The
# symlinks land in the temporary HOME but they point at the repo, and
# install.sh then writes through them: git setup edits .gitconfig, the
# theme step refreshes the gitignored rendered copies. On a copy that
# is contained; on the real checkout it would rewrite tracked files.
# ============================================
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/base-test.sh"

require_command brew
require_command git
require_command zsh

THEME="${DOTFILES_THEME:-tokyo-night}"
LOG="$TEST_TMP/install.log"
E2E_ROOT="$TEST_TMP/dotfiles"
cp -R "$ROOT" "$E2E_ROOT"

# Never block on a password prompt; CI has passwordless sudo, a laptop
# does not. Keep the runner's login shell alone (install.sh only calls
# chsh when $SHELL is not zsh). Skip the brew self-update: it is slow
# and not what this test is about.
export DOTFILES_NO_SUDO=1
export SHELL=/bin/zsh
export HOMEBREW_NO_AUTO_UPDATE=1
export HOMEBREW_NO_INSTALL_CLEANUP=1

section "Fresh install under /bin/bash $(/bin/bash -c 'echo "$BASH_VERSION"') into $HOME"

if /bin/bash "$E2E_ROOT/install.sh" \
    --groups core \
    --name "CI Tester" \
    --email "ci@example.com" \
    --ssh skip \
    --no-macos-defaults \
    --no-runtimes \
    >"$LOG" 2>&1; then
    pass "install.sh exits 0"
else
    fail "install.sh exits 0" "$(tail -60 "$LOG")"
fi

assert_file_contains "$LOG" "Every selected package installed cleanly" "no package in the core group failed"
assert_file_contains "$LOG" "Theme: $THEME" "theme $THEME selected without a prompt"
assert_file_contains "$LOG" "All symlinks processed" "symlink step ran"
assert_file_not_contains "$LOG" "Warning: unknown option" "every flag was recognised"

section "Managed symlinks"

# Ask the map itself, so a new entry is covered the day it is added.
DOTFILES_DIR="$E2E_ROOT"
source "$E2E_ROOT/scripts/symlink-map.sh"

_LINK_OK=0
_LINK_BAD=""
_check_link() {
    local source="$1" target="$2" name="$3"
    if [[ -L "$target" && "$(readlink "$target")" == "$source" ]]; then
        _LINK_OK=$((_LINK_OK + 1))
    else
        _LINK_BAD="$_LINK_BAD
  $name: $target -> $(readlink "$target" 2>/dev/null || echo '(missing)')"
    fi
}
dotfiles_for_each_link _check_link
if [[ -z "$_LINK_BAD" ]]; then
    pass "all $_LINK_OK mapped symlinks point into the installed copy"
else
    fail "all mapped symlinks point into the installed copy" "broken:$_LINK_BAD"
fi
if [[ "$_LINK_OK" -gt 20 ]]; then
    pass "the map is not empty ($_LINK_OK links)"
else
    fail "the map is not empty" "only $_LINK_OK links checked"
fi

section "State written by the install"

assert_eq "$(cat "$HOME/.dotfiles-theme")" "$THEME" "~/.dotfiles-theme records the theme"
assert_file_contains "$HOME/.dotfiles-packages" "^+core$" "~/.dotfiles-packages records the core group"

THEME_STATE="$HOME/.local/state/dotfiles/current/theme"
assert_dir_exists "$THEME_STATE" "theme rendered into ~/.local/state"
for rendered in ghostty zellij.kdl starship.toml sketchybar-colors.sh claude.json; do
    assert_file_exists "$THEME_STATE/$rendered" "rendered $rendered present"
done
assert_file_not_exists "$HOME/.local/state/dotfiles/next-theme" "no staging directory left behind"

section "Core packages"

_formulae="$(brew list --formula -1)"
for tool in starship mise fzf zoxide eza bat atuin ripgrep fd jq; do
    assert_contains "$_formulae" "$tool" "brew formula $tool installed"
done

section "The shell that results"

# An interactive zsh must start cleanly against the linked .zshrc with
# only the core group present. stderr is the assertion: plugin loaders
# and init hooks that reference missing tools print there. Without a
# tty zsh refuses to turn on line editing ("can't change option: zle")
# from the init snippets; that line says nothing about the config.
# Start in HOME like a login shell would: from the checkout, mise would
# instead complain about the repo's own untrusted config.toml.
_zsh_err="$( (cd "$HOME" && zsh -i -c 'exit 0' </dev/null 2>&1 >/dev/null || echo "zsh exited $?") | /usr/bin/grep -v "can't change option: zle" || true)"
assert_eq "$_zsh_err" "" "interactive zsh starts without errors"

section "Second run is idempotent"

if /bin/bash "$E2E_ROOT/install.sh" \
    --groups core --name "CI Tester" --email "ci@example.com" \
    --ssh skip --no-macos-defaults --no-runtimes >"$LOG.2" 2>&1; then
    pass "install.sh exits 0 on a re-run"
else
    fail "install.sh exits 0 on a re-run" "$(tail -60 "$LOG.2")"
fi
assert_file_not_contains "$LOG.2" "replaced existing directory" "re-run replaced nothing"
assert_file_contains "$LOG.2" "Personal Git identity: CI Tester <ci@example.com>" "re-run keeps the git identity"
assert_eq "$(git config --file "$E2E_ROOT/.gitconfig" user.name)" "CI Tester" "identity written through ~/.gitconfig"
_LINK_OK=0
_LINK_BAD=""
dotfiles_for_each_link _check_link
if [[ -z "$_LINK_BAD" ]]; then
    pass "symlinks unchanged after the re-run"
else
    fail "symlinks unchanged after the re-run" "broken:$_LINK_BAD"
fi
