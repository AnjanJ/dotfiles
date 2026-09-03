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

# Rendered theme files (see docs/THEMES.md). `dotfiles theme` writes
# ~/.local/state/dotfiles/current/theme/*; apps read from there.
export DOTFILES_THEME_DIR="$HOME/.local/state/dotfiles/current/theme"

# Prompt (Starship - blazing-fast, cross-shell, written in Rust)
# The config is a template rendered per theme; fall back to the default
# search path if no theme has been applied yet.
if command -v starship &>/dev/null; then
  [[ -f "$DOTFILES_THEME_DIR/starship.toml" ]] && export STARSHIP_CONFIG="$DOTFILES_THEME_DIR/starship.toml"
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
export PAGER="less"
export LESS="-R"                     
export BROWSER="open"                # Browser command (macOS)

# === VERSIONS ===
# Note: Ruby, Node, Elixir, etc. managed by mise (~/.config/mise/config.toml)
# These exports are for scripts/tools that need a version reference.
# Actual runtime versions are controlled by mise (all set to "latest").
export PG_VERSION="16"               # PostgreSQL version (matches the running service)
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
# Work projects directory. Currently unused (no job) and the directory
# does not exist -- the work-* helpers in ~/bin will report that clearly
# rather than misbehaving. Recreate ~/work/code to reactivate them.
export WORK_DIR="$HOME/work/code"
export PROJECTS_DIR="$HOME/code"     # Personal projects directory

# === OTHER ===
export ERL_AFLAGS="-kernel shell_history enabled"  # Elixir history
export RUBY_YJIT_ENABLE=1               # Enable YJIT JIT compiler (Ruby 3.1+)

# Maestro (mobile UI testing) -- only added when actually installed.
[[ -d "$HOME/.maestro/bin" ]] && export PATH="$PATH:$HOME/.maestro/bin"

# Ollama settings (local AI for Rails dev)
# MAX_LOADED_MODELS=1 — 36GB unified can't hold 7B + 30B together; explicit single-model swap is cleaner
export OLLAMA_MAX_LOADED_MODELS=1
export OLLAMA_KEEP_ALIVE=24h

# start claude code with ollama and default model as GLM 5.2
oclaude() {
  emulate -L zsh

  local model="glm-5.2:cloud"
  local choose_model=0
  local list_output name choice
  local -a claude_args cloud_models local_preferred local_models models labels
  local -A seen
  integer i

  # Current preferred Ollama cloud models
  cloud_models=(
    "glm-5.3:cloud"
    "glm-5.2:cloud"
    "kimi-k3:cloud"
    "deepseek-v4-pro:cloud"
  )

  # Local models to surface above the rest of `ollama list`
  local_preferred=(
    "qwen3.8-cc:27b"
    "qwen3.8:27b"
  )

  # Process arguments
  while (( $# )); do
    case "$1" in
      -m|--model)
        if (( $# >= 2 )) && [[ "$2" != -* ]]; then
          model="$2"
          shift 2
        else
          choose_model=1
          shift
        fi
        ;;
      -m=*|--model=*)
        model="${1#*=}"
        shift
        ;;
      *)
        claude_args+=("$1")
        shift
        ;;
    esac
  done

  if (( choose_model )); then
    # Read models currently downloaded or registered in Ollama
    list_output="$(ollama list 2>/dev/null)"

    if [[ -n "$list_output" ]]; then
      local_models=(
        "${(@f)$(print -r -- "$list_output" |
          awk 'NR > 1 && NF { print $1 }')}"
      )
    fi

    # Add recommended cloud models first
    for name in "${cloud_models[@]}"; do
      models+=("$name")
      labels+=("$name  [cloud]")
      seen[$name]=1
    done

    # Add preferred local models next
    for name in "${local_preferred[@]}"; do
      [[ -n "${seen[$name]-}" ]] && continue
      # only offer it if it is actually installed
      if print -r -- "$list_output" | awk 'NR > 1 && NF { print $1 }' |
         grep -qxF -- "$name"; then
        models+=("$name")
        labels+=("$name  [local]")
        seen[$name]=1
      fi
    done

    # Add locally available models, avoiding duplicates
    for name in "${local_models[@]}"; do
      [[ -z "$name" ]] && continue
      [[ -n "${seen[$name]-}" ]] && continue

      models+=("$name")

      if [[ "$name" == *:cloud ]]; then
        labels+=("$name  [cloud]")
      else
        labels+=("$name  [local]")
      fi

      seen[$name]=1
    done

    print
    print -r -- "Choose the model for Claude Code:"
    print

    for (( i = 1; i <= ${#models[@]}; i++ )); do
      printf '  %d) %s\n' "$i" "${labels[$i]}"
    done

    print
    read "choice?Model number [1], or q to cancel: "

    choice="${choice:-1}"

    if [[ "$choice" == [qQ] ]]; then
      return 0
    fi

    if [[ "$choice" != <-> ]] ||
       (( choice < 1 || choice > ${#models[@]} )); then
      print -u2 -- "Invalid model selection."
      return 2
    fi

    model="${models[$choice]}"
  fi

  print -r -- "Launching Claude Code with: $model"

  # --permission-mode auto matches ~/.claude/settings.json (defaultMode: auto):
  # project edits are auto-approved, destructive actions still prompt. Pass
  # --dangerously-skip-permissions yourself when a run really needs it.
  ollama launch claude \
    --model "$model" \
    -- \
    --permission-mode auto \
    "${claude_args[@]}"
}

# `a` launches whichever agent `dotfiles default-agent` names (claude by
# default). Change it with: dotfiles default-agent gemini
a() {
  local cmd
  cmd="$(dotfiles-default-agent --command 2>/dev/null)" || cmd="claude --permission-mode auto"
  eval "$cmd" '"$@"'
}

# ── Update notice ─────────────────────────────
# One line at login when commits, brew upgrades, migrations or restarts are
# waiting. The check itself (a git fetch, seconds) never runs in the prompt
# path: once a day a detached job refreshes the cache and the shell only
# reads it. `dotfiles update` refreshes it too, so the notice clears at
# once. Silence it with: dotfiles toggle update-notice off
if [[ -o interactive && ! -f "$HOME/.local/state/dotfiles/toggles/update-notice.off" ]] \
   && command -v dotfiles-update-available >/dev/null 2>&1; then
  _dotfiles_ua="$HOME/.local/state/dotfiles/update-available"
  if [[ ! -f "$_dotfiles_ua" || -n "$(/usr/bin/find "$_dotfiles_ua" -mtime +0 2>/dev/null)" ]]; then
    command mkdir -p "${_dotfiles_ua:h}" && command touch "$_dotfiles_ua"   # so parallel shells do not all fetch
    (dotfiles-update-available --quiet >/dev/null 2>&1 &)
  elif _dotfiles_ua_line="$(dotfiles-update-available --cached --short 2>/dev/null)"; then
    print -P "%F{yellow}dotfiles:%f $_dotfiles_ua_line"
  fi
  unset _dotfiles_ua _dotfiles_ua_line
fi

# Local Qwen3.8-27B for quick coding queries, thinking off for speed.
# (Claude Code via `ollama launch` has no way to pass Ollama's per-request
# `think` field, so thinking-off only applies to this direct path.)
oq() {
  emulate -L zsh
  ollama run qwen3.8:27b --think=false "$@"
}

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

# zsh-syntax-highlighting MUST be the last thing sourced — it wraps the ZLE
# widgets and only sees aliases/functions/completions defined before it.
if [[ -f /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]]; then
  source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi

# ============================================
# END OF CONFIGURATION
# ============================================

# Android SDK (Homebrew android-commandlinetools) — added for karromkar Flutter dev
export ANDROID_HOME="/opt/homebrew/share/android-commandlinetools"
export ANDROID_SDK_ROOT="$ANDROID_HOME"
export PATH="$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator:$ANDROID_HOME/cmdline-tools/latest/bin:$PATH"

# ============================================
# AEROSPACE SESSION
# ============================================
# Re-launch the standard workspace layout at any time. Safe to re-run:
# already-running apps are focused, not duplicated. Placement is handled
# by the on-window-detected rules in .config/aerospace/aerospace.toml.
alias restore-session='~/.config/aerospace/scripts/startup-apps.sh'

# Show what is open where -- handy when adding a new app to the layout.
alias ws='aerospace list-windows --all --format "%{workspace}  %{app-name}" | sort -n'

# Print the bundle id of every open window, to paste into aerospace.toml.
alias ws-ids='aerospace list-windows --all --format "%{workspace}  %{app-bundle-id}  %{app-name}" | sort -n'
