#!/usr/bin/env bash

# ============================================
# DOTFILES INSTALLATION SCRIPT
# ============================================
# One-command setup for macOS development environment
# Usage: bash install.sh
# ============================================

set -e  # Exit on error

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
echo "║   • Starship prompt                                       ║"
echo "║   • Shell configuration                                   ║"
echo "║   • Tokyo Night theme everywhere                          ║"
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

mkdir -p ~/.config/{aerospace,ghostty,nvim,zellij}
mkdir -p ~/.tmux/plugins

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
ln -sf "$DOTFILES_DIR/.config/mise/config.toml" ~/.config/mise/config.toml

# Trust the mise config file (required for security)
mise trust ~/.config/mise/config.toml

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

# Shell configuration
ln -sf "$DOTFILES_DIR/.zshrc" ~/.zshrc
[[ -f "$DOTFILES_DIR/.zshrc-aliases" ]] && ln -sf "$DOTFILES_DIR/.zshrc-aliases" ~/.zshrc-aliases
[[ -f "$DOTFILES_DIR/.zshrc-terminal-enhancements" ]] && ln -sf "$DOTFILES_DIR/.zshrc-terminal-enhancements" ~/.zshrc-terminal-enhancements

# tmux
ln -sf "$DOTFILES_DIR/.tmux.conf" ~/.tmux.conf

# Config directories
ln -sf "$DOTFILES_DIR/.config/aerospace" ~/.config/aerospace
ln -sf "$DOTFILES_DIR/.config/ghostty" ~/.config/ghostty
ln -sf "$DOTFILES_DIR/.config/nvim" ~/.config/nvim
ln -sf "$DOTFILES_DIR/.config/zellij" ~/.config/zellij
ln -sf "$DOTFILES_DIR/.config/starship.toml" ~/.config/starship.toml

print_success "Symlinks created"

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

    # Finder settings
    defaults write com.apple.finder ShowPathbar -bool true
    defaults write com.apple.finder ShowStatusBar -bool true
    defaults write com.apple.finder _FXShowPosixPathInTitle -bool true

    # Dock settings
    defaults write com.apple.dock autohide -bool true
    defaults write com.apple.dock show-recents -bool false

    print_success "macOS defaults applied"
    print_warning "Some settings require logout/restart to take effect"
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
echo "5. Configure Git:"
echo "   git config --global user.name \"Your Name\""
echo "   git config --global user.email \"your.email@example.com\""
echo ""
echo "6. Verify mise installations:"
echo "   mise list       # See all installed versions"
echo "   ruby --version  # Should show Ruby 3.4.5"
echo "   node --version  # Should show latest"
echo "   elixir --version # Should show latest"
echo ""
echo "📚 Documentation:"
echo "   • Neovim guide: ~/.config/nvim/README.md"
echo "   • tmux guide: $DOTFILES_DIR/docs/tmux-guide.md"
echo "   • Zellij guide: $DOTFILES_DIR/docs/zellij-guide.md"
echo ""
echo "🎨 Theme: Tokyo Night (everywhere)"
echo ""
echo "🔧 Backup location: $BACKUP_DIR"
echo ""
echo "Enjoy your new setup! 🚀"
echo ""
