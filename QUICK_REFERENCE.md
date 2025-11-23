# ⚡ Quick Reference Card

## 🎯 One-Liners

```bash
# Install everything
git clone https://github.com/YOUR_USERNAME/dotfiles.git ~/dotfiles && cd ~/dotfiles && bash install.sh

# Update dotfiles
cd ~/dotfiles && git pull && bash install.sh

# Backup current configs
cp -r ~/.config ~/.config.backup.$(date +%Y%m%d)
```

## ⌨️ Essential Keybindings

### Aerospace (Window Manager)
**Note**: Uses `Ctrl+Shift` for international keyboards (DHH-inspired)

| Key | Action |
|-----|--------|
| `Ctrl+Shift+H/J/K/L` | Navigate windows (vim-style) |
| `Ctrl+Alt+H/J/K/L` | Move windows |
| `Ctrl+Shift+1-9` | Switch workspace |
| `Ctrl+Alt+1-9` | Move to workspace |
| `Ctrl+Shift+/` | Toggle layout |
| `Ctrl+Shift+-/=` | Resize window |
| `Ctrl+Shift+Tab` | Toggle last workspaces |

**App Launchers**:
| `Ctrl+Shift+C` | Chrome (workspace 1) |
| `Ctrl+Shift+Z` | Zed (workspace 2) |
| `Ctrl+Shift+G` | Ghostty (workspace 7) |
| `Ctrl+Shift+O` | Obsidian (workspace 8) |

### tmux (Prefix: `Ctrl+A`)
| Key | Action |
|-----|--------|
| `Prefix \|` | Split vertical |
| `Prefix -` | Split horizontal |
| `Prefix h/j/k/l` | Navigate panes |
| `Prefix c` | New window |
| `Prefix r` | Rails server |
| `Prefix C` | Rails console |
| `Prefix I` | Install plugins |

### Neovim (Leader: `Space`)
| Key | Action |
|-----|--------|
| `<Leader>ff` | Find files |
| `<Leader>fw` | Find word (grep) |
| `<Leader>fb` | Find buffers |
| `<Leader>ha` | Harpoon: add file |
| `Ctrl+H/J/K/L` | Harpoon: jump 1-4 |
| `gd` | Go to definition |
| `gr` | Find references |
| `<Leader>la` | Code actions |
| `K` | Hover docs |

### Zellij
| Key | Action |
|-----|--------|
| `Ctrl+O` | Enter mode |
| `Ctrl+G` | Lock (pass-through) |
| `Alt+H/J/K/L` | Navigate panes |
| `Ctrl+Q` | Quit |

## 🛠️ Common Tasks

### Git Workflow
```bash
# Stage and commit
lazygit  # or 'lg' alias

# Create PR
gh pr create

# View PR
gh pr view --web
```

### Rails Development
```bash
# In Neovim
<Leader>rc  # Go to controller
<Leader>rm  # Go to model
<Leader>rv  # Go to view
<Leader>rs  # Go to spec
<Leader>ra  # Alternate file

# In tmux
Prefix r    # Start Rails server
Prefix C    # Open Rails console
```

### Elixir/Phoenix Development
```bash
# In tmux
Prefix P    # Start Phoenix server
Prefix I    # Open IEx

# In Neovim
<Leader>ff  # Find files
<Leader>fw  # Find in files
```

### Package Management
```bash
# Homebrew
brew update && brew upgrade
brew bundle install  # Install from Brewfile

# Neovim plugins
nvim
:Lazy sync

# tmux plugins
tmux
Prefix + U  # Update
```

## 🔧 Troubleshooting

### Reload Configurations
```bash
# Shell
source ~/.zshrc

# tmux
tmux source ~/.tmux.conf

# Aerospace
aerospace reload

# Neovim
:source ~/.config/nvim/init.lua
```

### Reset Everything
```bash
# Neovim
rm -rf ~/.local/share/nvim ~/.cache/nvim

# tmux plugins
rm -rf ~/.tmux/plugins && git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

# Shell
source ~/.zshrc
```

## 📊 System Info

```bash
# Check versions
nvim --version
tmux -V
zellij --version
starship --version
aerospace --version

# Check Homebrew packages
brew list
```

## 🎨 Theme Colors (Tokyo Night)

| Element | Hex |
|---------|-----|
| Background | `#1a1b26` |
| Foreground | `#c0caf5` |
| Blue | `#7aa2f7` |
| Cyan | `#7dcfff` |
| Purple | `#bb9af7` |
| Green | `#9ece6a` |
| Red | `#f7768e` |
| Yellow | `#e0af68` |

---

**Print this out or keep it handy!** 📎
