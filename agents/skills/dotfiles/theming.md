# Theming

Read this before changing colours, fonts, the prompt palette, or anything that looks like a hex value.

## One palette, rendered everywhere

```
themes/<name>/colors.toml          ← THE source of colours (edit this)
themes/<name>/theme.conf           ← editor theme names, bat/delta theme, Warp
themes/<name>/overrides/<file>     ← optional hand-written replacement for one rendered file
themes/_templates/<file>.tpl       ← one template per app ({{ accent }}, {{ mix background foreground 10% }})
        │  dotfiles theme <name>
        ▼
~/.local/state/dotfiles/current/theme/<file>   ← rendered output (never edit)
```

Apps read the rendered directory: Starship (`$STARSHIP_CONFIG`), lazygit (`$LG_CONFIG_FILE`), WezTerm and Neovim (`dofile`), git-delta (`[include]`), fzf (`~/.zshrc-theme-env`), Claude Code (`~/.claude/themes/dotfiles.json`). Ghostty, Zellij, sketchybar and borders get a gitignored generated copy inside their config dir. Zed and VS Code have their theme *name* written into their settings.

Themes: `tokyo-night`, `aura`, `catppuccin` (dark) and `catppuccin-latte`, `flexoki-light` (light). A theme's `mode` drives `{{ is_light }}` in templates, Zed's `theme.mode` and slot, and the macOS appearance (`dark-mode` CLI, else `osascript`; off with `dotfiles toggle appearance off` or `DOTFILES_NO_APPEARANCE=1`).

Palette keys (same schema as Omarchy themes): `mode`, `accent`, `selection`, `muted`, `background`, `dark_background`, `darker_background`, `lighter_background`, `foreground`, `dark_foreground`, `light_foreground`, `bright_foreground`, `black`, `red`, `green`, `yellow`, `blue`, `magenta`, `cyan`, `orange`, `purple`, `bright_*`. Missing keys are derived (accent from blue, muted from a fg/bg blend, bright shades 20% toward white).

## Do

- Change a colour: edit `themes/<name>/colors.toml`, then `dotfiles theme <name>`.
- Change how one app uses colours: edit `themes/_templates/<app>.tpl` (affects every theme), then re-apply.
- Hand-tune one app for one theme: copy the rendered file to `themes/<name>/overrides/<file>`, edit, re-apply.
- Add a theme: `dotfiles add-theme <name>` (or paste an Omarchy `colors.toml`), fill `theme.conf`, put the lazy.nvim spec in `nvim/<name>-theme.lua` (or leave it out: the palette-driven `dotfiles` colorscheme is used), `dotfiles theme <name>`.
- Install someone else's theme: `dotfiles theme install <git-url>` (clones to `~/.config/dotfiles/themes/<name>/`; a cloned theme contributes colour data only, its `nvim/*.lua`, code-capable overrides and symlinks are dropped at staging). `dotfiles theme remove <name>` undoes it.
- See the active theme: `cat ~/.dotfiles-theme` or `dotfiles health` (Theme Assets section).
- Desktop picture: `dotfiles theme bg next` cycles `themes/<name>/backgrounds/`, `~/.config/dotfiles/backgrounds/<name>/`, then the gradient generated from the palette; `dotfiles theme bg set <image>` pins one. `dotfiles toggle background off` to leave the desktop alone.

## Do not

- Put a hex colour in `ghostty/config`, `zellij/config.kdl`, `sketchybarrc`, `bordersrc`, `starship.toml`, `lazygit/config.yml`, `wezterm.lua`, `.gitconfig`. The theme switch will not know about it and the next theme will look wrong.
- Edit `~/.config/ghostty/theme.generated`, `~/.config/zellij/themes/dotfiles.kdl`, `~/.config/sketchybar/colors.sh`, `~/.config/borders/colors.sh`, or anything under `~/.local/state/dotfiles/`.
- Change `theme "dotfiles"` in `zellij/config.kdl` or `palette = "dotfiles"` in the starship template; those names are fixed on purpose.

## After applying

- New shell for the prompt and fzf (`exec zsh`), `cmd+shift+,` in Ghostty, restart Neovim (`:Lazy sync` if the theme plugin is new), Zellij and WezTerm on next launch. sketchybar reloads by itself.
- `dotfiles theme` prints manual steps for Slack, Chrome, Zen, Telegram, Raycast.
- Automation on theme change: scripts in `~/.config/dotfiles/hooks/theme-set.d/` run with the theme name as `$1`.

## Fonts

Fonts are not themed. Ghostty: `font-family`/`font-size` in `~/.config/ghostty/config`. WezTerm: `config.font` in `~/.wezterm.lua`. Zed: `buffer_font_family` in `~/.config/zed/settings.json`. sketchybar: `icon.font`/`label.font` in `sketchybarrc`. Fonts are installed from the Brewfile `fonts` group.
