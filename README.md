# 🚀 AJ's Dotfiles

> A complete macOS development environment for Ruby on Rails and Elixir/Phoenix development, with your choice of Tokyo Night or Aura Dark theme applied everywhere.

## 💭 Philosophy

This setup is inspired by **DHH's Omakub** and his "**Everything in one place, everything just works**" philosophy. The goal is simple:

### Core Principles

1. **One Command Installation** - From zero to productive development environment in minutes
2. **Unified Theme** - Choose Tokyo Night or Aura Dark, applied everywhere for visual consistency
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
| **Tokyo Night / Aura** | Choose your theme — applied consistently across all tools |

## ✨ Features

### 🎨 Theme System (Tokyo Night or Aura Dark)

Choose your theme during install — it's applied across **12 apps**:

| Auto-configured | Manual (links provided) |
|----------------|------------------------|
| Neovim, Ghostty, tmux, Zellij, Starship, Zed, VS Code | Slack, Chrome, Firefox, Telegram, Raycast |

Switch anytime: `dotfiles theme aura` or `dotfiles theme tokyo-night`

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
- **Smart CLI** - `cd` uses zoxide (frecency), `ls`→eza, `cat`→bat, `grep`→ripgrep, `find`→fd

## 📦 What's Included

### Core Tools
- **Window Manager**: Aerospace (i3-like tiling for macOS)
- **Terminal**: Ghostty (GPU-accelerated)
- **Shell**: zsh with modular configuration
- **Prompt**: Starship
- **Multiplexers**: tmux + Zellij
- **Editors**: Neovim with AstroNvim, Zed (settings, snippets, tasks)
- **Version Control**: Git (smart defaults + per-directory identity), lazygit, GitHub CLI
- **Work Management**: work-setup, work-nuke, work-switch, work-status, repos-clone
- **Dotfiles CLI**: `dotfiles update`, `dotfiles health`, `dotfiles theme`, `dotfiles install`
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
- MySQL
- Redis
- SQLite (via litecli)

### CLI Utilities
- ripgrep, fd, fzf (fuzzy finding)
- bat (cat with syntax highlighting)
- eza (modern ls)
- tree (directory visualization)
- yazi (terminal file manager)
- lnav, tailspin (log viewers)

## 🎯 One-Command Installation

### Quick Install (from a fresh Mac)

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/AnjanJ/dotfiles/main/install.sh)
```

Or if you prefer to clone first:

```bash
git clone https://github.com/AnjanJ/dotfiles.git ~/dotfiles && bash ~/dotfiles/install.sh
```

Both are **fully non-interactive** with sensible defaults. No prompts, no questions — just run it.

### Customize via flags

```bash
bash install.sh --name "AJ" --email "aj@example.com" --theme aura
bash install.sh --work-email "aj@corp.com" --ssh generate
bash install.sh --interactive          # Prompt for every choice (old behavior)
bash install.sh --no-macos-defaults    # Skip macOS system preferences
bash install.sh --force                # Force reinstall everything
bash install.sh --help                 # Show all options
```

### What it does

1. ✅ Install Homebrew (if not installed)
2. ✅ Install all packages from Brewfile
3. ✅ Create symlinks to dotfiles (shell, tmux, Neovim, Zed, ~/bin)
4. ✅ Apply your chosen theme (Tokyo Night or Aura Dark)
5. ✅ Set up tmux plugins
6. ✅ Configure Neovim
7. ✅ Configure Zed (settings, snippets, tasks)
8. ✅ Set up shell environment, Git defaults, and SSH keys
9. ✅ Apply macOS defaults
10. ✅ Run health check

**💡 Truly idempotent** — run it 10 times, get the same result. No backup clutter, no duplicate configs, no re-prompting.

**📋 Want the full breakdown?** See [WHAT_GETS_INSTALLED.md](WHAT_GETS_INSTALLED.md) — every tool, language, config, and system change explained step by step.

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
│   ├── MySQL
│   ├── Redis
│   └── SQLite (litecli)
├── Dotfiles CLI
│   ├── dotfiles update (upgrade & sync)
│   ├── dotfiles health (verify setup)
│   ├── dotfiles theme (switch theme)
│   └── dotfiles install (run installer)
├── Work Management
│   ├── work-setup (configure work identity)
│   ├── work-nuke (remove work config)
│   ├── work-switch (change employer)
│   ├── work-status (show current setup)
│   └── repos-clone (clone from GitHub/GitLab)
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
| `Ctrl+Shift+W` | Ghostty terminal | 3 |
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

Choose between **Tokyo Night** (dark blue) or **Aura Dark** (deep purple) during install. The theme is applied across 12 apps automatically.

| | Tokyo Night | Aura Dark |
|---|-----------|-----------|
| **Background** | `#1a1b26` | `#15141b` |
| **Foreground** | `#c0caf5` | `#edecee` |
| **Primary accent** | `#7aa2f7` blue | `#a277ff` purple |
| **Secondary** | `#bb9af7` purple | `#61ffca` green |
| **Success** | `#9ece6a` green | `#61ffca` green |
| **Error** | `#f7768e` red | `#ff6767` red |
| **Warning** | `#e0af68` yellow | `#ffca85` orange |

Switch anytime: `dotfiles theme aura` or `dotfiles theme tokyo-night`

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
│   ├── zellij/                 # Zellij config + theme
│   └── starship.toml           # Prompt configuration
├── themes/                     # Theme assets
│   ├── tokyo-night/            # Tokyo Night configs per app
│   └── aura/                   # Aura Dark configs per app
├── bin/                        # CLI commands (all available globally via ~/bin)
│   ├── dotfiles                # Main CLI: dotfiles <update|health|theme|install|edit|dir>
│   ├── dotfiles-update         # Shorthand for dotfiles update
│   ├── dotfiles-health         # Shorthand for dotfiles health
│   ├── dotfiles-theme          # Shorthand for dotfiles theme
│   ├── dotfiles-install        # Shorthand for dotfiles install
│   ├── work-setup              # Configure work identity
│   ├── work-nuke               # Remove all work config
│   ├── work-switch             # Change employer
│   ├── work-status             # Show current work setup
│   ├── repos-clone             # Clone repos from GitHub/GitLab
│   ├── erb-lint-formatter      # ERB lint wrapper for Zed
│   └── _work-helpers           # Shared utilities for work scripts
├── Brewfile.backup             # Previous Brewfile (one backup, for rollback)
├── scripts/
│   ├── _helpers.sh             # Shared colors & print functions
│   ├── setup-git.sh            # Git identity & defaults setup
│   ├── setup-ssh.sh            # SSH key & config setup
│   ├── health-check.sh         # Verify installation
│   ├── theme-utils.sh          # Theme utility functions
│   └── apply-theme.sh          # Apply theme across all apps
├── tests/
│   ├── test-idempotency.sh     # 18 idempotency tests (sandboxed)
│   ├── test-work-nuke.sh       # 9 work-nuke edge case tests
│   ├── test-repos-clone.sh     # 10 repos-clone logic tests
│   ├── test-ssh-adversarial.sh # 7 SSH adversarial input tests
│   └── test-update.sh          # 5 update.sh symlink tests
└── docs/                       # Additional documentation
```

## 🔄 Maintenance

All commands work from anywhere — no need to `cd ~/dotfiles` first.

### Dotfiles CLI

```bash
dotfiles update       # Upgrade system & sync repo (pull → brew upgrade → snapshot → push)
dotfiles health       # Verify all tools are installed and configured
dotfiles theme aura   # Switch theme (tokyo-night | aura)
dotfiles install      # Re-run full installer (idempotent)
dotfiles edit         # Open dotfiles in your editor
dotfiles dir          # Print dotfiles directory path
```

Shorthand commands also work: `dotfiles-update`, `dotfiles-health`, `dotfiles-theme`, `dotfiles-install`

### What `dotfiles update` does

1. Pull latest changes from git
2. `brew update` + `brew upgrade` + `brew cleanup`
3. Snapshot Brewfile (captures any new apps you installed manually)
4. Refresh all symlinks
5. Upgrade mise tools
6. Update tmux plugins
7. Reload live configs (tmux, aerospace)
8. Commit & push changes back to repo

**Your Brewfile stays in sync automatically.** Install apps with `brew install` or `mas install` anytime — the next `dotfiles update` captures them into the repo. One `Brewfile.backup` is kept for rollback.

### Health Check

```bash
dotfiles health
```

Verifies: core tools, config symlinks, language runtimes, running services (PostgreSQL, MySQL, Redis), shell integrations, and work identity.

### Re-run Installation

The install script is **truly idempotent** — run it any number of times with identical results:

```bash
dotfiles install                    # Non-interactive, skips what's done
dotfiles install --interactive      # Prompt for every choice
dotfiles install --force            # Force reinstall everything
```

## 🔧 Customization

### Switch Theme

Switch between Tokyo Night and Aura Dark from anywhere:

```bash
dotfiles theme aura         # Switch to Aura Dark
dotfiles theme tokyo-night  # Switch to Tokyo Night
```

This updates Neovim, Ghostty, tmux, Zellij, Starship, Zed, and VS Code automatically, then prints instructions for Slack, browsers, Telegram, and Raycast.

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

- [What Gets Installed](WHAT_GETS_INSTALLED.md) - Full breakdown of every tool and config change
- [Quick Reference](QUICK_REFERENCE.md) - Print this!
- [Neovim Guide](.config/nvim/README.md)
- [Daily Workflows](docs/DAILY_WORKFLOWS.md)

## 🧪 Testing

Automated tests run on every push and PR via GitHub Actions:

- **Shellcheck** — lints all shell scripts
- **Idempotency** — verifies install/setup can run multiple times safely
- **Work identity** — tests setup, nuke, and switch lifecycle
- **SSH config** — adversarial inputs and edge cases
- **Repo cloner** — SSH alias detection and URL rewriting
- **Update flow** — symlink creation and refresh

Run locally: `bash tests/test-idempotency.sh` (or any test file in `tests/`)

## 🙏 Credits

### Inspirations
- **[DHH](https://dhh.dk/)** - Omakub philosophy, Rails workflows, clean configurations
- **[Omakub](https://omakub.org/)** - "Everything in one place" installation concept
- **[ThePrimeagen](https://github.com/ThePrimeagen/.dotfiles)** - Harpoon workflow, tmux setup, vim-first development
- **[José Valim](https://github.com/josevalim/dotfiles)** - Elixir tooling and workflows

### Tools & Themes
- **[AstroNvim](https://github.com/AstroNvim/AstroNvim)** - Neovim distribution
- **[Tokyo Night](https://github.com/folke/tokyonight.nvim)** - Dark blue theme by folke
- **[Aura Theme](https://github.com/daltonmenezes/aura-theme)** - Deep purple theme by daltonmenezes
- **[Starship](https://starship.rs/)** - Fast prompt
- **[Aerospace](https://github.com/nikitabobko/AeroSpace)** - Window manager
- **[Ghostty](https://ghostty.org/)** - Modern terminal

## 📝 License

MIT License - Feel free to use and modify!

## 🤝 Contributing

Found a bug or have a suggestion? Open an issue or PR!

---

**Made with ❤️ by [AJ](https://anjan.dev)**

*Inspired by DHH's Omakub and ThePrimeagen's workflows*

*Last updated: 2026-03-11*
