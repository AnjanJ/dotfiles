#!/usr/bin/env bash
# Migration: Claude Code settings rendered from settings.base.json
#
# .config/claude/settings.json left git and became a generated file, so a
# pull on a machine set up before this change deletes it from the checkout
# and leaves ~/.claude/settings.json dangling. Render it now from the new
# base so Claude Code keeps its settings; later renders run with every
# `dotfiles theme`, sync and update.
set -euo pipefail

if [[ -f "$DOTFILES_DIR/.config/claude/settings.base.json" ]]; then
    bash "$DOTFILES_DIR/scripts/claude-settings.sh" --quiet
    echo "    rendered .config/claude/settings.json from settings.base.json"
fi
