#!/usr/bin/env bash
# Migration: editor settings rendered from settings.base.json
#
# .config/zed/settings.json and .config/vscode/settings.json left git and
# became generated copies of the new settings.base.json files, so a pull
# on a machine set up before this change deletes them from the checkout
# and leaves ~/.config/zed/settings.json (and the VS Code link under
# ~/Library) dangling until the next theme render. Seed the generated
# files from the base so the editors keep working; `dotfiles sync`
# re-renders the theme into them right after this runs.
set -euo pipefail

for pair in ".config/zed/settings.base.json:.config/zed/settings.json" \
            ".config/vscode/settings.base.json:.config/vscode/settings.json"; do
    base="$DOTFILES_DIR/${pair%%:*}"
    live="$DOTFILES_DIR/${pair##*:}"
    if [[ -f "$base" && ! -f "$live" ]]; then
        cp "$base" "$live"
        echo "    seeded ${pair##*:} from ${pair%%:*}"
    fi
done
