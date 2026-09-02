# Theming

Choose between **[Tokyo Night](https://github.com/folke/tokyonight.nvim)** (dark blue), **[Aura Dark](https://github.com/daltonmenezes/aura-theme)** (deep purple), or **[Catppuccin Mocha](https://github.com/catppuccin/catppuccin)** (warm pastels) during install, and switch anytime after.

The theme is applied across **22 apps**: 17 configured automatically, 5 with manual one-click instructions.

| Auto-configured (17) | Manual — links provided (5) |
|----------------------|------------------------------|
| Ghostty, WezTerm, Zellij, Starship, Neovim, Zed, VS Code, Warp, bat, git-delta, fzf, lazygit, lsd, borders, sketchybar, Claude Code, Xcode/Sublime Text (when installed) | Slack, Chrome, Zen/Firefox, Telegram, Raycast |

> Browse the full galleries: [Tokyo Night](https://github.com/folke/tokyonight.nvim#readme) | [Aura Dark](https://github.com/daltonmenezes/aura-theme#readme) | [Catppuccin](https://github.com/catppuccin/catppuccin#-showcase)

## How it works: one palette, rendered everywhere

A theme is a single palette file. `dotfiles theme <name>` renders it through a set of templates and every app reads the result.

```
themes/
├── _templates/               # one template per rendered file ({{ accent }}, {{ mix bg fg 10% }} …)
│   ├── ghostty.tpl  zellij.kdl.tpl  starship.toml.tpl  lazygit.yml.tpl  wezterm.lua.tpl
│   ├── nvim.lua.tpl  claude.json.tpl  fzf.zsh.tpl  lsd.yaml.tpl  bat.conf.tpl
│   └── sketchybar-colors.sh.tpl  borders-colors.sh.tpl  delta.gitconfig.tpl
└── <name>/
    ├── colors.toml           # THE palette (same keys as Omarchy themes)
    ├── theme.conf            # what a palette can't say: editor theme names, bat theme
    ├── nvim/<name>-theme.lua # lazy.nvim plugin spec for the colorscheme
    ├── overrides/            # optional hand-written file replacing a template's output
    └── bat/ zed/ warp/ …     # optional per-app assets (custom .tmTheme, Zed theme JSON)
```

Applying a theme:

1. Renders every template into a staging directory, `~/.local/state/dotfiles/current/next-theme/`. A file in `overrides/` is copied first and the matching template is skipped.
2. Swaps the staging directory into `~/.local/state/dotfiles/current/theme/` in one move, so apps never see a half-rendered theme. If any template fails to render, the previous theme stays active.
3. Copies rendered files to the few apps that cannot read from there, then retints what is running (sketchybar reloads).
4. Fires the `theme-set` hook (`~/.config/dotfiles/hooks/theme-set.d/*`) with the theme name.

Nothing tracked in git changes when you switch themes. Each app gets its colours one of three ways:

| Mechanism | Apps |
|-----------|------|
| Reads the rendered file directly | Starship (`$STARSHIP_CONFIG`), lazygit (`$LG_CONFIG_FILE`), WezTerm (`dofile`), Neovim (`dofile` in `astroui.lua` and `plugins/theme.lua`), git-delta (`[include]`), fzf (`~/.zshrc-theme-env`) |
| Gitignored generated copy inside its config dir | Ghostty (`theme.generated`), Zellij (`themes/dotfiles.kdl`), sketchybar and borders (`colors.sh`) |
| Own settings edited, best-effort | Zed and VS Code (theme name), Warp (`defaults write`), bat (`~/.config/bat/config` + custom `.tmTheme`), lsd, Claude Code (`~/.claude/themes/dotfiles.json`), Xcode, Sublime Text |

## Palettes

| | Tokyo Night | Aura Dark | Catppuccin Mocha |
|---|-----------|-----------|-----------------|
| **Background** | `#1a1b26` | `#15141b` | `#1e1e2e` |
| **Foreground** | `#c0caf5` | `#edecee` | `#cdd6f4` |
| **Accent** | `#7aa2f7` blue | `#a277ff` purple | `#b4befe` lavender |
| **Success** | `#9ece6a` green | `#61ffca` green | `#a6e3a1` green |
| **Error** | `#f7768e` red | `#ff6767` red | `#f38ba8` red |
| **Warning** | `#e0af68` yellow | `#ffca85` orange | `#f9e2af` yellow |

The full palette for each theme is in `themes/<name>/colors.toml`.

## Switching

```bash
dotfiles theme tokyo-night  # Switch to Tokyo Night
dotfiles theme aura         # Switch to Aura Dark
dotfiles theme catppuccin   # Switch to Catppuccin Mocha
```

Then reload what is already open: a new shell for the prompt and fzf, `cmd+shift+,` in Ghostty, restart Neovim (and `:Lazy sync` if the theme plugin is new). Zellij and WezTerm pick the theme up on next launch. The command ends by printing the manual steps for Slack, browsers, Telegram, and Raycast.

## Adding a theme

```bash
dotfiles add-theme my-theme   # scaffolds themes/my-theme/
```

1. Put the palette in `colors.toml`. Only `background`, `foreground` and the eight base colours are required; `accent`, `muted`, `selection`, the `bright_*` shades and the background/foreground steps are derived when missing.
2. Fill in `theme.conf`: the Neovim colorscheme name, the Zed and VS Code theme names, and the bat/delta syntax theme.
3. Put the colorscheme's lazy.nvim spec in `nvim/my-theme-theme.lua`.
4. `dotfiles theme my-theme`.

Themes are auto-discovered from `themes/*/theme.conf`; no code or completion changes are needed.

**Importing an Omarchy palette.** The `colors.toml` schema is the same one [Omarchy](https://github.com/basecamp/omarchy) uses, so any of its bundled themes (`themes/<name>/colors.toml` in that repo, MIT licensed) can be pasted straight in. You still supply `theme.conf` and the Neovim spec.

**Hand-tuning one app.** If a rendered file is not quite right for a theme, put the finished file in `themes/<name>/overrides/<rendered-name>` (for example `overrides/ghostty`). It replaces that template's output for that theme only. Aura does this for Ghostty to keep its purple selection highlight.

## Template tokens

Templates are plain config files with `{{ … }}` placeholders, rendered by `scripts/theme-render.sh` (bash + awk, no dependencies):

| Token | Output |
|-------|--------|
| `{{ accent }}` | `#7aa2f7` |
| `{{ accent_strip }}` | `7aa2f7` |
| `{{ accent_rgb }}` | `122,162,247` |
| `{{ accent_argb }}` | `0xff7aa2f7` (sketchybar, borders) |
| `{{ mix background foreground 10% }}` | blend, with `mix_strip` / `mix_rgb` / `mix_argb` variants |
| `{{ theme_name }}`, `{{ nvim_colorscheme }}`, `{{ bat_theme }}` … | any `theme.conf` key |
| `{{ mode }}`, `{{ is_light }}` | `dark`/`light`, `true`/`false` (from `mode`, else from background luminance) |

An unresolved token fails the render, and the previous theme stays active.

## Hooks

Scripts in `~/.config/dotfiles/hooks/theme-set.d/` run after every theme switch with the theme name as `$1`. Use them for anything the repo does not automate: setting the macOS wallpaper, pushing the Slack colour string to the clipboard, restarting an app.
