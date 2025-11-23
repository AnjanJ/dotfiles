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

# Prompt (Starship - blazing-fast, cross-shell, written in Rust)
eval "$(starship init zsh)"

# PATH
export PATH="$HOME/bin:$PATH:$HOME/.local/bin"

# ============================================
# 2. ENVIRONMENT VARIABLES
# ============================================
# Centralized variables - change once, use everywhere!

# === CORE TOOLS ===
export EDITOR="zed --wait"
export VISUAL="$EDITOR"              # Visual editor (usually same)
export GIT_EDITOR="$EDITOR"          # Git commit editor
export BUNDLER_EDITOR="$EDITOR"      # Rails credentials editor
export PAGER="bat"                   # File pager (bat with syntax highlighting)
export BROWSER="open"                # Browser command (macOS)

# === VERSIONS ===
# Note: Ruby, Node, Elixir, etc. managed by mise (~/.config/mise/config.toml)
export PG_VERSION="14"               # PostgreSQL version (14.20 installed, 17 available)
export RUBY_VERSION="3.4.5"          # Ruby (mise global - matches actual)
export NODE_VERSION="24.7.0"         # Node (mise uses "latest" = 24.7.0)
export RAILS_VERSION="8.0.4"         # Rails (latest stable)
export ELIXIR_VERSION="latest"       # Elixir (mise manages)
export GO_VERSION="latest"           # Go (mise manages)
export PYTHON_VERSION="3"            # Python (mise manages)

# === DATABASE ===
export DEFAULT_DB="postgresql"       # Default database for new Rails apps
export DB_USER="postgres"            # Default database user

# === PATHS ===
export WORK_DIR="$HOME/work/code"    # Work projects directory
export PROJECTS_DIR="$HOME/code"     # Personal projects directory

# === OTHER ===
export ERL_AFLAGS="-kernel shell_history enabled"  # Elixir history

# ============================================
# 3. TOOL INITIALIZATION
# ============================================

# mise (polyglot version manager)
eval "$(mise activate zsh)"

# ============================================
# 4. PROJECT-SPECIFIC ALIASES
# ============================================

# Canvas LMS Development
alias rslti='rails server -p 4000'           # LTI server on port 4000
alias devmig='bin/rails db:migrate RAILS_ENV=development'
alias testmig='bin/rails db:migrate RAILS_ENV=test'
alias deljob='bundle exec script/delayed_job run'
alias skiq='bundle exec sidekiq'
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

  echo "⚠️  Delete all gems for Ruby $ruby_version? (y/N)"
  read confirm
  if [[ $confirm == "y" ]]; then
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

# Modern terminal enhancements
# (fzf, zoxide, bat, eza, fd, ripgrep, etc.)
if [ -f ~/.zshrc-terminal-enhancements ]; then
  source ~/.zshrc-terminal-enhancements
fi

# Work-specific configuration
# (Instructure, AWS, Canvas shortcuts)
if [ -f ~/.zshrc-work ]; then
  source ~/.zshrc-work
fi

# Elixir & Phoenix developer setup
# (Phoenix, Mix, Ecto, Testing, IEx helpers)
if [ -f ~/.zshrc-elixir-additions ]; then
  source ~/.zshrc-elixir-additions
fi

# ============================================
# END OF CONFIGURATION
# ============================================
