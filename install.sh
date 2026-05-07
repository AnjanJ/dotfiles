#!/usr/bin/env bash

# ============================================
# DOTFILES INSTALLATION SCRIPT
# ============================================
# One-command setup for macOS development environment
#
# Usage:
#   bash install.sh                          # Non-interactive, sensible defaults
#   bash install.sh --interactive            # Prompt for every choice
#   bash install.sh --name "AJ" --email "aj@example.com"
#   bash <(curl -fsSL https://raw.githubusercontent.com/AnjanJ/dotfiles/main/install.sh)
#
# Flags:
#   --interactive       Prompt for every choice (original behavior)
#   --name "Name"       Git user.name
#   --email "a@b.com"   Git personal email
#   --work-email "x@y"  Git work email (enables work identity)
#   --work-dir "~/work" Work directory (default: ~/work)
#   --theme <name>      Theme: tokyo-night or aura (default: tokyo-night)
#   --ssh <mode>        SSH: 1password, existing, generate, skip
#                       Default: auto-detect 1Password SSH agent if running,
#                       otherwise skip. Force with --ssh 1password.
#   --groups "a,b,c"    Package groups to install (comma-separated)
#   --no-macos-defaults Skip macOS defaults
#   --force             Force reinstall even if already configured
#   --help              Show this help
#
# Environment variables (flags take precedence):
#   DOTFILES_GIT_NAME, DOTFILES_GIT_EMAIL, DOTFILES_WORK_EMAIL
#   DOTFILES_WORK_DIR, DOTFILES_THEME, DOTFILES_SSH_MODE
# ============================================

# ── Bootstrap: handle curl-pipe-bash ──────────
# If this script is piped via curl, clone the repo first and re-exec.
_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd)"

if [[ ! -f "$_SCRIPT_DIR/scripts/_helpers.sh" ]]; then
    echo ""
    echo "Bootstrapping: dotfiles repo not found locally..."
    DOTFILES_REPO="https://github.com/AnjanJ/dotfiles.git"
    DOTFILES_TARGET="$HOME/dotfiles"

    if ! command -v git &>/dev/null; then
        echo "Git not found. Installing Xcode Command Line Tools..."
        xcode-select --install 2>/dev/null || true
        echo "Please re-run this script after Xcode tools finish installing."
        exit 1
    fi

    if [[ -d "$DOTFILES_TARGET/.git" ]]; then
        echo "Dotfiles already cloned at $DOTFILES_TARGET, pulling latest..."
        git -C "$DOTFILES_TARGET" pull origin main 2>/dev/null || true
    else
        git clone "$DOTFILES_REPO" "$DOTFILES_TARGET"
    fi

    exec bash "$DOTFILES_TARGET/install.sh" "$@"
fi

set -euo pipefail

# ── Parse Arguments ───────────────────────────

INTERACTIVE=false
FORCE_INSTALL=false
APPLY_MACOS_DEFAULTS=true

# Env var defaults (flags override these)
GIT_NAME="${DOTFILES_GIT_NAME:-}"
GIT_EMAIL="${DOTFILES_GIT_EMAIL:-}"
GIT_WORK_EMAIL="${DOTFILES_WORK_EMAIL:-}"
WORK_DIR="${DOTFILES_WORK_DIR:-}"
SELECTED_THEME="${DOTFILES_THEME:-}"
SSH_MODE="${DOTFILES_SSH_MODE:-}"
SELECTED_GROUPS="${DOTFILES_GROUPS:-}"

while [[ $# -gt 0 ]]; do
    case $1 in
        --interactive) INTERACTIVE=true; shift ;;
        --force) FORCE_INSTALL=true; shift ;;
        --name) GIT_NAME="$2"; shift 2 ;;
        --email) GIT_EMAIL="$2"; shift 2 ;;
        --work-email) GIT_WORK_EMAIL="$2"; shift 2 ;;
        --work-dir) WORK_DIR="$2"; shift 2 ;;
        --theme) SELECTED_THEME="$2"; shift 2 ;;
        --ssh) SSH_MODE="$2"; shift 2 ;;
        --groups) SELECTED_GROUPS="$2"; shift 2 ;;
        --no-macos-defaults) APPLY_MACOS_DEFAULTS=false; shift ;;
        --help)
            # Print the usage block from the header
            sed -n '/^# Usage:/,/^# ====/{ /^# ====/d; s/^# //; s/^#//; p; }' "$0"
            exit 0
            ;;
        *) shift ;;
    esac
done

# Export for sub-scripts
export INTERACTIVE FORCE_INSTALL GIT_NAME GIT_EMAIL GIT_WORK_EMAIL WORK_DIR SSH_MODE SELECTED_GROUPS

# ── Setup ─────────────────────────────────────

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Shared colors & print functions
source "$DOTFILES_DIR/scripts/_helpers.sh"

# Check if running on macOS
if [[ "$(uname)" != "Darwin" ]]; then
    print_error "This script is only for macOS"
    exit 1
fi

echo ""
echo ""
echo "  AJ's Dotfiles Installation"
echo "  =========================================="
echo ""
echo "  This will install:"
echo "    - Homebrew packages"
echo "    - Aerospace (window manager)"
echo "    - Ghostty terminal"
echo "    - Neovim + AstroNvim"
echo "    - Zellij (terminal multiplexer)"
echo "    - Zed editor (settings, snippets, tasks)"
echo "    - Starship prompt"
echo "    - Shell configuration (zsh + autosuggestions + syntax-highlighting + fzf-tab)"
echo "    - AI CLI tooling (llm + ollama + gh copilot)"
echo "    - Git smart defaults + identity setup"
echo "    - SSH keys (1Password, import, generate, or existing)"
echo "    - Custom scripts (~/bin)"
echo "    - Theme: Tokyo Night, Aura, or Catppuccin (your choice!)"
echo ""
echo "  Idempotent -- safe to re-run anytime"
echo ""
echo ""

if [[ "$INTERACTIVE" == true ]]; then
    read -r -p "Continue with installation? (y/n) " -n 1
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_warning "Installation cancelled"
        exit 1
    fi
fi

echo ""
print_step "Dotfiles directory: $DOTFILES_DIR"

# ============================================
# THEME SELECTION
# ============================================
source "$DOTFILES_DIR/scripts/theme-utils.sh"

if [[ -z "$SELECTED_THEME" ]]; then
    if [[ "$INTERACTIVE" == true ]]; then
        # --interactive: always let the user choose
        SELECTED_THEME=$(prompt_theme_choice)
    elif [[ -f "$HOME/.dotfiles-theme" ]]; then
        # Re-run without --interactive: keep previous choice
        SELECTED_THEME=$(get_current_theme)
    else
        # Fresh install without --interactive: prompt anyway
        SELECTED_THEME=$(prompt_theme_choice)
    fi
fi

if ! validate_theme "$SELECTED_THEME"; then
    print_warning "Invalid theme '$SELECTED_THEME', using tokyo-night"
    SELECTED_THEME="tokyo-night"
fi

echo ""
print_success "Theme: $SELECTED_THEME"

# ============================================
# 1. INSTALL HOMEBREW
# ============================================
echo ""
print_step "Step 1: Installing Homebrew..."

if ! command -v brew &> /dev/null; then
    print_warning "Homebrew not found. Installing..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Add Homebrew to PATH for Apple Silicon
    if [[ $(uname -m) == 'arm64' ]]; then
        if ! grep -q '/opt/homebrew/bin/brew shellenv' ~/.zprofile 2>/dev/null; then
            # shellcheck disable=SC2016
            echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
        fi
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
    print_success "Homebrew installed"
else
    print_success "Homebrew already installed"
fi

# ============================================
# 2. INSTALL PACKAGES FROM BREWFILE
# ============================================
echo ""
print_step "Step 2: Installing packages from Brewfile..."

source "$DOTFILES_DIR/scripts/package-utils.sh"

# Determine which groups to install
_PACKAGE_SELECTIONS=""

if [[ -n "$SELECTED_GROUPS" ]]; then
    # --groups flag: convert comma-separated list to selections format
    IFS=',' read -ra _groups_arr <<< "$SELECTED_GROUPS"
    for g in "${_groups_arr[@]}"; do
        _PACKAGE_SELECTIONS+="+${g}"$'\n'
    done
    _PACKAGE_SELECTIONS="${_PACKAGE_SELECTIONS%$'\n'}"
    save_selected_groups "$_PACKAGE_SELECTIONS"
elif [[ "$INTERACTIVE" == true ]]; then
    _PACKAGE_SELECTIONS=$(prompt_package_selection "$DOTFILES_DIR/Brewfile")
elif [[ -f "$PACKAGES_STATE_FILE" ]]; then
    _PACKAGE_SELECTIONS=$(get_saved_groups)
fi

cd "$DOTFILES_DIR"
if [[ -n "$_PACKAGE_SELECTIONS" ]]; then
    _FILTERED_BREWFILE=$(generate_filtered_brewfile "$DOTFILES_DIR/Brewfile" "$_PACKAGE_SELECTIONS")
    if brew bundle install --file="$_FILTERED_BREWFILE"; then
        print_success "Selected packages installed"
    else
        print_warning "Some packages failed to install (see errors above). Continuing..."
    fi
    rm -f "$_FILTERED_BREWFILE"
else
    if brew bundle install; then
        print_success "All packages installed"
    else
        print_warning "Some packages failed to install (see errors above). Continuing..."
    fi
fi

# ============================================
# 3. CREATE NECESSARY DIRECTORIES
# ============================================
echo ""
print_step "Step 3: Creating configuration directories..."

mkdir -p ~/.config/{aerospace,ghostty,nvim,zellij,zed/snippets}
mkdir -p ~/.tmux/plugins
mkdir -p ~/bin

print_success "Directories created"

# ============================================
# 4. SET UP MISE (VERSION MANAGER)
# ============================================
echo ""
print_step "Step 4: Setting up mise (version manager)..."

# Create mise config directory
mkdir -p ~/.config/mise

# Link mise configuration
if [ -L ~/.config/mise/config.toml ] && [ "$(readlink ~/.config/mise/config.toml)" = "$DOTFILES_DIR/.config/mise/config.toml" ] && [ "$FORCE_INSTALL" = false ]; then
    print_success "mise config already linked"
else
    backup_if_needed ~/.config/mise/config.toml
    ln -sf "$DOTFILES_DIR/.config/mise/config.toml" ~/.config/mise/config.toml
    print_success "mise config linked"
fi

# Trust the mise config file (required for security)
mise trust ~/.config/mise/config.toml 2>/dev/null || true

# Install all tools defined in mise config
print_step "Installing language runtimes with mise (this may take a few minutes)..."
mise install

print_success "mise configured and tools installed"

# ============================================
# 5. CREATE SYMLINKS
# ============================================
echo ""
print_step "Step 5: Creating symlinks..."

# Helper function to create symlink with idempotent backup
create_symlink() {
    local source="$1"
    local target="$2"
    local name="$3"

    if [ -L "$target" ] && [ "$(readlink "$target")" = "$source" ] && [ "$FORCE_INSTALL" = false ]; then
        print_success "$name already linked"
    else
        backup_if_needed "$target"
        ln -sf "$source" "$target"
        print_success "$name linked"
    fi
}

# Shell configuration
create_symlink "$DOTFILES_DIR/.zshrc" ~/.zshrc ".zshrc"
[[ -f "$DOTFILES_DIR/.zshrc-terminal-enhancements" ]] && create_symlink "$DOTFILES_DIR/.zshrc-terminal-enhancements" ~/.zshrc-terminal-enhancements ".zshrc-terminal-enhancements"

# DHH additions (main Rails workflow file)
[[ -f "$DOTFILES_DIR/.zshrc-dhh-additions" ]] && create_symlink "$DOTFILES_DIR/.zshrc-dhh-additions" ~/.zshrc-dhh-additions ".zshrc-dhh-additions"

# Elixir additions
[[ -f "$DOTFILES_DIR/.zshrc-elixir-additions" ]] && create_symlink "$DOTFILES_DIR/.zshrc-elixir-additions" ~/.zshrc-elixir-additions ".zshrc-elixir-additions"

# Work command completions
[[ -f "$DOTFILES_DIR/.zshrc-work-completions" ]] && create_symlink "$DOTFILES_DIR/.zshrc-work-completions" ~/.zshrc-work-completions ".zshrc-work-completions"

# tmux
create_symlink "$DOTFILES_DIR/.tmux.conf" ~/.tmux.conf ".tmux.conf"

# wezterm (lives under .config/wezterm/, but wezterm also reads ~/.wezterm.lua first)
create_symlink "$DOTFILES_DIR/.config/wezterm/wezterm.lua" ~/.wezterm.lua ".wezterm.lua"

# Git global ignores
[[ -f "$DOTFILES_DIR/.gitignore_global" ]] && create_symlink "$DOTFILES_DIR/.gitignore_global" ~/.gitignore_global ".gitignore_global"

# Config directories
create_symlink "$DOTFILES_DIR/.config/aerospace" ~/.config/aerospace "aerospace config"
create_symlink "$DOTFILES_DIR/.config/ghostty" ~/.config/ghostty "ghostty config"
create_symlink "$DOTFILES_DIR/.config/nvim" ~/.config/nvim "nvim config"
create_symlink "$DOTFILES_DIR/.config/zellij" ~/.config/zellij "zellij config"
create_symlink "$DOTFILES_DIR/.config/starship.toml" ~/.config/starship.toml "starship config"
create_symlink "$DOTFILES_DIR/.config/lazygit" ~/.config/lazygit "lazygit config"
create_symlink "$DOTFILES_DIR/.config/borders" ~/.config/borders "borders config"
create_symlink "$DOTFILES_DIR/.config/sketchybar" ~/.config/sketchybar "sketchybar config"

# Zed editor
create_symlink "$DOTFILES_DIR/.config/zed/settings.json" ~/.config/zed/settings.json "zed settings"
create_symlink "$DOTFILES_DIR/.config/zed/tasks.json" ~/.config/zed/tasks.json "zed tasks"
for snippet in "$DOTFILES_DIR/.config/zed/snippets/"*.json; do
    name=$(basename "$snippet")
    create_symlink "$snippet" ~/.config/zed/snippets/"$name" "zed snippet: $name"
done

# Custom scripts (~/bin)
for script in "$DOTFILES_DIR/bin/"*; do
    name=$(basename "$script")
    create_symlink "$script" ~/bin/"$name" "bin/$name"
done

print_success "All symlinks processed"

# ============================================
# 5b. APPLY SELECTED THEME
# ============================================
echo ""
print_step "Step 5b: Applying $SELECTED_THEME theme everywhere..."

source "$DOTFILES_DIR/scripts/apply-theme.sh"
apply_theme "$SELECTED_THEME"

# ============================================
# 6. INSTALL TPM (TMUX PLUGIN MANAGER) — only if tmux is present
# ============================================
# tmux is no longer in the Brewfile (replaced by zellij), but keep this
# step so users who re-add tmux to their fork still get TPM auto-installed.
if command -v tmux &>/dev/null; then
    echo ""
    print_step "Step 6: Installing TPM (Tmux Plugin Manager)..."
    if [[ ! -d ~/.tmux/plugins/tpm ]]; then
        git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
        print_success "TPM installed"
    else
        print_success "TPM already installed"
    fi
fi

# ============================================
# 7. SET UP NEOVIM
# ============================================
echo ""
print_step "Step 7: Setting up Neovim..."

# AstroNvim will auto-install on first launch
print_success "Neovim configuration linked (plugins will install on first launch)"

# ============================================
# 7b. SET UP AI CLI (llm + ollama)
# ============================================
# Brewfile already installed `llm` and `ollama`. We need to:
#   - Wire `llm` to talk to Ollama (one-time plugin install, fast)
# We deliberately DO NOT pull models here (each is multi-GB) or set API
# keys (private). Those are surfaced in "Next Steps" at end of install.
echo ""
print_step "Step 7b: Wiring llm <-> ollama..."

if command -v llm &>/dev/null; then
    if ! llm plugins 2>/dev/null | grep -q llm-ollama; then
        llm install llm-ollama && print_success "llm-ollama plugin installed"
    else
        print_success "llm-ollama plugin already installed"
    fi
else
    print_warning "llm not found — skipping plugin install (check Brewfile)"
fi

# ============================================
# 8. SET UP SHELL
# ============================================
echo ""
print_step "Step 8: Setting up shell..."

# Make zsh default shell if not already
if [[ "$SHELL" != "$(which zsh)" ]]; then
    print_warning "Setting zsh as default shell..."
    chsh -s "$(which zsh)"
    print_success "Default shell changed to zsh"
else
    print_success "zsh is already the default shell"
fi

# ============================================
# 8b. GIT CONFIGURATION
# ============================================
source "$DOTFILES_DIR/scripts/setup-git.sh"
setup_git

# ============================================
# 8c. SSH CONFIGURATION
# ============================================
source "$DOTFILES_DIR/scripts/setup-ssh.sh"
setup_ssh

# ============================================
# 9. MACOS DEFAULTS
# ============================================
echo ""
if [[ "$INTERACTIVE" == true ]]; then
    read -r -p "Apply recommended macOS defaults? (y/n) " -n 1
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        APPLY_MACOS_DEFAULTS=false
    fi
fi

if [[ "$APPLY_MACOS_DEFAULTS" == true ]]; then
    print_step "Step 9: Applying macOS defaults..."

    # Keyboard settings
    defaults write NSGlobalDomain KeyRepeat -int 2
    defaults write NSGlobalDomain InitialKeyRepeat -int 15

    # Appearance
    defaults write NSGlobalDomain AppleInterfaceStyle -string "Dark"

    # Finder settings
    defaults write com.apple.finder ShowPathbar -bool true
    defaults write com.apple.finder ShowStatusBar -bool true
    defaults write com.apple.finder ShowSidebar -bool true
    defaults write com.apple.finder _FXShowPosixPathInTitle -bool true
    defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"
    defaults write com.apple.finder AppleShowAllFiles -bool true
    defaults write com.apple.finder NewWindowTarget -string "PfHm"
    defaults write com.apple.finder ShowExternalHardDrivesOnDesktop -bool true
    defaults write com.apple.finder ShowHardDrivesOnDesktop -bool true
    defaults write com.apple.finder ShowMountedServersOnDesktop -bool true
    defaults write com.apple.finder ShowRemovableMediaOnDesktop -bool true

    # Dock settings
    defaults write com.apple.dock autohide -bool true
    defaults write com.apple.dock show-recents -bool false
    defaults write com.apple.dock minimize-to-application -bool true
    defaults write com.apple.dock expose-group-apps -bool true

    # Window behavior
    defaults write NSGlobalDomain AppleMiniaturizeOnDoubleClick -bool false
    defaults write NSGlobalDomain com.apple.springing.enabled -bool true
    defaults write NSGlobalDomain com.apple.springing.delay -float 0.5

    # Trackpad settings
    defaults write com.apple.AppleMultitouchTrackpad Clicking -bool true
    defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerDrag -bool true
    defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
    defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadThreeFingerDrag -bool true

    # Menu bar clock
    defaults write com.apple.menuextra.clock ShowDate -int 0
    defaults write com.apple.menuextra.clock ShowDayOfWeek -bool true

    # Hot corners (bottom-right → Quick Note)
    defaults write com.apple.dock wvous-br-corner -int 14
    defaults write com.apple.dock wvous-br-modifier -int 0

    # Restart affected services
    killall Finder 2>/dev/null || true
    killall Dock 2>/dev/null || true

    print_success "macOS defaults applied (24 settings)"
    print_warning "Some settings require logout/restart to take effect"
else
    print_success "macOS defaults skipped"
fi

# ============================================
# 10. RUN HEALTH CHECK
# ============================================
echo ""
print_step "Step 10: Running health check..."
bash "$DOTFILES_DIR/scripts/health-check.sh"

# ============================================
# INSTALLATION COMPLETE
# ============================================
echo ""
echo "  =========================================="
echo "  Installation Complete!"
echo "  =========================================="
echo ""
echo "📋 Next Steps:"
echo ""
echo "1. Restart your terminal or run: source ~/.zshrc"
echo ""
echo "2. Open Neovim to install plugins:"
echo "   nvim"
echo "   (AstroNvim will auto-install)"
echo ""
echo "3. Start Aerospace (will start on next login):"
echo "   aerospace reload"
echo ""
echo "4. Verify mise installations:"
echo "   mise list"
echo ""
echo "5. Sign in to 1Password (recommended for SSH + secrets):"
echo ""
echo "   # a) Open 1Password.app → sign in to your account"
echo "   #    (your vaults sync from cloud automatically)"
echo "   # b) Enable the SSH Agent:"
echo "   #    1Password → Settings → Developer → 'Set Up SSH Agent'"
echo "   # c) Wire the agent into ~/.ssh/config (one-time):"
echo "   bash $DOTFILES_DIR/scripts/setup-ssh.sh"
echo "   # d) Test it:"
echo "   ssh -T git@github.com   # should succeed via Touch ID"
echo ""
echo "   Note: SSH keys must already be in your 1Password vault (synced"
echo "   from another machine, or add them via 1Password → New Item → SSH Key)."
echo ""
echo "6. Set up AI tooling (one-time, optional):"
echo ""
echo "   # Pull a local model (~5GB, ~5 min) — recommended default"
echo "   ollama pull qwen2.5-coder:7b"
echo "   llm models default qwen2.5-coder:7b"
echo ""
echo "   # Optional: a larger general model for harder reasoning"
echo "   ollama pull qwen3:14b"
echo ""
echo "   # Optional: hosted-API plugins for llm"
echo "   llm install llm-anthropic llm-gemini"
echo "   llm keys set anthropic    # paste key when prompted"
echo "   llm keys set openai"
echo ""
echo "   # Authenticate gh + GitHub Copilot CLI (for ghcs / ghce)"
echo "   gh auth login"
echo ""
echo "7. Run health check anytime:"
echo "   bash $DOTFILES_DIR/scripts/health-check.sh"
echo ""
echo "8. Update dotfiles in the future:"
echo "   bash $DOTFILES_DIR/update.sh"
echo ""
echo "🎨 Theme: $SELECTED_THEME (applied everywhere)"
echo "   Switch anytime: dotfiles theme"
echo ""
if [[ -d "$BACKUP_DIR" ]]; then
    echo "🔧 Backup location: $BACKUP_DIR"
    echo ""
fi
echo "Enjoy your new setup! 🚀"
echo ""
