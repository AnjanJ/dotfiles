# ============================================
# DOTFILES BREWFILE
# ============================================
# Install all packages with: brew bundle install
# ============================================

# Taps
tap "homebrew/bundle"
tap "nikitabobko/tap"  # Aerospace window manager
tap "FelixKratz/formulae"  # JankyBorders (optional)

# ============================================
# ESSENTIAL TOOLS
# ============================================

# Shell & Terminal
brew "zsh"
brew "starship"      # Fast, customizable prompt
brew "tmux"          # Terminal multiplexer
brew "zellij"        # Modern terminal multiplexer
cask "ghostty"       # GPU-accelerated terminal

# Window Management
cask "aerospace"     # i3-like tiling window manager for macOS

# Version Control
brew "git"
brew "gh"            # GitHub CLI
brew "lazygit"       # Terminal UI for git

# ============================================
# DEVELOPMENT TOOLS
# ============================================

# Code Editors
cask "zed"           # Modern code editor
brew "neovim"        # Hyperextensible Vim-based text editor

# Programming Languages
brew "ruby"          # Ruby (via rbenv recommended)
brew "elixir"        # Elixir
brew "erlang"        # Erlang (Elixir dependency)
brew "node"          # Node.js
brew "python"        # Python

# Language Version Managers (optional but recommended)
brew "rbenv"         # Ruby version manager
brew "ruby-build"    # rbenv plugin to compile Ruby
brew "nvm"           # Node version manager (requires shell setup)

# Databases
brew "postgresql@16" # PostgreSQL
brew "redis"         # Redis

# ============================================
# NEOVIM DEPENDENCIES
# ============================================

brew "ripgrep"       # Fast grep (required for Telescope)
brew "fd"            # Fast find (required for Telescope)
brew "fzf"           # Fuzzy finder
brew "tree-sitter"   # Parser generator
brew "lazygit"       # Terminal UI for git (Neovim integration)

# LSP Servers (Language Server Protocol)
brew "lua-language-server"  # Lua LSP

# Ruby LSP will be installed via Mason in Neovim
# Elixir LSP will be installed via Mason in Neovim

# ============================================
# OPTIONAL TOOLS
# ============================================

# System Utilities
brew "htop"          # Process viewer
brew "btop"          # Resource monitor
brew "wget"          # Download utility
brew "curl"          # Transfer tool
brew "jq"            # JSON processor
brew "yq"            # YAML processor

# File Management
brew "tree"          # Directory tree viewer
brew "bat"           # Cat with syntax highlighting
brew "eza"           # Modern ls replacement

# Additional Tools
brew "tldr"          # Simplified man pages
brew "mas"           # Mac App Store CLI

# Fonts (Nerd Fonts for terminal icons)
cask "font-fira-code-nerd-font"
cask "font-jetbrains-mono-nerd-font"
cask "font-meslo-lg-nerd-font"

# ============================================
# OPTIONAL APPLICATIONS
# ============================================

# Browsers
cask "google-chrome"
cask "firefox"

# Communication
cask "slack"
cask "zoom"

# Productivity
cask "rectangle"     # Window management (alternative to Aerospace)
cask "raycast"       # Spotlight replacement (optional)

# ============================================
# NOTES
# ============================================
# After installation:
# 1. Run: $(brew --prefix)/opt/fzf/install  # Set up fzf key bindings
# 2. Set up rbenv: echo 'eval "$(rbenv init - zsh)"' >> ~/.zshrc
# 3. Install Ruby: rbenv install 3.3.0 && rbenv global 3.3.0
# 4. Install Rails: gem install rails
# 5. Install Postgres: brew services start postgresql@16
# ============================================
