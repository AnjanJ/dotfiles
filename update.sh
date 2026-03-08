#!/usr/bin/env bash

# ============================================
# DOTFILES UPDATE SCRIPT
# ============================================
# Quick update for syncing dotfiles changes
# Usage: bash update.sh
# Supported: macOS, Arch Linux, Ubuntu/Debian
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

# ============================================
# OS DETECTION
# ============================================
OS="unknown"
DISTRO="unknown"

case "$(uname -s)" in
    Darwin)
        OS="macos"
        ;;
    Linux)
        OS="linux"
        if [ -f /etc/os-release ]; then
            . /etc/os-release
            case "$ID" in
                arch|manjaro|endeavouros)
                    DISTRO="arch"
                    ;;
                ubuntu|debian|pop|linuxmint|elementary)
                    DISTRO="debian"
                    ;;
                fedora|rhel|centos)
                    DISTRO="fedora"
                    ;;
                *)
                    DISTRO="$ID"
                    ;;
            esac
        fi
        ;;
    *)
        print_error "Unsupported operating system: $(uname -s)"
        exit 1
        ;;
esac

is_macos() { [[ "$OS" == "macos" ]]; }
is_linux() { [[ "$OS" == "linux" ]]; }

# Get dotfiles directory
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo ""
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║                                                           ║"
echo "║   🔄  AJ's Dotfiles Update                                ║"
echo "║                                                           ║"
echo "║   This will:                                              ║"
echo "║   • Pull latest changes from git                          ║"
echo "║   • Update Homebrew packages                              ║"
echo "║   • Refresh symlinks                                      ║"
echo "║   • Update mise tools                                     ║"
echo "║   • Update tmux plugins                                   ║"
echo "║                                                           ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""

# Ask for confirmation
read -p "Continue with update? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_warning "Update cancelled"
    exit 1
fi

# ============================================
# 1. GIT PULL
# ============================================
echo ""
print_step "Step 1: Pulling latest changes..."

cd "$DOTFILES_DIR"

# Check if there are uncommitted changes
if [[ -n $(git status -s) ]]; then
    print_warning "You have uncommitted changes in dotfiles repo"
    echo ""
    git status -s
    echo ""
    read -p "Stash changes and continue? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        git stash push -m "Auto-stash before update $(date +%Y%m%d_%H%M%S)"
        print_success "Changes stashed"
    else
        print_error "Please commit or stash your changes first"
        exit 1
    fi
fi

git pull origin main
print_success "Repository updated"

# ============================================
# 2. UPDATE PACKAGES
# ============================================
echo ""
print_step "Step 2: Updating packages..."

if is_macos; then
    # Update Homebrew itself
    brew update

    # Install any new packages from Brewfile
    brew bundle install

    # Upgrade existing packages
    read -p "Upgrade existing packages? This may take a while. (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        brew upgrade
        brew cleanup
        print_success "Packages upgraded"
    else
        print_success "Skipped package upgrade"
    fi

    print_success "Homebrew updated"

elif is_linux; then
    # TODO: Add Linux package updates
    # Arch: sudo pacman -Syu
    # Debian/Ubuntu: sudo apt update && sudo apt upgrade
    print_warning "Linux package update not yet implemented"
fi

# ============================================
# 3. REFRESH SYMLINKS
# ============================================
echo ""
print_step "Step 3: Refreshing symlinks..."

# Helper function to create symlink
create_symlink() {
    local source="$1"
    local target="$2"
    local name="$3"

    if [ -L "$target" ] && [ "$(readlink "$target")" = "$source" ]; then
        print_success "$name already up to date"
    else
        ln -sf "$source" "$target"
        print_success "$name refreshed"
    fi
}

# Shell configuration
create_symlink "$DOTFILES_DIR/.zshrc" ~/.zshrc ".zshrc"
[[ -f "$DOTFILES_DIR/.zshrc-aliases" ]] && create_symlink "$DOTFILES_DIR/.zshrc-aliases" ~/.zshrc-aliases ".zshrc-aliases"
[[ -f "$DOTFILES_DIR/.zshrc-terminal-enhancements" ]] && create_symlink "$DOTFILES_DIR/.zshrc-terminal-enhancements" ~/.zshrc-terminal-enhancements ".zshrc-terminal-enhancements"
[[ -f "$DOTFILES_DIR/.zshrc-dhh-additions" ]] && create_symlink "$DOTFILES_DIR/.zshrc-dhh-additions" ~/.zshrc-dhh-additions ".zshrc-dhh-additions"
[[ -f "$DOTFILES_DIR/.zshrc-elixir-additions" ]] && create_symlink "$DOTFILES_DIR/.zshrc-elixir-additions" ~/.zshrc-elixir-additions ".zshrc-elixir-additions"

# tmux
create_symlink "$DOTFILES_DIR/.tmux.conf" ~/.tmux.conf ".tmux.conf"

# Config directories
if is_macos; then
    create_symlink "$DOTFILES_DIR/.config/aerospace" ~/.config/aerospace "aerospace config"
fi
create_symlink "$DOTFILES_DIR/.config/ghostty" ~/.config/ghostty "ghostty config"
create_symlink "$DOTFILES_DIR/.config/nvim" ~/.config/nvim "nvim config"
create_symlink "$DOTFILES_DIR/.config/zellij" ~/.config/zellij "zellij config"
create_symlink "$DOTFILES_DIR/.config/starship.toml" ~/.config/starship.toml "starship config"
create_symlink "$DOTFILES_DIR/.config/mise/config.toml" ~/.config/mise/config.toml "mise config"

# Zed editor
mkdir -p ~/.config/zed/snippets
create_symlink "$DOTFILES_DIR/.config/zed/settings.json" ~/.config/zed/settings.json "zed settings"
create_symlink "$DOTFILES_DIR/.config/zed/tasks.json" ~/.config/zed/tasks.json "zed tasks"
for snippet in "$DOTFILES_DIR/.config/zed/snippets/"*.json; do
    name=$(basename "$snippet")
    create_symlink "$snippet" ~/.config/zed/snippets/"$name" "zed snippet: $name"
done

# Custom scripts (~/bin)
mkdir -p ~/bin
for script in "$DOTFILES_DIR/bin/"*; do
    name=$(basename "$script")
    create_symlink "$script" ~/bin/"$name" "bin/$name"
done

print_success "Symlinks refreshed"

# ============================================
# 4. UPDATE MISE TOOLS
# ============================================
echo ""
print_step "Step 4: Updating mise tools..."

# Trust the config again (in case it changed)
mise trust ~/.config/mise/config.toml 2>/dev/null || true

# Update mise itself
mise self-update || print_warning "mise self-update not available (might need sudo)"

# Update all installed tools
mise upgrade

print_success "mise tools updated"

# ============================================
# 5. UPDATE TMUX PLUGINS
# ============================================
echo ""
print_step "Step 5: Updating tmux plugins..."

if [[ -d ~/.tmux/plugins/tpm ]]; then
    # Update TPM itself
    cd ~/.tmux/plugins/tpm
    git pull origin master

    # Update all plugins
    ~/.tmux/plugins/tpm/bin/update_plugins all
    print_success "tmux plugins updated"
else
    print_warning "TPM not found. Run install.sh first"
fi

# ============================================
# 6. RELOAD CONFIGURATIONS
# ============================================
echo ""
print_step "Step 6: Reloading configurations..."

# Reload tmux config if tmux is running
if command -v tmux &> /dev/null && tmux info &> /dev/null 2>&1; then
    tmux source-file ~/.tmux.conf
    print_success "tmux config reloaded"
fi

# Reload aerospace if running (macOS only)
if is_macos; then
    if pgrep -x "Aerospace" > /dev/null; then
        aerospace reload-config
        print_success "Aerospace config reloaded"
    else
        print_warning "Aerospace not running"
    fi
fi

# ============================================
# UPDATE COMPLETE
# ============================================
echo ""
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║                                                           ║"
echo "║   ✅  Update Complete!                                    ║"
echo "║                                                           ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""
echo "📋 Next Steps:"
echo ""
echo "1. Restart your terminal or run:"
echo "   source ~/.zshrc"
echo ""
echo "2. Verify versions:"
echo "   mise list"
echo "   brew list --versions"
echo ""
echo "3. Check for any warnings above"
echo ""
echo "🎉 Your dotfiles are now up to date!"
echo ""
