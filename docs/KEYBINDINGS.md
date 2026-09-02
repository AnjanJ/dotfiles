# Keybindings

All the muscle memory in one place. For a printable cheat sheet, see [QUICK_REFERENCE.md](../QUICK_REFERENCE.md).

## Aerospace (window management)

Uses `Ctrl+Shift` for international keyboard compatibility (DHH-inspired). Source of truth: `.config/aerospace/aerospace.toml`.

| Key | Action |
|-----|--------|
| `Ctrl+Shift+H/J/K/L` | Focus window (vim-style navigation) |
| `Ctrl+Alt+H/J/K/L` | Move window |
| `Ctrl+Shift+1-9` | Switch to workspace 1-9 |
| `Ctrl+Alt+1-9` | Move window to workspace 1-9 |
| `Ctrl+Shift+0` / `Ctrl+Alt+0` | Cycle forward / backward through overflow workspaces 10-12 |
| `Ctrl+Shift+Tab` | Toggle between last two workspaces |
| `Ctrl+Alt+Tab` | Move current workspace to next monitor |
| `Ctrl+Shift+/` | Tiles layout |
| `Ctrl+Shift+,` | Accordion layout |
| `Ctrl+Shift+-` | Decrease window size |
| `Ctrl+Shift+=` | Increase window size |
| `Ctrl+Shift+;` | Enter service mode (see below) |

### Multi-monitor

| Key | Action |
|-----|--------|
| `Alt+Shift+M` | Focus next monitor |
| `Alt+Shift+H` / `Alt+Shift+L` | Focus monitor left / right |
| `Ctrl+Shift+Cmd+M` | Move window to next monitor |
| `Ctrl+Shift+Cmd+H` / `Ctrl+Shift+Cmd+L` | Move window to monitor left / right |

### Service mode (`Ctrl+Shift+;` first)

| Key | Action |
|-----|--------|
| `Esc` | Reload config and return to main mode |
| `R` | Flatten workspace tree (reset layout) |
| `F` | Toggle floating / tiling for the focused window |
| `Backspace` | Close all windows but the current one |
| `Ctrl+Alt+H/J/K/L` | Join with the window in that direction |
| `Up` / `Down` | Volume up / down |
| `Shift+Down` | Mute |

### App launchers (workspace-aware)

These are my personal app/workspace assignments — edit `.config/aerospace/aerospace.toml` to make them yours. Each app lands on its home workspace via `[[on-window-detected]]` rules, so the shortcut only launches; it never needs to switch workspace first.

| Key | App | Workspace |
|-----|-----|-----------|
| `Ctrl+Shift+W` | Warp terminal | 1 |
| `Ctrl+Shift+X` | Zen browser | 2 |
| `Ctrl+Shift+C` | Chrome (new window) | 3 |
| `Ctrl+Shift+Z` | Zed editor | 4 |
| `Ctrl+Shift+V` | VS Code | 4 |
| `Ctrl+Shift+M` | Proton Mail | 5 |
| `Ctrl+Shift+O` | Obsidian | 6 |
| `Ctrl+Shift+S` | Slack (floating) | 6 |
| `Ctrl+Shift+E` | Ente Auth (floating) | 6 |
| `Ctrl+Shift+A` | Claude (floating) | 7 |
| `Ctrl+Shift+T` | ChatGPT (floating) | 7 |
| `Ctrl+Shift+P` | 1Password (floats on the current workspace) | — |
| `Ctrl+Shift+Enter` | Finder | — |
| `Ctrl+Shift+R` | Re-launch the whole startup session (`scripts/startup-apps.sh`) | — |

Workspaces 8 and 9 are free.

### Browser window cycling (across all workspaces)

| Key | Action |
|-----|--------|
| `Ctrl+Shift+N` | Next Chrome window |
| `Ctrl+Shift+B` | Previous Chrome window |
| `Alt+Shift+N` | Next Zen window |
| `Alt+Shift+B` | Previous Zen window |

## Neovim (leader: `Space`)

| Key | Action |
|-----|--------|
| `<Leader>ff` | Find files (Telescope) |
| `<Leader>fw` | Find word (grep) |
| `<Leader>fb` | Find buffers |
| `<Leader>ha` | Harpoon: add file |
| `Ctrl+H/J/K/L` | Harpoon: jump to marks 1-4 |
| `gd` | Go to definition |
| `gr` | Find references |
| `<Leader>la` | Code actions |
| `K` | Hover documentation |
| `<Leader>rc` | Rails: controller |
| `<Leader>rm` | Rails: model |
| `<Leader>rv` | Rails: view |
| `<Leader>rs` | Rails: spec |

## Zellij

| Key | Action |
|-----|--------|
| `Ctrl+O` | Enter command mode (shows options) |
| `Ctrl+G` | Lock mode (pass keys to terminal) |
| `Alt+H/J/K/L` | Navigate panes |
| `Ctrl+Q` | Quit Zellij |

### Layouts (pre-configured via aliases)

| Alias | Layout | Tabs |
|-------|--------|------|
| `zr` | Rails | editor, server (rails s + console), tests, terminal |
| `zp` | Phoenix | editor, server (phx.server + iex), tests, terminal |
| `zw` | Work | editor, server (two panes), terminal |

## Customizing

- **Aerospace**: `.config/aerospace/aerospace.toml`
- **Zellij**: `.config/zellij/config.kdl`
- **Neovim**: `.config/nvim/lua/plugins/*.lua`
