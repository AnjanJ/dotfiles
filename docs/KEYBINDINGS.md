# Keybindings

All the muscle memory in one place. For a printable cheat sheet, see [QUICK_REFERENCE.md](../QUICK_REFERENCE.md).

## Aerospace (window management)

Uses `Ctrl+Shift` for international keyboard compatibility (DHH-inspired).

| Key | Action |
|-----|--------|
| `Ctrl+Shift+H/J/K/L` | Focus window (vim-style navigation) |
| `Ctrl+Alt+H/J/K/L` | Move window |
| `Ctrl+Shift+1-9` | Switch to workspace 1-9 |
| `Ctrl+Alt+1-9` | Move window to workspace 1-9 |
| `Ctrl+Shift+Tab` | Toggle between last two workspaces |
| `Ctrl+Shift+/` | Toggle layout (tiles/accordion) |
| `Ctrl+Shift+-` | Decrease window size |
| `Ctrl+Shift+=` | Increase window size |

### App launchers (workspace-aware)

These are my personal app/workspace assignments — edit `.config/aerospace/aerospace.toml` to make them yours.

| Key | App | Workspace |
|-----|-----|-----------|
| `Ctrl+Shift+C` | Chrome (work) | 1 |
| `Ctrl+Shift+Z` | Zed editor | 2 |
| `Ctrl+Shift+W` | Ghostty terminal | 3 |
| `Ctrl+Shift+F` | Firefox (personal) | 5 |
| `Ctrl+Shift+G` | Ghostty terminal | 7 |
| `Ctrl+Shift+O` | Obsidian (PKM) | 8 |
| `Ctrl+Shift+P` | 1Password | 9 |

### Browser window cycling (across all workspaces)

| Key | Action |
|-----|--------|
| `Ctrl+Shift+N` | Next Chrome window |
| `Ctrl+Shift+B` | Previous Chrome window |
| `Alt+Shift+N` | Next Firefox window |
| `Alt+Shift+B` | Previous Firefox window |

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
