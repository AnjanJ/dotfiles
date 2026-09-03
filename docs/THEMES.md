# Theming

Choose between **[Tokyo Night](https://github.com/folke/tokyonight.nvim)** (dark blue), **[Aura Dark](https://github.com/daltonmenezes/aura-theme)** (deep purple), or **[Catppuccin Mocha](https://github.com/catppuccin/catppuccin)** (warm pastels) during install, and switch anytime after. Two light themes, **Catppuccin Latte** and **[Flexoki Light](https://stephango.com/flexoki)**, switch macOS to light appearance along with every app.

The theme is applied across **22 apps**: 17 configured automatically, 5 with manual one-click instructions.

| Auto-configured (17) | Manual — links provided (5) |
|----------------------|------------------------------|
| Ghostty, WezTerm, Zellij, Starship, Neovim, Zed, VS Code, Warp, bat, git-delta, fzf, lazygit, lsd, borders, sketchybar, Claude Code, Xcode/Sublime Text (when installed and the theme ships a file for them) | Slack, Chrome, Zen/Firefox, Telegram, Raycast |

Xcode and Sublime Text are the two exceptions to "automatic": they get a file only when the app is installed *and* the theme carries `xcode/*.xccolortheme` or `sublime-text/*.tmTheme`. Of the bundled themes only `aura` does; the others leave both editors untouched.

> Browse the full galleries: [Tokyo Night](https://github.com/folke/tokyonight.nvim#readme) | [Aura Dark](https://github.com/daltonmenezes/aura-theme#readme) | [Catppuccin](https://github.com/catppuccin/catppuccin#-showcase)

## How it works: one palette, rendered everywhere

A theme is a single palette file. `dotfiles theme <name>` renders it through a set of templates and every app reads the result.

```
themes/
├── _templates/               # one template per rendered file ({{ accent }}, {{ mix bg fg 10% }} …)
│   ├── ghostty.tpl  ghostty-font.tpl  wezterm.lua.tpl  wezterm-font.lua.tpl  zellij.kdl.tpl
│   ├── starship.toml.tpl  lazygit.yml.tpl  nvim.lua.tpl  claude.json.tpl  fzf.zsh.tpl
│   └── lsd.yaml.tpl  bat.conf.tpl  sketchybar-colors.sh.tpl  borders-colors.sh.tpl  delta.gitconfig.tpl
├── _shared/
│   ├── nvim/dotfiles-theme.lua   # lazy.nvim spec used when a theme has no nvim/ spec of its own
│   └── nvim-dotfiles-theme/      # the palette-driven `dotfiles` colorscheme it loads
└── <name>/
    ├── colors.toml               # THE palette (same keys as Omarchy themes)
    ├── theme.conf                # what a palette can't say: editor theme names, bat theme
    ├── manual-instructions.txt   # printed after applying: the Slack, browser, Telegram, Raycast steps
    ├── nvim/<name>-theme.lua     # optional lazy.nvim spec; without one the _shared fallback is used
    ├── overrides/                # optional hand-written file replacing a template's output
    ├── backgrounds/              # optional desktop pictures (a gradient is generated otherwise)
    └── bat/ zed/ warp/ xcode/ sublime-text/ telegram/   # optional per-app assets
```

The two `*-font.tpl` templates carry only `{{ font_family }}` (see Fonts below), so a font change and a theme change go through the same render. The per-app asset directories are: `bat/*.tmTheme` (installed into `~/.config/bat/themes/`, cache rebuilt), `zed/*.json` (copied to `~/.config/zed/themes/`, for themes Zed's registry lacks), `warp/*.yaml` (the file named by `warp_custom_file` in `theme.conf`, copied to `~/.warp/themes/`), `xcode/*.xccolortheme` and `sublime-text/*.tmTheme` (copied only when that app is installed). Those five plus `backgrounds/` are the directories a cloned theme may contribute. `telegram/` (only `aura` has one) is never copied anywhere; `manual-instructions.txt` points at it.

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
| Generated from a tracked base | Zed and VS Code: `settings.base.json` is tracked, `settings.json` is rendered next to it with the theme name filled in (Zed's `theme.mode` and slot, VS Code's `workbench.colorTheme` placeholder), and anything changed in the editor's own settings UI is copied back into the base on the next `dotfiles theme` |
| Own settings edited, best-effort | Warp (`defaults write`), bat (`~/.config/bat/config` + custom `.tmTheme`), lsd, Claude Code (`~/.claude/themes/dotfiles.json`), Xcode and Sublime Text (only when installed and the theme ships `xcode/` or `sublime-text/` files) |

## Fonts

The monospace family is one setting, not per theme: `dotfiles font set "JetBrainsMono Nerd Font"` records it in `~/.local/state/dotfiles/font`, re-renders the active theme so Ghostty (`font-family` in `font.generated`, included by its config), WezTerm (`wezterm-font.lua`), Zed (`buffer_font_family`) and VS Code (`editor.fontFamily`) pick it up, and fires the `font-set` hook. `dotfiles font list` shows the installed monospace families (fontconfig), `dotfiles font reset` returns to Fira Code. Sizes stay in each app's config.

## Palettes

| | Tokyo Night | Aura Dark | Catppuccin Mocha | Catppuccin Latte | Flexoki Light |
|---|-----------|-----------|-----------------|-----------------|---------------|
| **Mode** | dark | dark | dark | light | light |
| **Background** | `#1a1b26` | `#15141b` | `#1e1e2e` | `#eff1f5` | `#fffcf0` |
| **Foreground** | `#c0caf5` | `#edecee` | `#cdd6f4` | `#4c4f69` | `#100f0f` |
| **Accent** | `#7aa2f7` blue | `#a277ff` purple | `#b4befe` lavender | `#1e66f5` blue | `#205ea6` blue |
| **Success** | `#9ece6a` green | `#61ffca` green | `#a6e3a1` green | `#40a02b` green | `#66800b` green |
| **Error** | `#f7768e` red | `#ff6767` red | `#f38ba8` red | `#d20f39` red | `#af3029` red |
| **Warning** | `#e0af68` yellow | `#ffca85` orange | `#f9e2af` yellow | `#df8e1d` yellow | `#ad8301` yellow |

The full palette for each theme is in `themes/<name>/colors.toml`.

## Switching

```bash
dotfiles theme tokyo-night       # Switch to Tokyo Night
dotfiles theme aura              # Switch to Aura Dark
dotfiles theme catppuccin        # Switch to Catppuccin Mocha
dotfiles theme catppuccin-latte  # Light: Catppuccin Latte
dotfiles theme flexoki-light     # Light: Flexoki
```

Then reload what is already open: a new shell for the prompt and fzf, `cmd+shift+,` in Ghostty, restart Neovim (and `:Lazy sync` if the theme plugin is new). Zellij and WezTerm pick the theme up on next launch. The command ends by printing the manual steps for Slack, browsers, Telegram, and Raycast.

## Light themes and macOS appearance

Every palette declares `mode = "light"` or `"dark"` (derived from the background luminance when missing). The mode reaches every template as `{{ mode }}`, `{{ theme_type }}` and `{{ is_light }}`: lazygit gets `lightTheme`, Claude Code gets its `base`, and the rendered directory records it in `theme.mode`. Zed's `theme.mode` is pinned to it and the matching `theme.light` / `theme.dark` slot is filled, so the other slot keeps its last value.

`dotfiles theme` also switches macOS between light and dark appearance to match, using the `dark-mode` CLI from the Brewfile (instant, no permission dialog) or, without it, System Events through `osascript` under a 5-second watchdog (macOS asks once to allow Automation for your terminal). Leave the appearance alone with `dotfiles toggle appearance off`; scripts and tests can set `DOTFILES_NO_APPEARANCE=1`.

The light themes keep dark ANSI black and grey white slots (the values Ghostty ships for the same themes), so `ls` and prompts stay readable on a pale background. Their editor themes come from extensions listed in the Brewfile (`catppuccin.catppuccin-vsc`, `shadesofbuntu.flexoki-light`) and Zed's `auto_install_extensions` (`catppuccin`, `flexoki-themes`).

## Backgrounds

Every theme gets a desktop picture. `dotfiles theme` renders a gradient from the palette (background toward the accent, darkening downward) into `~/.local/state/dotfiles/current/theme/background.png`, so no image has to live in git; drop your own into `themes/<name>/backgrounds/` (tracked) or `~/.config/dotfiles/backgrounds/<name>/` (`dotfiles theme bg dir` opens it, never committed) and they come first.

```bash
dotfiles theme bg next          # cycle: theme images, your images, the generated gradient
dotfiles theme bg set ~/pic.jpg # use a specific image
dotfiles theme bg list          # candidates, * marks the current one
dotfiles theme bg current
```

The choice is a symlink at `~/.local/state/dotfiles/current/background`. A theme *switch* moves to that theme's next candidate; re-applying the same theme (`dotfiles sync`) leaves whatever you set alone. The desktop is set with [desktoppr](https://github.com/scriptingosx/desktoppr) from the Brewfile (a pkg, so the first `brew bundle` asks for sudo) or, without it, System Events through `osascript` under a 5-second watchdog. `dotfiles toggle background off` keeps the desktop alone while still recording the choice; scripts and tests set `DOTFILES_NO_BACKGROUND=1`.

## Installing a theme from a git repository

```bash
dotfiles theme install https://github.com/someone/omarchy-nord-theme   # clone, then apply
dotfiles theme remove nord                                             # undo (switch away first)
dotfiles theme remove --list
dotfiles theme update                                                  # fast-forward every cloned theme, re-apply if the active one moved
dotfiles theme preview nord                                            # palette swatches (also the preview pane in `dotfiles menu theme`)
```

The repo lands in `~/.config/dotfiles/themes/<name>/` (the name is the repo's, minus an `omarchy-`/`dotfiles-` prefix and a `-theme` suffix) and must carry a `colors.toml`; an Omarchy theme without a `theme.conf` gets a minimal one (editors keep their current theme, bat uses `ansi`). Themes you write by hand can live in the same directory: any `~/.config/dotfiles/themes/<name>/theme.conf` is discovered next to the repo's `themes/*/theme.conf` (`scripts/theme-utils.sh`), and a directory without a `.git` counts as trusted, so its Neovim spec and overrides are used just like a repo theme's. A repo theme with the same name wins.

A cloned theme is a stranger's repo, so `dotfiles theme` stages only its colour data, the way Omarchy does: `colors.toml`, `backgrounds/`, `bat/*.tmTheme`, `zed/*.json`, `warp/*.yaml`, `xcode/`, `sublime-text/`, and the `claude.json`, `lsd.yaml` and `zellij.kdl` overrides. Everything that can run code is dropped at staging and named in a warning: `nvim/*.lua` (Neovim loads it), `theme.conf` as code (it is parsed for the known `key="value"` lines instead of sourced), every other override (a Ghostty `command`, WezTerm Lua, Starship custom modules, lazygit custom commands, the sourced fzf/sketchybar/borders shell, delta's git config), and symlinks at any depth. Filtering at staging rather than at clone time means a file the theme gains later through `git pull` is filtered too. Neovim uses the palette-driven `dotfiles` colorscheme (`themes/_shared/nvim/dotfiles-theme.lua`, a base16 scheme built from the rendered palette), which also serves any theme that has no `nvim/` spec of its own.

## Adding a theme

```bash
dotfiles add-theme my-theme   # scaffolds themes/my-theme/
```

1. Put the palette in `colors.toml`. Only `background`, `foreground` and the eight base colours are required; `accent`, `muted`, `selection`, the `bright_*` shades and the background/foreground steps are derived when missing.
2. Fill in `theme.conf`: `nvim_colorscheme`, `bat_theme` and `delta_theme` are required; `zed_theme` and `vscode_theme` may stay empty (the editor keeps its theme); `warp_theme` and `warp_custom_file` are optional.
3. Optional: put the colorscheme's lazy.nvim spec in `nvim/my-theme-theme.lua` (the scaffold leaves a stub there; the file name comes from `nvim_plugin_file`). Delete the stub instead and `dotfiles theme` falls back to the palette-driven `dotfiles` colorscheme from `themes/_shared/`, with a warning naming the missing file.
4. `dotfiles theme my-theme`.

Themes are auto-discovered from `themes/*/theme.conf` in the repo and then `~/.config/dotfiles/themes/*/theme.conf`; no code or completion changes are needed.

**Importing an Omarchy palette.** The `colors.toml` schema is the same one [Omarchy](https://github.com/basecamp/omarchy) uses, so any of its bundled themes (`themes/<name>/colors.toml` in that repo, MIT licensed) can be pasted straight in. You still supply `theme.conf`; a Neovim spec is optional.

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
| `{{ font_family }}` | the family from `dotfiles font` (`~/.local/state/dotfiles/font`, default `Fira Code`); not a `theme.conf` key |
| `{{ mode }}`, `{{ theme_type }}`, `{{ is_light }}` | `dark`/`light`, the same again, `true`/`false` (from `mode`, else from background luminance) |

An unresolved token fails the render, and the previous theme stays active.

## Hooks

Scripts in `~/.config/dotfiles/hooks/theme-set.d/` run after every theme switch with the theme name as `$1`. Use them for anything the repo does not automate: setting the macOS wallpaper, pushing the Slack colour string to the clipboard, restarting an app.
