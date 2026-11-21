#!/usr/bin/env bash
# Migration: Claude Code settings rendered from settings.base.json
#
# .config/claude/settings.json left git and became a generated file, so a
# pull on a machine set up before this change deletes it from the checkout
# and leaves ~/.claude/settings.json dangling. Render it now from the new
# base so Claude Code keeps its settings; later renders run with every
# `dotfiles theme`, sync and update.
set -euo pipefail

# A machine with local edits in the old tracked file (an autoMode block,
# say) had them auto-stashed by update.sh before the pull. Popping the
# stash ends one of two ways, and both would leave those edits where git
# tracks them:
#   - git follows the rename and applies them to settings.base.json, so the
#     private block sits in the tracked base as an uncommitted change;
#   - or the pop conflicts (modified here, deleted upstream) and git leaves
#     this machine's copy in the working tree.
# Either way, move the copy to the live file and restore what git tracks;
# the render below then adopts the shared keys and keeps autoMode local.
f=".config/claude/settings.json"
b=".config/claude/settings.base.json"
if [[ -n "$(git -C "$DOTFILES_DIR" ls-files -u -- "$f")" ]]; then
    git -C "$DOTFILES_DIR" rm --cached -q -- "$f"
    echo "    kept this machine's $f from the update's auto-stash"
elif [[ ! -e "$DOTFILES_DIR/$f" && -f "$DOTFILES_DIR/$b" ]] \
    && ! git -C "$DOTFILES_DIR" diff --quiet -- "$b"; then
    cp "$DOTFILES_DIR/$b" "$DOTFILES_DIR/$f"
    git -C "$DOTFILES_DIR" checkout -q -- "$b"
    echo "    moved this machine's local Claude settings out of the tracked $b"
fi

if [[ -f "$DOTFILES_DIR/.config/claude/settings.base.json" ]]; then
    bash "$DOTFILES_DIR/scripts/claude-settings.sh" --quiet
    echo "    rendered .config/claude/settings.json from settings.base.json"
fi
