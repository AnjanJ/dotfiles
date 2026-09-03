---
name: dotfiles
description: >
  REQUIRED for changes to this Mac's shell, terminal, window manager, prompt,
  editor or theme setup. Use when editing anything under ~/.config/ (aerospace,
  ghostty, zellij, nvim, lazygit, sketchybar, borders, wezterm, zed), ~/.zshrc*,
  ~/.gitconfig, the Brewfile, or when asked about themes, colours, keybindings,
  workspaces, packages, `dotfiles` commands, health checks or machine setup.
  Excludes developing the dotfiles repo itself (see AGENTS.md in the repo).
---

# Dotfiles Skill

This machine is configured by the dotfiles repo at `~/code/dotfiles` (fall back to `~/dotfiles`; `dotfiles dir` prints it). Configs are **symlinked** into `$HOME`, so editing `~/.config/aerospace/aerospace.toml` edits the repo file and takes effect immediately.

## When this skill MUST be used

- Editing any file under `~/.config/{aerospace,ghostty,zellij,nvim,lazygit,sketchybar,borders,wezterm,zed,mise}/`, `~/.zshrc*`, `~/.gitconfig`, `~/.wezterm.lua`
- Themes, colours, fonts, prompt appearance
- Keybindings, workspaces, window rules
- Installing or removing packages (the Brewfile is the source of truth)
- Running `dotfiles …` commands, health checks, sync, update

**If you are about to edit a config file in `~/.config/` or `~/.zshrc*`, read the matching guide first:**

- [`theming.md`](theming.md) — how colours flow from `colors.toml` to every app; what never to edit
- [`aerospace.md`](aerospace.md) — window manager bindings, workspaces, app rules, the generated cheatsheet
- [`commands.md`](commands.md) — the `dotfiles` CLI, toggles, hooks, migrations, health

## Critical rules

1. **Never edit generated files.** `~/.local/state/dotfiles/**`, `~/.config/ghostty/theme.generated`, `~/.config/zellij/themes/dotfiles.kdl`, `~/.config/sketchybar/colors.sh`, `~/.config/borders/colors.sh`, and the generated block in `docs/KEYBINDINGS.md` are overwritten by `dotfiles theme` / `dotfiles keys --update`. Change the source (`themes/<name>/colors.toml`, `aerospace.toml`) instead.
2. **Never put a hex colour in a tracked config.** Colours live in `themes/<name>/colors.toml`; apps read the rendered theme. See `theming.md`.
3. **Packages go in the Brewfile**, under the right `# @group`. `brew install` alone is undone by `dotfiles cleanup --force`.
4. **Validate after editing:** `aerospace reload-config`, `ghostty +validate-config` (binary in `/Applications/Ghostty.app/Contents/MacOS/`), `zellij setup --check`, `sketchybar --reload`, `nvim --headless +qa`, then `dotfiles health`.
5. **Do not run `dotfiles update` or `dotfiles uninstall`** without the user asking; `update` upgrades Homebrew and may commit and push to GitHub. `dotfiles sync` and `dotfiles health` are safe.
6. **Do not commit or push** in `~/code/dotfiles` unless asked. The repo's own `AGENTS.md` covers development conventions if the user wants repo changes.

## Command discovery

```bash
dotfiles                      # every command with a one-line summary
dotfiles commands --json      # machine-readable listing
dotfiles <command> --help     # usage from the command's metadata
cat "$(dotfiles dir)/bin/dotfiles-<command>"   # read the source
```

Common ones: `dotfiles health`, `dotfiles sync`, `dotfiles theme <name>`, `dotfiles keys`, `dotfiles toggle <flag>`, `dotfiles doctor`, `dotfiles migrate --pending`, `dotfiles backup`.

## Where things live

| Area | File(s) |
|------|---------|
| Window manager | `~/.config/aerospace/aerospace.toml` (+ `scripts/` for session restore and window cycling) |
| Status bar | `~/.config/sketchybar/sketchybarrc`, `plugins/*.sh` |
| Terminal | `~/.config/ghostty/config`, `~/.wezterm.lua`, `~/.config/zellij/config.kdl` + `layouts/` |
| Shell | `~/.zshrc` (env, core), `~/.zshrc-terminal-enhancements` (fzf, zoxide, aliases), `~/.zshrc-dhh-additions` (Rails), `~/.zshrc-elixir-additions` (Phoenix), `~/.zshrc.local` (machine-only, untracked) |
| Prompt | template `themes/_templates/starship.toml.tpl` in the repo (rendered per theme; `$STARSHIP_CONFIG` points at the result) |
| Editors | `~/.config/nvim/lua/plugins/*.lua` (AstroNvim), `.config/zed/settings.base.json` and `.config/vscode/settings.base.json` in the repo (the `settings.json` next to each is generated with the theme; `dotfiles theme` copies in-app edits back into the base) via `~/Library/Application Support/Code/User/` |
| Git | `~/.gitconfig` (tracked), `~/.gitconfig-work` (untracked, from `dotfiles work setup`) |
| Runtimes | `~/.config/mise/config.toml` |
| Packages | `Brewfile` in the repo |
| Themes | `themes/<name>/colors.toml`, `theme.conf`, `overrides/` |

Machine-only overrides that should not be committed: `~/.zshrc.local`, `~/.zshrc-work`, `~/.gitconfig-work`.

## Example requests

- "Switch to Tokyo Night" → `dotfiles theme tokyo-night`
- "Change the wallpaper to match" → `dotfiles theme bg next` (or `dotfiles theme bg set <image>`; own images go in `~/.config/dotfiles/backgrounds/<theme>/`)
- "Go light" → `dotfiles theme catppuccin-latte` or `dotfiles theme flexoki-light` (macOS appearance follows; `dotfiles toggle appearance off` to stop that)
- "Make the accent colour purple in Catppuccin" → edit `accent` in `themes/catppuccin/colors.toml`, then `dotfiles theme catppuccin`
- "Add a shortcut to open Finder on Ctrl+Shift+F" → add `ctrl-shift-f = '''exec-and-forget open -a "Finder"'''` under `[mode.main.binding]` in `aerospace.toml` with a `# desc:` line above it, `aerospace reload-config`, then `dotfiles keys --update`
- "Stop the apps auto-launching at login" → `dotfiles toggle startup-apps off`
- "Install ripgrep-all" → add `brew "ripgrep-all"` to the right group in the Brewfile, then `brew bundle --file="$(dotfiles dir)/Brewfile"`
- "Something is off after pulling the repo" → `dotfiles sync`, then `dotfiles health`, then `dotfiles doctor` for the auto-fixable part
- "Run a script whenever the theme changes" → drop it in `~/.config/dotfiles/hooks/theme-set.d/`
