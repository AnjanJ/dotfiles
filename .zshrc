# ============================================
# MAIN ZSH CONFIGURATION
# ============================================
# Author: AJ
# Last Updated: 2025-11-23
# Description: Clean, organized shell config
#              for DHH-inspired workflow
# ============================================
#
# QUICK INDEX:
# ──────────────────────────────────────────
#  1. Core Settings (prompt, editor, PATH)
#  2. Environment Variables
#  3. Tool Initialization (mise)
#  4. Project-Specific Aliases
#  5. System Utilities
#  6. Functions
#  7. Load Additional Configs
#
# ============================================

# ============================================
# 1. CORE SETTINGS
# ============================================
#

# Prompt (Starship - blazing-fast, cross-shell, written in Rust)
if command -v starship &>/dev/null; then
  eval "$(starship init zsh)"
fi

# PATH
export PATH="$HOME/bin:$PATH:$HOME/.local/bin"

# ============================================
# 2. ENVIRONMENT VARIABLES
# ============================================
# Centralized variables - change once, use everywhere!

# === CORE TOOLS ===
if command -v zed &>/dev/null; then
  export EDITOR="zed --wait"
elif command -v nvim &>/dev/null; then
  export EDITOR="nvim"
else
  export EDITOR="vim"
fi
export VISUAL="$EDITOR"              # Visual editor (usually same)
export GIT_EDITOR="$EDITOR"          # Git commit editor
export BUNDLER_EDITOR="$EDITOR"      # Rails credentials editor
if command -v bat &>/dev/null; then
  export PAGER="bat"                   # File pager (bat with syntax highlighting)
fi
export BROWSER="open"                # Browser command (macOS)

# === VERSIONS ===
# Note: Ruby, Node, Elixir, etc. managed by mise (~/.config/mise/config.toml)
# These exports are for scripts/tools that need a version reference.
# Actual runtime versions are controlled by mise (all set to "latest").
export PG_VERSION="14"               # PostgreSQL version
export RUBY_VERSION="latest"         # Ruby (mise manages)
export NODE_VERSION="latest"         # Node (mise manages)
export RAILS_VERSION="8.0.4"         # Rails (latest stable, gem-managed)
export ELIXIR_VERSION="latest"       # Elixir (mise manages)
export GO_VERSION="latest"           # Go (mise manages)
export PYTHON_VERSION="latest"       # Python (mise manages)

# === DATABASE ===
export DEFAULT_DB="postgresql"       # Default database for new Rails apps
export DB_USER="postgres"            # Default database user

# === PATHS ===
export WORK_DIR="$HOME/work/code"    # Work projects directory
export PROJECTS_DIR="$HOME/code"     # Personal projects directory

# === OTHER ===
export ERL_AFLAGS="-kernel shell_history enabled"  # Elixir history
export RUBY_YJIT_ENABLE=1               # Enable YJIT JIT compiler (Ruby 3.1+)

# ============================================
# 3. TOOL INITIALIZATION
# ============================================

# mise (polyglot version manager)
if command -v mise &>/dev/null; then
  eval "$(mise activate zsh)"
fi

# direnv (per-project environment variables)
if command -v direnv &>/dev/null; then
  eval "$(direnv hook zsh)"
fi

# ============================================
# 4. PROJECT-SPECIFIC ALIASES
# ============================================

# General Rails development
alias rails_tree='lsd --tree --ignore-glob "tmp" --ignore-glob "vendors" --ignore-glob "node_modules"'

# ============================================
# 5. SYSTEM UTILITIES
# ============================================

# Process Management
alias killspring='pkill -9 -f spring'       # Kill Rails Spring
alias docker-nuke='docker system prune -a --volumes'

# System Maintenance
alias updatebrew='brew update && brew upgrade && brew cleanup'
alias htop='htop --sort-key PERCENT_CPU'

# Python
alias venv='source venv/bin/activate'
alias pyserve='python3 -m http.server'

# Git (unique aliases - main ones in dhh-additions)
alias gst='git status'                       # Preferred over 'gs'
alias gcm='git commit -m'
alias gcane='git commit --amend --no-edit'
alias gstash='git stash'
alias gpop='git stash pop'

# ============================================
# 6. FUNCTIONS
# ============================================

# Remove all gems for a specific Ruby version
# Usage: delgems <version>
# Example: delgems 3.2.0
delgems() {
  if [ -z "$1" ]; then
    echo "Usage: delgems <ruby_version>"
    echo "Example: delgems 3.2.0"
    return 1
  fi

  local ruby_version="$1"
  local gem_dir="$HOME/.local/share/mise/installs/ruby/$ruby_version/lib/ruby/gems"

  if [ ! -d "$gem_dir" ]; then
    echo "❌ Ruby version $ruby_version not found"
    echo "💡 Available versions: $(mise list ruby 2>/dev/null | grep -v 'not installed')"
    return 1
  fi

  echo "⚠️  Delete all gems for Ruby $ruby_version?"
  echo "  Type 'yes' to confirm:"
  read -r confirm
  if [[ "$confirm" == "yes" ]]; then
    rm -rf "$gem_dir"/*
    echo "✅ Gems deleted for Ruby $ruby_version"
  else
    echo "Cancelled"
  fi
}

# ============================================
# 7. LOAD ADDITIONAL CONFIGS
# ============================================

# DHH-inspired Rails developer setup
# (Rails, Git, Bundle, Testing, Database helpers)
if [ -f ~/.zshrc-dhh-additions ]; then
  source ~/.zshrc-dhh-additions
fi

# compinit runs BEFORE plugins that depend on it (fzf-tab, zsh-completions
# wired via terminal-enhancements). `-C` skips the security check on insecure
# directories — saves ~5ms; safe because we own everything in fpath.
autoload -Uz compinit && compinit -C

# Modern terminal enhancements
# (fzf, zoxide, bat, eza, fd, ripgrep, autosuggestions, syntax-highlight, AI tools)
if [ -f ~/.zshrc-terminal-enhancements ]; then
  source ~/.zshrc-terminal-enhancements
fi

# Work-specific configuration
# (work-specific shortcuts)
if [ -f ~/.zshrc-work ]; then
  source ~/.zshrc-work
fi

# Elixir & Phoenix developer setup
# (Phoenix, Mix, Ecto, Testing, IEx helpers)
if [ -f ~/.zshrc-elixir-additions ]; then
  source ~/.zshrc-elixir-additions
fi

# Dotfiles & work command completions
if [ -f ~/.zshrc-work-completions ]; then
  source ~/.zshrc-work-completions
fi

# Machine-specific overrides (not tracked in git)
if [ -f ~/.zshrc.local ]; then
  source ~/.zshrc.local
fi

# ============================================
# END OF CONFIGURATION
# ============================================
export PATH=$PATH:$HOME/.maestro/bin

# Ollama settings (local AI for Rails dev)
# MAX_LOADED_MODELS=1 — 36GB unified can't hold 7B + 30B together; explicit single-model swap is cleaner
export OLLAMA_MAX_LOADED_MODELS=1
export OLLAMA_KEEP_ALIVE=24h
