#!/usr/bin/env bash
# Migration: palette-first theming
#
# The theme system now renders every app config from themes/<name>/colors.toml
# into ~/.local/state/dotfiles/current/theme/. Two things a machine set up
# before this change is left with:
#   - ~/.config/starship.toml is a symlink to a repo file that no longer
#     exists (starship now reads $STARSHIP_CONFIG from the rendered dir)
#   - the previous per-theme Ghostty/Zellij/nvim theme files inside the
#     linked config dirs are gone from git, but a stale copy may remain
#     if the checkout was dirty
# Both are safe to remove; `dotfiles sync` re-renders the active theme.
set -euo pipefail

link="$HOME/.config/starship.toml"
if [[ -L "$link" && ! -e "$link" ]]; then
    rm -f "$link"
    echo "    removed dangling $link"
fi

for stale in "$DOTFILES_DIR/.config/ghostty/themes/Aura" "$DOTFILES_DIR/.config/nvim/lua/plugins/aura-theme.lua" \
             "$DOTFILES_DIR/.config/nvim/lua/plugins/tokyo-night-theme.lua" "$DOTFILES_DIR/.config/nvim/lua/plugins/catppuccin-theme.lua"; do
    if [[ -f "$stale" ]] && ! git -C "$DOTFILES_DIR" ls-files --error-unmatch "$stale" &>/dev/null; then
        rm -f "$stale"
        echo "    removed stale $stale"
    fi
done
rmdir "$DOTFILES_DIR/.config/ghostty/themes" 2>/dev/null || true
