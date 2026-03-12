#!/usr/bin/env bash

# ============================================
# DOTFILES UPDATE SCRIPT
# ============================================
# Keeps your system and dotfiles repo in sync.
#
# What it does:
#   1. Pull latest dotfiles from git
#   2. Upgrade Homebrew packages & snapshot Brewfile
#   3. Refresh symlinks & theme
#   4. Upgrade mise tools (config auto-syncs via symlink)
#   5. Update tmux plugins
#   6. Reload live configs (tmux, aerospace)
#   7. Commit & push any changes back to repo
#
# Usage: bash update.sh [--interactive]
# ============================================

INTERACTIVE=false

for arg in "$@"; do
    case $arg in
        --interactive) INTERACTIVE=true ;;
        --help)
            echo "Usage: bash update.sh [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --interactive  Prompt before each step"
            echo "  --help         Show this help message"
            exit 0
            ;;
    esac
done

set -euo pipefail

# Get dotfiles directory
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
echo "  AJ's Dotfiles Update"
echo "  =========================================="
echo ""
echo "  This will:"
echo "    - Pull latest changes from git"
echo "    - Upgrade Homebrew & snapshot Brewfile"
echo "    - Refresh symlinks"
echo "    - Upgrade mise tools"
echo "    - Update tmux plugins"
echo "    - Push changes back to repo"
echo ""
echo ""

if [[ "$INTERACTIVE" == true ]]; then
    read -r -p "Continue with update? (y/n) " -n 1
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_warning "Update cancelled"
        exit 1
    fi
fi

# ============================================
# 1. GIT PULL
# ============================================
echo ""
print_step "Step 1: Pulling latest changes..."

cd "$DOTFILES_DIR"

# Stash uncommitted changes so git pull doesn't conflict, then restore them
DID_STASH=false
if [[ -n $(git status -s) ]]; then
    print_warning "Uncommitted changes detected — stashing temporarily for pull"
    git stash push -m "Auto-stash before update $(date +%Y%m%d_%H%M%S)"
    DID_STASH=true
fi

git pull origin main
print_success "Repository updated"

# Restore stashed changes immediately after pull
if [[ "$DID_STASH" == true ]]; then
    git stash pop || print_warning "Stash pop had conflicts — resolve manually"
    print_success "Uncommitted changes restored"
fi

# ============================================
# 2. UPDATE HOMEBREW & SNAPSHOT BREWFILE
# ============================================
echo ""
print_step "Step 2: Updating Homebrew packages..."

# Update Homebrew itself
brew update

# Upgrade already-installed packages
brew upgrade
brew cleanup

print_success "Homebrew packages upgraded"

# Snapshot: dump current system state into Brewfile
echo ""
print_step "Step 2b: Snapshotting Brewfile..."

# Rotate backup: remove old backup, keep only one
if [[ -f "$DOTFILES_DIR/Brewfile.backup" ]]; then
    rm "$DOTFILES_DIR/Brewfile.backup"
fi
if [[ -f "$DOTFILES_DIR/Brewfile" ]]; then
    cp "$DOTFILES_DIR/Brewfile" "$DOTFILES_DIR/Brewfile.backup"
    print_success "Previous Brewfile saved to Brewfile.backup"
fi

# Dump current state (captures brew, casks, mas, vscode, taps, go, uv)
brew bundle dump --file="$DOTFILES_DIR/Brewfile" --force
print_success "Brewfile snapshot taken"
echo "  Tip: Run 'dotfiles cleanup' to find packages not in Brewfile"

# Show what changed
if [[ -f "$DOTFILES_DIR/Brewfile.backup" ]]; then
    BREW_ADDED_LINES=$(diff "$DOTFILES_DIR/Brewfile.backup" "$DOTFILES_DIR/Brewfile" 2>/dev/null | grep "^> " | sed 's/^> //' || true)
    BREW_REMOVED_LINES=$(diff "$DOTFILES_DIR/Brewfile.backup" "$DOTFILES_DIR/Brewfile" 2>/dev/null | grep "^< " | sed 's/^< //' || true)
    BREW_ADDED_COUNT=$(echo "$BREW_ADDED_LINES" | grep -c . || true)
    BREW_REMOVED_COUNT=$(echo "$BREW_REMOVED_LINES" | grep -c . || true)

    if [[ "$BREW_ADDED_COUNT" -gt 0 || "$BREW_REMOVED_COUNT" -gt 0 ]]; then
        echo -e "  ${YELLOW}+${BREW_ADDED_COUNT} added, -${BREW_REMOVED_COUNT} removed since last snapshot${NC}"
        if [[ -n "$BREW_ADDED_LINES" ]]; then
            while IFS= read -r line; do
                [[ -z "$line" ]] && continue
                echo -e "    ${GREEN}+ $line${NC}"
            done <<< "$BREW_ADDED_LINES"
        fi
        if [[ -n "$BREW_REMOVED_LINES" ]]; then
            while IFS= read -r line; do
                [[ -z "$line" ]] && continue
                echo -e "    ${RED}- $line${NC}"
            done <<< "$BREW_REMOVED_LINES"
        fi
    else
        echo -e "  ${GREEN}No changes since last snapshot${NC}"
    fi
fi

# In interactive mode, also install anything in Brewfile missing from system
if [[ "$INTERACTIVE" == true ]]; then
    read -r -p "Install any missing Brewfile packages? This may require your password. (y/n) " -n 1
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        brew bundle install --no-lock --file="$DOTFILES_DIR/Brewfile"
        print_success "Brewfile synced to system"
    else
        print_success "Skipped Brewfile sync"
    fi
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
[[ -f "$DOTFILES_DIR/.zshrc-terminal-enhancements" ]] && create_symlink "$DOTFILES_DIR/.zshrc-terminal-enhancements" ~/.zshrc-terminal-enhancements ".zshrc-terminal-enhancements"
[[ -f "$DOTFILES_DIR/.zshrc-dhh-additions" ]] && create_symlink "$DOTFILES_DIR/.zshrc-dhh-additions" ~/.zshrc-dhh-additions ".zshrc-dhh-additions"
[[ -f "$DOTFILES_DIR/.zshrc-elixir-additions" ]] && create_symlink "$DOTFILES_DIR/.zshrc-elixir-additions" ~/.zshrc-elixir-additions ".zshrc-elixir-additions"
[[ -f "$DOTFILES_DIR/.zshrc-work-completions" ]] && create_symlink "$DOTFILES_DIR/.zshrc-work-completions" ~/.zshrc-work-completions ".zshrc-work-completions"

# tmux
create_symlink "$DOTFILES_DIR/.tmux.conf" ~/.tmux.conf ".tmux.conf"

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
mise self-update --yes 2>/dev/null || print_warning "mise self-update not available"

# Upgrade all installed tools
# Note: mise config is symlinked to the repo, so any changes
# (e.g. 'mise use python@3.13') are already tracked automatically.
mise upgrade --yes 2>/dev/null || mise install

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

# Reload aerospace if running
if pgrep -x "Aerospace" > /dev/null; then
    aerospace reload-config
    print_success "Aerospace config reloaded"
else
    print_warning "Aerospace not running"
fi

# ============================================
# 7. COMMIT & PUSH CHANGES
# ============================================
echo ""
print_step "Step 7: Syncing dotfiles repo..."

cd "$DOTFILES_DIR"

CURRENT_BRANCH=$(git branch --show-current)

if [[ "$CURRENT_BRANCH" != "main" ]]; then
    print_warning "On branch '$CURRENT_BRANCH' — skipping auto-commit/push (only runs on main)"
elif [[ -n $(git status -s) ]]; then
    # Stage snapshot files and any other tracked changes
    git add Brewfile Brewfile.backup .config/mise/config.toml 2>/dev/null || true
    git add -u

    CHANGES=$(git diff --cached --stat | tail -1)
    git commit -m "update: snapshot system state

$CHANGES"

    git push origin main
    print_success "Changes pushed to repo"
else
    print_success "Repo already in sync"
fi

# ============================================
# UPDATE COMPLETE
# ============================================
echo ""
echo "  =========================================="
echo "  Update Complete!"
echo "  =========================================="
echo ""
echo "   Restart your terminal or run: source ~/.zshrc"
echo ""
