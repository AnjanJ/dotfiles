# 🚀 AJ's Dotfiles

> A complete macOS development environment for Ruby on Rails and Elixir/Phoenix development, themed with Tokyo Night everywhere.

## 💭 Philosophy

This setup is inspired by **DHH's Omakub** and his "**Everything in one place, everything just works**" philosophy. The goal is simple:

### Core Principles

1. **One Command Installation** - From zero to productive development environment in minutes
2. **Unified Theme** - Tokyo Night everywhere for visual consistency and reduced cognitive load
3. **Keyboard-First** - Vim motions, tiling windows, keyboard shortcuts for everything
4. **Modular Configuration** - Clean, organized configs that are easy to understand and modify
5. **Developer Ergonomics** - Tools chosen for speed, reliability, and joy of use

### The DHH/Omakub Influence

Like DHH's **[Omakub](https://omakub.org/)** for Ubuntu, this setup provides:
- **Opinionated but customizable** - Great defaults, easy to change
- **Battle-tested tools** - Used daily for professional Rails and Elixir development
- **Productivity-focused** - Everything configured to minimize friction
- **Beautiful aesthetics** - Because we stare at code all day

### Why This Stack?

| Tool | Why |
|------|-----|
| **Aerospace** | i3-style tiling for macOS — keyboard-driven, distraction-free |
| **Ghostty** | GPU-accelerated terminal, native macOS, modern |
| **Neovim + Zed** | Neovim with AstroNvim for terminal, Zed for GUI — both with full LSP |
| **zsh + Starship** | Fast, reliable shell with a beautiful prompt |
| **tmux + Zellij** | Session management with vim integration |
| **Tokyo Night** | Consistent theme everywhere — easy on eyes, used by thousands |

## ✨ Features

### 🎨 Unified Tokyo Night Theme
- **Neovim** - Beautiful syntax highlighting and statusline
- **tmux** - Themed status bar and pane borders
- **Zellij** - Custom Tokyo Night color scheme
- **Starship** - Matching prompt colors
- **Ghostty** - Terminal theme

### 🛠️ Development Tools
- **Ruby/Rails** - mise, ruby-lsp, RuboCop, RSpec tasks, ERB formatting
- **Elixir/Phoenix** - mise, elixir-ls, mix integration, tailwindcss-language-server
- **TypeScript/React** - prettier, eslint, auto-imports, inlay hints
- **Zig** - zls (auto-installed), build/test/run tasks, 26 snippets
- **Node.js** - mise, npm/yarn
- **Git** - lazygit, fugitive, gitsigns

### ⌨️ Productivity
- **Aerospace** - i3-like tiling window manager for macOS
- **Neovim + AstroNvim** - Modern Vim distribution with LSP, Treesitter, Telescope
- **tmux** - Session management, vim integration, persistent sessions
- **Zellij** - Modern alternative to tmux with on-screen hints
- **Starship** - Fast, customizable prompt (16x faster than Spaceship)
- **Harpoon** - Quick file navigation (ThePrimeagen workflow)

## 📦 What's Included

### Core Tools
- **Window Manager**: Aerospace (i3-like tiling for macOS)
- **Terminal**: Ghostty (GPU-accelerated)
- **Shell**: zsh with modular configuration
- **Prompt**: Starship
- **Multiplexers**: tmux + Zellij
- **Editors**: Neovim with AstroNvim, Zed (settings, snippets, tasks)
- **Version Control**: Git, lazygit, GitHub CLI
- **Custom Scripts**: `~/bin` (erb-lint-formatter, etc.)

### Development
- **mise** - Modern version manager (replaces rbenv, nvm, asdf)
- Ruby (latest via mise)
- Elixir + Erlang (latest)
- Node.js (latest)
- Python 3
- Zig
- Go, Rust (latest)
- PostgreSQL 14
- Redis

### CLI Utilities
- ripgrep, fd, fzf (fuzzy finding)
- bat (cat with syntax highlighting)
- eza (modern ls)
- tree (directory visualization)
- yazi (terminal file manager)
- lnav, tailspin (log viewers)

## 🎯 One-Command Installation

### Quick Install

```bash
git clone https://github.com/AnjanJ/dotfiles.git ~/dotfiles
cd ~/dotfiles
bash install.sh
```

That's it! The script will:
1. ✅ Install Homebrew (if not installed)
2. ✅ Install all packages from Brewfile
3. ✅ Backup your existing configurations
4. ✅ Create symlinks to dotfiles (shell, tmux, Neovim, Zed, ~/bin)
5. ✅ Set up tmux plugins
6. ✅ Configure Neovim
7. ✅ Configure Zed (settings, snippets, tasks)
8. ✅ Set up shell environment
9. ✅ Apply macOS defaults (optional)
10. ✅ Run health check (optional)

**💡 The install script is idempotent** - safe to run multiple times. Use `--force` to override existing configs.

```bash
bash install.sh --force  # Force reinstall everything
bash install.sh --help   # Show all options
```

### What Gets Installed

```
Installed Tools:
├── Window Management
│   └── Aerospace (i3-like tiling)
├── Terminals
│   └── Ghostty (GPU-accelerated)
├── Shell
│   ├── zsh (modular configuration)
│   └── Starship prompt
├── Multiplexers
│   ├── tmux (with 8 plugins)
│   └── Zellij
├── Editors
│   ├── Neovim + AstroNvim
│   └── Zed
├── Languages
│   ├── Ruby + mise
│   ├── Elixir + Erlang
│   ├── Node.js
│   ├── Python
│   ├── Zig
│   └── Go
├── Databases
│   ├── PostgreSQL 14
│   └── Redis
├── Custom Scripts
│   └── ~/bin (erb-lint-formatter, etc.)
└── Tools
    ├── Git + lazygit
    ├── ripgrep, fd, fzf
    └── bat, eza, tree
```

## 📖 Configuration Structure

### Modular Shell Setup

The `.zshrc` is organized into focused, modular files:

```
~/.zshrc                         # Main config (loads everything)
~/.zshrc-dhh-additions           # DHH-inspired workflows
~/.zshrc-elixir-additions        # Elixir/Phoenix tools
~/.zshrc-terminal-enhancements   # tmux, Zellij, Neovim aliases
~/.zshrc-work                    # Work-specific settings (optional)
```

**Why modular?**
- Easy to understand and modify
- Enable/disable features by commenting one line
- Share common configs, keep private ones separate
- Inspired by DHH's clean, organized approach

### Philosophy Behind File Organization

```
dotfiles/
├── .zshrc                      # Core: prompt, PATH, tool initialization
├── .zshrc-dhh-additions        # Rails workflows, aliases, functions
├── .zshrc-elixir-additions     # Elixir/Phoenix development
├── .zshrc-terminal-enhancements # Terminal multiplexers, editors
├── .zshrc-work                 # Work-specific (not committed to public repo)
├── .tmux.conf                  # tmux: sessions, vim integration, shortcuts
├── .config/
│   ├── aerospace/              # Window management: layouts, keybindings
│   ├── ghostty/                # Terminal: theme, fonts
│   ├── mise/                   # Version manager (Ruby, Node, Elixir, etc.)
│   ├── nvim/                   # Editor: LSP, plugins, keymaps
│   ├── zed/                    # Zed: settings, snippets, tasks
│   ├── zellij/                 # Multiplexer: layouts, theme
│   └── starship.toml           # Prompt: git, languages, colors
├── bin/                        # Custom scripts (erb-lint-formatter, etc.)
└── Brewfile                    # Declarative package management
```

Each file has a single responsibility. Want to change your Rails workflow? Edit `.zshrc-dhh-additions`. Need different terminal aliases? Modify `.zshrc-terminal-enhancements`.

## 📖 Quick Start Guide

### After Installation

1. **Restart your terminal**
   ```bash
   source ~/.zshrc
   ```

2. **Install tmux plugins**
   ```bash
   tmux
   # Press: Ctrl+A then Shift+I
   ```

3. **Open Neovim** (plugins auto-install)
   ```bash
   nvim
   ```

4. **Start Aerospace**
   ```bash
   aerospace reload
   # Or: logout and login again
   ```

### Essential Keybindings

#### Aerospace (Window Management)
**Note**: Uses `Ctrl+Shift` for international keyboard compatibility (DHH-inspired)

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

**App Launchers** (Workspace-aware):
| Key | App | Workspace |
|-----|-----|-----------|
| `Ctrl+Shift+C` | Chrome (work) | 1 |
| `Ctrl+Shift+Z` | Zed editor | 2 |
| `Ctrl+Shift+W` | Warp terminal | 3 |
| `Ctrl+Shift+F` | Firefox (personal) | 5 |
| `Ctrl+Shift+G` | Ghostty terminal | 7 |
| `Ctrl+Shift+O` | Obsidian (PKM) | 8 |
| `Ctrl+Shift+P` | 1Password | 9 |

**Browser Window Cycling** (across all workspaces):
| Key | Action |
|-----|--------|
| `Ctrl+Shift+N` | Next Chrome window |
| `Ctrl+Shift+B` | Previous Chrome window |
| `Alt+Shift+N` | Next Firefox window |
| `Alt+Shift+B` | Previous Firefox window |

#### tmux (Prefix: `Ctrl+A`)
| Key | Action |
|-----|--------|
| `Prefix \|` | Split vertical |
| `Prefix -` | Split horizontal |
| `Prefix h/j/k/l` | Navigate panes (vim-style) |
| `Prefix H/J/K/L` | Resize panes |
| `Prefix c` | New window |
| `Prefix r` | Rails server |
| `Prefix C` | Rails console |
| `Prefix P` | Phoenix server |
| `Prefix I` | IEx console |
| `Prefix Shift+I` | Install plugins |
| `Prefix Shift+U` | Update plugins |

#### Neovim (Leader: `Space`)
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

#### Zellij
| Key | Action |
|-----|--------|
| `Ctrl+O` | Enter command mode (shows options) |
| `Ctrl+G` | Lock mode (pass keys to terminal) |
| `Alt+H/J/K/L` | Navigate panes |
| `Ctrl+Q` | Quit Zellij |

## 🎨 Theming

All tools use the **Tokyo Night** color palette for a consistent, beautiful dark theme:

| Color | Hex | Usage |
|-------|-----|-------|
| Background | `#1a1b26` | Main background |
| Foreground | `#c0caf5` | Text |
| Blue | `#7aa2f7` | Primary accent |
| Cyan | `#7dcfff` | Info, hints |
| Purple | `#bb9af7` | Keywords |
| Green | `#9ece6a` | Strings, success |
| Red | `#f7768e` | Errors |
| Yellow | `#e0af68` | Warnings |

## 📁 Repository Structure

```
dotfiles/
├── install.sh                  # Main installation script (idempotent)
├── update.sh                   # Update script for syncing changes
├── Brewfile                    # Homebrew packages (auto-generated)
├── README.md                   # This file
├── QUICK_REFERENCE.md          # Cheat sheet
├── .zshrc                      # Main shell config
├── .zshrc-dhh-additions        # Rails workflows
├── .zshrc-elixir-additions     # Elixir/Phoenix
├── .zshrc-terminal-enhancements # Terminal tools
├── .zshrc-work                 # Work-specific (optional)
├── .tmux.conf                  # tmux configuration
├── .config/
│   ├── aerospace/              # Window manager config
│   ├── ghostty/                # Terminal config
│   ├── mise/                   # Version manager (Ruby, Node, Elixir, etc.)
│   ├── nvim/                   # Neovim config (AstroNvim)
│   ├── zed/                    # Zed editor config
│   │   ├── settings.json       # Language, LSP, formatter, extension settings
│   │   ├── tasks.json          # RSpec, Rails, Elixir, Zig, npm tasks
│   │   └── snippets/           # ruby.json, erb.json, zig.json
│   ├── zellij/                 # Zellij config + Tokyo Night theme
│   └── starship.toml           # Prompt configuration
├── bin/                        # Custom scripts
│   └── erb-lint-formatter      # ERB lint wrapper for Zed
├── scripts/
│   └── health-check.sh         # Verify installation
└── docs/                       # Additional documentation
```

## 🔄 Maintenance

### Update Dotfiles

Keep your dotfiles in sync with the latest changes:

```bash
cd ~/dotfiles
bash update.sh
```

The update script will:
- 🔄 Pull latest changes from git
- 📦 Update Homebrew packages
- 🔗 Refresh symlinks
- 🛠️ Update mise tools
- 🔌 Update tmux plugins
- ♻️ Reload configurations

### Health Check

Verify your installation is working correctly:

```bash
cd ~/dotfiles
bash scripts/health-check.sh
```

The health check will verify:
- ✅ All core tools are installed
- ✅ Configuration files are properly linked
- ✅ Language runtimes are available
- ✅ Services are running (PostgreSQL, Redis)
- ✅ Shell integrations are configured

### Re-run Installation

The install script is **idempotent** - you can safely run it multiple times:

```bash
cd ~/dotfiles
bash install.sh        # Skip already-installed components
bash install.sh --force # Force reinstall everything
```

## 🔧 Customization

### Change Theme

To switch from Tokyo Night to another theme:

1. **Neovim**: Edit `.config/nvim/lua/plugins/tokyo-night-theme.lua`
2. **Starship**: Edit `.config/starship.toml` palette section
3. **tmux**: Change `@plugin 'janoamaral/tokyo-night-tmux'` in `.tmux.conf`
4. **Zellij**: Edit `.config/zellij/themes/tokyo-night.kdl`
5. **Ghostty**: Change `theme = tokyonight_night` in `.config/ghostty/config`

### Add More Packages

Edit `Brewfile` and run:
```bash
brew bundle install
```

### Customize Zed

- **Settings**: `.config/zed/settings.json` (languages, LSP, formatters)
- **Tasks**: `.config/zed/tasks.json` (RSpec, Rails, Zig, etc.)
- **Snippets**: `.config/zed/snippets/` (ruby.json, erb.json, zig.json)

### Modify Keybindings

- **Aerospace**: `.config/aerospace/aerospace.toml`
- **tmux**: `.tmux.conf`
- **Neovim**: `.config/nvim/lua/plugins/*.lua`

## 🆘 Troubleshooting

### Homebrew Not Found
```bash
# Apple Silicon
eval "$(/opt/homebrew/bin/brew shellenv)"

# Intel
eval "$(/usr/local/bin/brew shellenv)"
```

### tmux Plugins Not Loading
```bash
# Remove and reinstall
rm -rf ~/.tmux/plugins
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
tmux
# Press: Ctrl+A then Shift+I
```

### Neovim Errors
```bash
# Clear cache and reinstall
rm -rf ~/.local/share/nvim
rm -rf ~/.cache/nvim
nvim  # Will reinstall everything
```

### Aerospace Not Starting
```bash
# Reload configuration
aerospace reload

# Or restart
killall Aerospace
open -a Aerospace
```

## 📚 Documentation

Detailed guides for each tool:

- [Neovim Guide](.config/nvim/README.md)
- [Quick Reference](QUICK_REFERENCE.md) - Print this!
- [tmux Guide](docs/tmux-guide.md)
- [Zellij Guide](docs/zellij-guide.md)
- [Aerospace Guide](.config/aerospace/README.md)

## 🙏 Credits

### Inspirations
- **[DHH](https://dhh.dk/)** - Omakub philosophy, Rails workflows, clean configurations
- **[Omakub](https://omakub.org/)** - "Everything in one place" installation concept
- **[ThePrimeagen](https://github.com/ThePrimeagen/.dotfiles)** - Harpoon workflow, tmux setup, vim-first development
- **[José Valim](https://github.com/josevalim/dotfiles)** - Elixir tooling and workflows

### Tools & Themes
- **[AstroNvim](https://github.com/AstroNvim/AstroNvim)** - Neovim distribution
- **[Tokyo Night](https://github.com/folke/tokyonight.nvim)** - Beautiful theme
- **[Starship](https://starship.rs/)** - Fast prompt
- **[Aerospace](https://github.com/nikitabobko/AeroSpace)** - Window manager
- **[Ghostty](https://ghostty.org/)** - Modern terminal

## 📝 License

MIT License - Feel free to use and modify!

## 🤝 Contributing

Found a bug or have a suggestion? Open an issue or PR!

---

**Made with ❤️ by AJ**

*Inspired by DHH's Omakub and ThePrimeagen's workflows*

*Last updated: 2026-03-08*
