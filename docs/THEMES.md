# Theming

Choose between **[Tokyo Night](https://github.com/folke/tokyonight.nvim)** (dark blue), **[Aura Dark](https://github.com/daltonmenezes/aura-theme)** (deep purple), or **[Catppuccin Mocha](https://github.com/catppuccin/catppuccin)** (warm pastels) during install, and switch anytime after.

The theme is applied across **21 apps**: 16 configured automatically, 5 with manual one-click instructions.

| Auto-configured (16) | Manual — links provided (5) |
|----------------------|------------------------------|
| Neovim, Ghostty, Zellij, Starship, Zed, VS Code, Warp, bat, git-delta, fzf, lazygit, borders, sketchybar, Xcode, Sublime Text, lsd | Slack, Chrome, Firefox, Telegram, Raycast |

If any of the four core steps (Ghostty, Neovim, Zellij, Starship) fails, every config is rolled back. The remaining apps are applied best-effort afterwards and report individually.

> Browse the full galleries: [Tokyo Night](https://github.com/folke/tokyonight.nvim#readme) | [Aura Dark](https://github.com/daltonmenezes/aura-theme#readme) | [Catppuccin](https://github.com/catppuccin/catppuccin#-showcase)

## Palettes

| | Tokyo Night | Aura Dark | Catppuccin Mocha |
|---|-----------|-----------|-----------------|
| **Background** | `#1a1b26` | `#15141b` | `#1e1e2e` |
| **Foreground** | `#c0caf5` | `#edecee` | `#cdd6f4` |
| **Primary accent** | `#7aa2f7` blue | `#a277ff` purple | `#b4befe` lavender |
| **Secondary** | `#bb9af7` purple | `#61ffca` green | `#94e2d5` teal |
| **Success** | `#9ece6a` green | `#61ffca` green | `#a6e3a1` green |
| **Error** | `#f7768e` red | `#ff6767` red | `#f38ba8` red |
| **Warning** | `#e0af68` yellow | `#ffca85` orange | `#f9e2af` yellow |

## Switching

```bash
dotfiles theme tokyo-night  # Switch to Tokyo Night
dotfiles theme aura         # Switch to Aura Dark
dotfiles theme catppuccin   # Switch to Catppuccin Mocha
```

This updates the 16 auto-configured apps, then prints instructions for Slack, browsers, Telegram, and Raycast.

## Adding a new theme

Themes are auto-discovered — adding one is just creating a `themes/<name>/` directory with a `theme.conf` registry file; no code changes needed.

```bash
dotfiles add-theme my-theme   # Scaffolds the full directory structure
```

Each theme directory contains per-app config files (see `themes/aura/` for a complete example) plus:

- `theme.conf` — the registry mapping theme values to each app (read by `scripts/apply-theme.sh`)
- `manual-instructions.txt` — printed after apply, for the apps that need a manual step
