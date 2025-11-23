# 🚀 AJ's Dotfiles

> A complete macOS development environment for Ruby on Rails and Elixir/Phoenix development, themed with Tokyo Night everywhere.

## ✨ Features

### 🎨 Unified Tokyo Night Theme
- **Neovim** - Beautiful syntax highlighting and statusline
- **tmux** - Themed status bar and pane borders
- **Zellij** - Custom Tokyo Night color scheme
- **Starship** - Matching prompt colors
- **Ghostty** - Terminal theme

### 🛠️ Development Tools
- **Ruby** - rbenv, ruby-lsp, RuboCop
- **Elixir** - elixir-ls, mix integration
- **Rails** - vim-rails, test runners, MVC navigation
- **Phoenix** - Phoenix-specific tooling
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
- **Shell**: zsh with custom configuration
- **Prompt**: Starship
- **Multiplexers**: tmux + Zellij
- **Editor**: Neovim with AstroNvim
- **Version Control**: Git, lazygit, GitHub CLI

### Development
- Ruby (via rbenv)
- Elixir + Erlang
- Node.js
- PostgreSQL
- Redis

### CLI Utilities
- ripgrep, fd, fzf (fuzzy finding)
- bat (cat with syntax highlighting)
- eza (modern ls)
- tree (directory visualization)
- htop, btop (system monitoring)

## 🎯 One-Command Installation

### Quick Install

```bash
git clone https://github.com/YOUR_USERNAME/dotfiles.git ~/dotfiles
cd ~/dotfiles
bash install.sh
```

That's it! The script will:
1. ✅ Install Homebrew (if not installed)
2. ✅ Install all packages from Brewfile
3. ✅ Backup your existing configurations
4. ✅ Create symlinks to dotfiles
5. ✅ Set up tmux plugins
6. ✅ Configure Neovim
7. ✅ Set up shell environment
8. ✅ Apply macOS defaults (optional)

### What Gets Installed

```
Installed Tools:
├── Window Management
│   └── Aerospace (i3-like tiling)
├── Terminals
│   └── Ghostty (GPU-accelerated)
├── Shell
│   ├── zsh
│   └── Starship prompt
├── Multiplexers
│   ├── tmux (with 8 plugins)
│   └── Zellij
├── Editors
│   ├── Neovim + AstroNvim
│   └── Zed
├── Languages
│   ├── Ruby + rbenv
│   ├── Elixir + Erlang
│   ├── Node.js
│   └── Python
├── Databases
│   ├── PostgreSQL 16
│   └── Redis
└── Tools
    ├── Git + lazygit
    ├── ripgrep, fd, fzf
    └── bat, eza, tree
```

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
- `Cmd+H/J/K/L` - Move focus between windows
- `Cmd+Shift+H/J/K/L` - Move windows
- `Cmd+1-9` - Switch to workspace
- `Cmd+Shift+1-9` - Move window to workspace
- `Cmd+F` - Toggle fullscreen
- `Cmd+S` - Toggle split orientation

#### tmux
- `Ctrl+A` - Prefix key
- `Prefix + |` - Split vertically
- `Prefix + -` - Split horizontally
- `Prefix + h/j/k/l` - Navigate panes
- `Prefix + c` - New window
- `Prefix + r` - Rails server
- `Prefix + C` - Rails console

#### Neovim (Normal Mode)
- `<Leader>ff` - Find files
- `<Leader>fw` - Find words (grep)
- `<Leader>fb` - Find buffers
- `Ctrl+H/J/K/L` - Navigate to Harpoon marks
- `<Leader>ha` - Add file to Harpoon
- `gd` - Go to definition
- `gr` - Find references
- `<Leader>la` - Code actions

#### Starship Prompt
- Git status, language versions, directory info
- Auto-displays when relevant
- Tokyo Night color scheme

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
├── install.sh                  # Main installation script
├── Brewfile                    # Homebrew packages
├── README.md                   # This file
├── .zshrc                      # Main shell config
├── .zshrc-aliases              # Shell aliases
├── .zshrc-terminal-enhancements # Terminal tools config
├── .tmux.conf                  # tmux configuration
├── .config/
│   ├── aerospace/              # Window manager config
│   ├── ghostty/                # Terminal config
│   ├── nvim/                   # Neovim config (AstroNvim)
│   ├── zellij/                 # Zellij config + Tokyo Night theme
│   └── starship.toml           # Prompt configuration
├── scripts/                    # Helper scripts
└── docs/                       # Additional documentation
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
- [tmux Guide](docs/tmux-guide.md)
- [Zellij Guide](docs/zellij-guide.md)
- [Aerospace Guide](.config/aerospace/README.md)

## 🙏 Credits

### Inspirations
- [ThePrimeagen](https://github.com/ThePrimeagen/.dotfiles) - Harpoon workflow, tmux setup
- [DHH](https://github.com/dhh/dotfiles) - Rails workflows
- [José Valim](https://github.com/josevalim/dotfiles) - Elixir tooling

### Tools
- [AstroNvim](https://github.com/AstroNvim/AstroNvim) - Neovim distribution
- [Tokyo Night](https://github.com/folke/tokyonight.nvim) - Beautiful theme
- [Starship](https://starship.rs/) - Fast prompt
- [Aerospace](https://github.com/nikitabobko/AeroSpace) - Window manager

## 📝 License

MIT License - Feel free to use and modify!

## 🤝 Contributing

Found a bug or have a suggestion? Open an issue or PR!

---

**Made with ❤️ by AJ**

*Last updated: 2025-11-24*
