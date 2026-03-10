#!/usr/bin/env bash

# ============================================
# DOTFILES INSTALLATION SCRIPT
# ============================================
# One-command setup for macOS development environment
# Usage: bash install.sh
# ============================================

set -e  # Exit on error

# Parse command line arguments
FORCE_INSTALL=false
for arg in "$@"; do
    case $arg in
        --force)
            FORCE_INSTALL=true
            shift
            ;;
        --help)
            echo "Usage: bash install.sh [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --force    Force reinstallation even if already installed"
            echo "  --help     Show this help message"
            exit 0
            ;;
    esac
done

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
print_step() {
    echo -e "${BLUE}==>${NC} ${GREEN}$1${NC}"
}

print_warning() {
    echo -e "${YELLOW}Warning:${NC} $1"
}

print_error() {
    echo -e "${RED}Error:${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

# Check if running on macOS
if [[ "$(uname)" != "Darwin" ]]; then
    print_error "This script is only for macOS"
    exit 1
fi

echo ""
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║                                                           ║"
echo "║   🚀  AJ's Dotfiles Installation                          ║"
echo "║                                                           ║"
echo "║   This will install:                                      ║"
echo "║   • Homebrew packages                                     ║"
echo "║   • Aerospace (window manager)                            ║"
echo "║   • Ghostty terminal                                      ║"
echo "║   • Neovim + AstroNvim                                    ║"
echo "║   • tmux + plugins                                        ║"
echo "║   • Zellij                                                ║"
echo "║   • Zed editor (settings, snippets, tasks)                ║"
echo "║   • Starship prompt                                       ║"
echo "║   • Shell configuration                                   ║"
echo "║   • Git smart defaults (rerere, histogram, etc.)         ║"
echo "║   • Custom scripts (~/bin)                                ║"
echo "║   • Theme: Tokyo Night or Aura (your choice!)              ║"
echo "║                                                           ║"
echo "║   💡 Tip: Script is idempotent - safe to re-run          ║"
echo "║   Use --force to override existing configs               ║"
echo "║                                                           ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""

# Ask for confirmation
read -p "Continue with installation? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_warning "Installation cancelled"
    exit 1
fi

# Get dotfiles directory
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo ""
print_step "Dotfiles directory: $DOTFILES_DIR"

# ============================================
# THEME SELECTION
# ============================================
source "$DOTFILES_DIR/scripts/theme-utils.sh"

SELECTED_THEME=$(prompt_theme_choice)
echo ""
print_success "Theme selected: $SELECTED_THEME"

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
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
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

cd "$DOTFILES_DIR"
brew bundle install

print_success "All packages installed"

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
# 4. BACKUP EXISTING CONFIGURATIONS
# ============================================
echo ""
print_step "Step 4: Backing up existing configurations..."

BACKUP_DIR="$HOME/.dotfiles_backup_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

# Backup files if they exist
[[ -f ~/.zshrc ]] && cp ~/.zshrc "$BACKUP_DIR/"
[[ -f ~/.tmux.conf ]] && cp ~/.tmux.conf "$BACKUP_DIR/"
[[ -d ~/.config/nvim ]] && cp -r ~/.config/nvim "$BACKUP_DIR/"
[[ -d ~/.config/aerospace ]] && cp -r ~/.config/aerospace "$BACKUP_DIR/"
[[ -d ~/.config/ghostty ]] && cp -r ~/.config/ghostty "$BACKUP_DIR/"
[[ -d ~/.config/zellij ]] && cp -r ~/.config/zellij "$BACKUP_DIR/"
[[ -d ~/.config/zed ]] && cp -r ~/.config/zed "$BACKUP_DIR/"
[[ -f ~/.config/starship.toml ]] && cp ~/.config/starship.toml "$BACKUP_DIR/"

print_success "Backup created at: $BACKUP_DIR"

# ============================================
# 5. SET UP MISE (VERSION MANAGER)
# ============================================
echo ""
print_step "Step 5: Setting up mise (version manager)..."

# Create mise config directory
mkdir -p ~/.config/mise

# Link mise configuration
if [ -L ~/.config/mise/config.toml ] && [ "$FORCE_INSTALL" = false ]; then
    print_success "mise config already linked"
else
    ln -sf "$DOTFILES_DIR/.config/mise/config.toml" ~/.config/mise/config.toml
    print_success "mise config linked"
fi

# Trust the mise config file (required for security)
mise trust ~/.config/mise/config.toml 2>/dev/null || true

# Initialize mise in shell (will be sourced from .zshrc)
if ! grep -q "mise activate" ~/.zshrc 2>/dev/null; then
    print_warning "Note: mise activation already in .zshrc"
fi

# Install all tools defined in mise config
print_step "Installing language runtimes with mise (this may take a few minutes)..."
mise install

print_success "mise configured and tools installed"

# ============================================
# 6. CREATE SYMLINKS
# ============================================
echo ""
print_step "Step 6: Creating symlinks..."

# Helper function to create symlink with check
create_symlink() {
    local source="$1"
    local target="$2"
    local name="$3"

    if [ -L "$target" ] && [ "$(readlink "$target")" = "$source" ] && [ "$FORCE_INSTALL" = false ]; then
        print_success "$name already linked"
    else
        ln -sf "$source" "$target"
        print_success "$name linked"
    fi
}

# Shell configuration
create_symlink "$DOTFILES_DIR/.zshrc" ~/.zshrc ".zshrc"
[[ -f "$DOTFILES_DIR/.zshrc-aliases" ]] && create_symlink "$DOTFILES_DIR/.zshrc-aliases" ~/.zshrc-aliases ".zshrc-aliases"
[[ -f "$DOTFILES_DIR/.zshrc-terminal-enhancements" ]] && create_symlink "$DOTFILES_DIR/.zshrc-terminal-enhancements" ~/.zshrc-terminal-enhancements ".zshrc-terminal-enhancements"

# DHH additions (main Rails workflow file)
[[ -f "$DOTFILES_DIR/.zshrc-dhh-additions" ]] && create_symlink "$DOTFILES_DIR/.zshrc-dhh-additions" ~/.zshrc-dhh-additions ".zshrc-dhh-additions"

# Elixir additions
[[ -f "$DOTFILES_DIR/.zshrc-elixir-additions" ]] && create_symlink "$DOTFILES_DIR/.zshrc-elixir-additions" ~/.zshrc-elixir-additions ".zshrc-elixir-additions"

# tmux
create_symlink "$DOTFILES_DIR/.tmux.conf" ~/.tmux.conf ".tmux.conf"

# Config directories
create_symlink "$DOTFILES_DIR/.config/aerospace" ~/.config/aerospace "aerospace config"
create_symlink "$DOTFILES_DIR/.config/ghostty" ~/.config/ghostty "ghostty config"
create_symlink "$DOTFILES_DIR/.config/nvim" ~/.config/nvim "nvim config"
create_symlink "$DOTFILES_DIR/.config/zellij" ~/.config/zellij "zellij config"
create_symlink "$DOTFILES_DIR/.config/starship.toml" ~/.config/starship.toml "starship config"

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
# 6b. APPLY SELECTED THEME
# ============================================
echo ""
print_step "Step 6b: Applying $SELECTED_THEME theme everywhere..."

source "$DOTFILES_DIR/scripts/apply-theme.sh"
apply_theme "$SELECTED_THEME"

# ============================================
# 7. INSTALL TPM (TMUX PLUGIN MANAGER)
# ============================================
echo ""
print_step "Step 7: Installing TPM (Tmux Plugin Manager)..."

if [[ ! -d ~/.tmux/plugins/tpm ]]; then
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
    print_success "TPM installed"
else
    print_success "TPM already installed"
fi

# ============================================
# 8. SET UP NEOVIM
# ============================================
echo ""
print_step "Step 8: Setting up Neovim..."

# AstroNvim will auto-install on first launch
print_success "Neovim configuration linked (plugins will install on first launch)"

# ============================================
# 9. SET UP SHELL
# ============================================
echo ""
print_step "Step 9: Setting up shell..."

# Make zsh default shell if not already
if [[ "$SHELL" != "$(which zsh)" ]]; then
    print_warning "Setting zsh as default shell..."
    chsh -s "$(which zsh)"
    print_success "Default shell changed to zsh"
else
    print_success "zsh is already the default shell"
fi

# ============================================
# 9b. GIT CONFIGURATION
# ============================================
echo ""
print_step "Step 9b: Configuring Git defaults..."

# Set default editor to Zed
git config --global core.editor "zed --wait"

# Merge on pull (no auto-rebase)
git config --global pull.rebase false

# Global gitignore
ln -sf "$DOTFILES_DIR/.gitignore_global" ~/.gitignore_global
git config --global core.excludesfile ~/.gitignore_global

# Better diff algorithm (handles moved code blocks better)
git config --global diff.algorithm histogram

# Reuse Recorded Resolution — auto-resolve repeated merge conflicts
git config --global rerere.enabled true

# Auto set upstream on first push (no more `git push -u origin branch`)
git config --global push.autoSetupRemote true

# Show most recent branches first
git config --global branch.sort -committerdate

# Show full diff in commit message editor
git config --global commit.verbose true

print_success "Git defaults configured (editor, pull, diff, rerere, push, branch sort)"

# ── Git Identity Setup ─────────────────────────────
echo ""
print_step "Setting up Git identity..."

# Back up existing git configs before modifying
if [[ -f ~/.gitconfig ]]; then
    cp ~/.gitconfig "$BACKUP_DIR/.gitconfig"
    print_success "Backed up ~/.gitconfig → $BACKUP_DIR/.gitconfig"
fi
if [[ -f ~/.gitconfig-work ]]; then
    cp ~/.gitconfig-work "$BACKUP_DIR/.gitconfig-work"
    print_success "Backed up ~/.gitconfig-work → $BACKUP_DIR/.gitconfig-work"
fi

echo ""
echo "Your personal Git identity will be used everywhere by default."
echo ""

# Show existing identity if any
EXISTING_NAME=$(git config --global user.name 2>/dev/null || true)
EXISTING_EMAIL=$(git config --global user.email 2>/dev/null || true)
if [[ -n "$EXISTING_NAME" || -n "$EXISTING_EMAIL" ]]; then
    echo "  Current identity: ${EXISTING_NAME:-<not set>} <${EXISTING_EMAIL:-<not set>}>"
    echo "  (backed up to $BACKUP_DIR — restore anytime with: cp $BACKUP_DIR/.gitconfig ~/.gitconfig)"
    echo ""
fi

# Personal identity
read -p "Your full name (for Git commits): " GIT_NAME
read -p "Your personal email: " GIT_PERSONAL_EMAIL

if [[ -n "$GIT_NAME" && -n "$GIT_PERSONAL_EMAIL" ]]; then
    git config --global user.name "$GIT_NAME"
    git config --global user.email "$GIT_PERSONAL_EMAIL"
    print_success "Personal Git identity: $GIT_NAME <$GIT_PERSONAL_EMAIL>"
else
    print_warning "Skipped — set manually: git config --global user.name / user.email"
fi

# Work identity (optional)
echo ""
read -p "Do you have a separate work Git identity? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    read -p "Work email: " GIT_WORK_EMAIL
    read -p "Work directory [~/work]: " WORK_DIR_INPUT
    WORK_DIR="${WORK_DIR_INPUT:-$HOME/work}"

    # Expand ~ to $HOME if user typed it
    WORK_DIR="${WORK_DIR/#\~/$HOME}"

    if [[ -n "$GIT_WORK_EMAIL" ]]; then
        # Create work directory
        mkdir -p "$WORK_DIR"
        print_success "Work directory created: $WORK_DIR"

        # Create ~/.gitconfig-work with work email
        cat > ~/.gitconfig-work <<EOF
[user]
    email = $GIT_WORK_EMAIL
EOF
        print_success "Created ~/.gitconfig-work"

        # Add includeIf to global config (must be at the end to override defaults)
        # Remove any existing includeIf for work dir first (idempotent)
        git config --global --unset-all "includeIf.gitdir:${WORK_DIR}/.path" 2>/dev/null || true
        git config --global "includeIf.gitdir:${WORK_DIR}/.path" "~/.gitconfig-work"

        print_success "Work identity configured: $GIT_NAME <$GIT_WORK_EMAIL>"
        echo ""
        echo "  How it works:"
        echo "  • Repos in $WORK_DIR/ → $GIT_WORK_EMAIL"
        echo "  • Repos everywhere else → $GIT_PERSONAL_EMAIL"
        echo "  • Verify: cd into a repo and run 'git config user.email'"
    else
        print_warning "No work email provided, skipping work identity"
    fi
else
    print_success "Single identity configured — work setup skipped"
fi

# Create personal projects directory too
mkdir -p "${PROJECTS_DIR:-$HOME/code}"

# ============================================
# 10. MACOS DEFAULTS (OPTIONAL)
# ============================================
echo ""
read -p "Apply recommended macOS defaults? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_step "Step 10: Applying macOS defaults..."

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
fi

# ============================================
# 11. RUN HEALTH CHECK
# ============================================
echo ""
read -p "Run health check to verify installation? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_step "Step 11: Running health check..."
    bash "$DOTFILES_DIR/scripts/health-check.sh"
fi

# ============================================
# INSTALLATION COMPLETE
# ============================================
echo ""
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║                                                           ║"
echo "║   ✅  Installation Complete!                              ║"
echo "║                                                           ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""
echo "📋 Next Steps:"
echo ""
echo "1. Restart your terminal or run: source ~/.zshrc"
echo ""
echo "2. Open tmux and install plugins:"
echo "   tmux"
echo "   Press: Ctrl+A then Shift+I"
echo ""
echo "3. Open Neovim to install plugins:"
echo "   nvim"
echo "   (AstroNvim will auto-install)"
echo ""
echo "4. Start Aerospace (will start on next login):"
echo "   aerospace reload"
echo ""
echo "5. Git identity (configured during install):"
echo "   Verify: cd into any repo and run 'git config user.email'"
echo "   Smart defaults: histogram diffs, rerere, autoSetupRemote, branch sort, verbose commits"
echo ""
echo "6. Verify mise installations:"
echo "   mise list       # See all installed versions"
echo "   ruby --version  # Should show Ruby 3.4.5"
echo "   node --version  # Should show latest"
echo "   elixir --version # Should show latest"
echo ""
echo "7. Run health check anytime:"
echo "   bash $DOTFILES_DIR/scripts/health-check.sh"
echo ""
echo "8. Update dotfiles in the future:"
echo "   bash $DOTFILES_DIR/update.sh"
echo ""
echo "📚 Documentation:"
echo "   • Neovim guide: ~/.config/nvim/README.md"
echo "   • tmux guide: $DOTFILES_DIR/docs/tmux-guide.md"
echo "   • Zellij guide: $DOTFILES_DIR/docs/zellij-guide.md"
echo ""
echo "🎨 Theme: $SELECTED_THEME (applied everywhere)"
echo "   Switch anytime: bash $DOTFILES_DIR/switch-theme.sh"
echo ""
echo "🔧 Backup location: $BACKUP_DIR"
echo ""
echo "Enjoy your new setup! 🚀"
echo ""
