#!/usr/bin/env bash
# Migration: use the repo's own commit hooks (scripts/git-hooks)
#
# The repo is public. scripts/git-hooks/pre-commit and commit-msg stop a
# commit that contains a word from ~/.config/dotfiles/private-words; git
# only runs them once core.hooksPath points there. Set in this checkout's
# .git/config only, so no other repository is affected. A hooksPath set
# to something else is left alone, with a note.
# Runs once per machine with DOTFILES_DIR exported. Must be idempotent.
set -euo pipefail

want="scripts/git-hooks"
[[ -d "$DOTFILES_DIR/.git" || -f "$DOTFILES_DIR/.git" ]] || exit 0
current=$(git -C "$DOTFILES_DIR" config --local core.hooksPath 2>/dev/null || true)
if [[ -z "$current" ]]; then
    git -C "$DOTFILES_DIR" config --local core.hooksPath "$want"
    echo "    commits to the dotfiles repo now check ~/.config/dotfiles/private-words"
elif [[ "$current" != "$want" ]]; then
    echo "    core.hooksPath is already $current; left alone. To check private words, call $want/pre-commit and commit-msg from your hooks."
fi
