#!/usr/bin/env bash

# ============================================
# DOTFILES HEALTH CHECK SCRIPT
# ============================================
# Verifies that all tools are installed and configured correctly
# Usage: bash scripts/health-check.sh
# ============================================

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Counters
PASSED=0
FAILED=0
WARNINGS=0

# Helper functions
print_header() {
    echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
}

check_command() {
    local cmd="$1"
    local name="$2"
    local required="${3:-true}"

    if command -v "$cmd" &> /dev/null; then
        local version=$($cmd --version 2>&1 | head -n 1)
        echo -e "${GREEN}✓${NC} $name: ${GREEN}installed${NC} ($version)"
        ((PASSED++))
        return 0
    else
        if [[ "$required" == "true" ]]; then
            echo -e "${RED}✗${NC} $name: ${RED}NOT FOUND${NC}"
            ((FAILED++))
        else
            echo -e "${YELLOW}⚠${NC} $name: ${YELLOW}not installed (optional)${NC}"
            ((WARNINGS++))
        fi
        return 1
    fi
}

check_file() {
    local file="$1"
    local name="$2"
    local type="${3:-file}"  # file, link, or dir

    if [[ "$type" == "link" ]]; then
        if [ -L "$file" ]; then
            local target=$(readlink "$file")
            echo -e "${GREEN}✓${NC} $name: ${GREEN}linked${NC} → $target"
            ((PASSED++))
            return 0
        else
            echo -e "${RED}✗${NC} $name: ${RED}not a symlink${NC}"
            ((FAILED++))
            return 1
        fi
    elif [[ "$type" == "dir" ]]; then
        if [ -d "$file" ]; then
            echo -e "${GREEN}✓${NC} $name: ${GREEN}exists${NC}"
            ((PASSED++))
            return 0
        else
            echo -e "${RED}✗${NC} $name: ${RED}not found${NC}"
            ((FAILED++))
            return 1
        fi
    else
        if [ -f "$file" ]; then
            echo -e "${GREEN}✓${NC} $name: ${GREEN}exists${NC}"
            ((PASSED++))
            return 0
        else
            echo -e "${RED}✗${NC} $name: ${RED}not found${NC}"
            ((FAILED++))
            return 1
        fi
    fi
}

check_mise_tool() {
    local tool="$1"
    local name="$2"

    if mise list "$tool" 2>/dev/null | grep -q "$tool"; then
        local version=$(mise current "$tool" 2>/dev/null)
        echo -e "${GREEN}✓${NC} $name: ${GREEN}installed${NC} (${version})"
        ((PASSED++))
        return 0
    else
        echo -e "${RED}✗${NC} $name: ${RED}not installed${NC}"
        ((FAILED++))
        return 1
    fi
}

check_brew_package() {
    local package="$1"
    local name="$2"

    if brew list "$package" &> /dev/null; then
        local version=$(brew list --versions "$package" | awk '{print $2}')
        echo -e "${GREEN}✓${NC} $name: ${GREEN}installed${NC} (${version})"
        ((PASSED++))
        return 0
    else
        echo -e "${RED}✗${NC} $name: ${RED}not installed${NC}"
        ((FAILED++))
        return 1
    fi
}

# ============================================
# START HEALTH CHECK
# ============================================

echo ""
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║                                                           ║"
echo "║   🏥  Dotfiles Health Check                               ║"
echo "║                                                           ║"
echo "╚═══════════════════════════════════════════════════════════╝"

# ============================================
# 1. CORE TOOLS
# ============================================
print_header "1. Core Tools"

check_command brew "Homebrew"
check_command git "Git"
check_command zsh "Zsh"
check_command mise "mise"
check_command starship "Starship"

# ============================================
# 2. TERMINAL & MULTIPLEXERS
# ============================================
print_header "2. Terminal & Multiplexers"

check_command tmux "tmux"
check_command zellij "Zellij" false
check_brew_package ghostty "Ghostty"

# Check tmux TPM
check_file ~/.tmux/plugins/tpm "TPM (Tmux Plugin Manager)" dir

# ============================================
# 3. WINDOW MANAGEMENT
# ============================================
print_header "3. Window Management"

check_brew_package aerospace "Aerospace"
check_file ~/.config/aerospace/aerospace.toml "Aerospace config"

# Check if Aerospace is running
if pgrep -x "Aerospace" > /dev/null; then
    echo -e "${GREEN}✓${NC} Aerospace: ${GREEN}running${NC}"
    ((PASSED++))
else
    echo -e "${YELLOW}⚠${NC} Aerospace: ${YELLOW}not running${NC}"
    ((WARNINGS++))
fi

# ============================================
# 4. EDITORS
# ============================================
print_header "4. Editors"

check_command nvim "Neovim"
check_command zed "Zed" false

# Check Neovim config
check_file ~/.config/nvim/init.lua "Neovim config"

# Check if lazy.nvim is installed
if [ -d ~/.local/share/nvim/lazy ]; then
    echo -e "${GREEN}✓${NC} Lazy.nvim: ${GREEN}installed${NC}"
    ((PASSED++))
else
    echo -e "${YELLOW}⚠${NC} Lazy.nvim: ${YELLOW}not installed (will install on first nvim launch)${NC}"
    ((WARNINGS++))
fi

# ============================================
# 5. SHELL CONFIGURATION
# ============================================
print_header "5. Shell Configuration"

check_file ~/.zshrc ".zshrc" link
check_file ~/.zshrc-dhh-additions ".zshrc-dhh-additions" link
check_file ~/.zshrc-elixir-additions ".zshrc-elixir-additions" link
check_file ~/.zshrc-terminal-enhancements ".zshrc-terminal-enhancements" link
check_file ~/.tmux.conf ".tmux.conf" link
check_file ~/.config/starship.toml "starship.toml" link
check_file ~/.config/mise/config.toml "mise config" link

# ============================================
# 6. LANGUAGE RUNTIMES (mise)
# ============================================
print_header "6. Language Runtimes (mise)"

if command -v mise &> /dev/null; then
    check_mise_tool ruby "Ruby"
    check_mise_tool node "Node.js"
    check_mise_tool elixir "Elixir"
    check_mise_tool python "Python"
    check_mise_tool go "Go"
    check_mise_tool rust "Rust"
else
    echo -e "${RED}✗${NC} mise not found, skipping language runtime checks"
    ((FAILED+=6))
fi

# ============================================
# 7. CLI UTILITIES
# ============================================
print_header "7. CLI Utilities"

check_command rg "ripgrep"
check_command fd "fd"
check_command fzf "fzf"
check_command bat "bat"
check_command eza "eza"
check_command tree "tree"
check_command lazygit "lazygit"
check_command gh "GitHub CLI" false

# ============================================
# 8. DATABASES
# ============================================
print_header "8. Databases"

check_command psql "PostgreSQL"
check_command redis-cli "Redis"

# Check if PostgreSQL is running
if pg_isready &> /dev/null; then
    echo -e "${GREEN}✓${NC} PostgreSQL: ${GREEN}running${NC}"
    ((PASSED++))
else
    echo -e "${YELLOW}⚠${NC} PostgreSQL: ${YELLOW}not running${NC}"
    ((WARNINGS++))
fi

# Check if Redis is running
if redis-cli ping &> /dev/null; then
    echo -e "${GREEN}✓${NC} Redis: ${GREEN}running${NC}"
    ((PASSED++))
else
    echo -e "${YELLOW}⚠${NC} Redis: ${YELLOW}not running${NC}"
    ((WARNINGS++))
fi

# ============================================
# 9. FRAMEWORK TOOLS
# ============================================
print_header "9. Framework Tools"

if command -v mise &> /dev/null && mise current ruby &> /dev/null; then
    # Check Ruby tools
    if command -v bundle &> /dev/null; then
        echo -e "${GREEN}✓${NC} Bundler: ${GREEN}installed${NC} ($(bundle --version))"
        ((PASSED++))
    else
        echo -e "${RED}✗${NC} Bundler: ${RED}not found${NC}"
        ((FAILED++))
    fi

    if command -v rails &> /dev/null; then
        echo -e "${GREEN}✓${NC} Rails: ${GREEN}installed${NC} ($(rails --version))"
        ((PASSED++))
    else
        echo -e "${YELLOW}⚠${NC} Rails: ${YELLOW}not installed (optional)${NC}"
        ((WARNINGS++))
    fi
fi

if command -v mise &> /dev/null && mise current elixir &> /dev/null; then
    # Check Elixir tools
    if command -v mix &> /dev/null; then
        echo -e "${GREEN}✓${NC} Mix: ${GREEN}installed${NC} (Elixir $(elixir --version | grep Elixir | awk '{print $2}'))"
        ((PASSED++))
    else
        echo -e "${RED}✗${NC} Mix: ${RED}not found${NC}"
        ((FAILED++))
    fi

    if mix phx.new --version &> /dev/null; then
        echo -e "${GREEN}✓${NC} Phoenix: ${GREEN}installed${NC}"
        ((PASSED++))
    else
        echo -e "${YELLOW}⚠${NC} Phoenix: ${YELLOW}not installed (optional)${NC}"
        ((WARNINGS++))
    fi
fi

# ============================================
# 10. SHELL INTEGRATION
# ============================================
print_header "10. Shell Integration"

# Check if mise is activated in shell
if grep -q "mise activate" ~/.zshrc; then
    echo -e "${GREEN}✓${NC} mise activation: ${GREEN}configured${NC}"
    ((PASSED++))
else
    echo -e "${RED}✗${NC} mise activation: ${RED}not found in .zshrc${NC}"
    ((FAILED++))
fi

# Check if starship is initialized
if grep -q "starship init" ~/.zshrc; then
    echo -e "${GREEN}✓${NC} Starship init: ${GREEN}configured${NC}"
    ((PASSED++))
else
    echo -e "${RED}✗${NC} Starship init: ${RED}not found in .zshrc${NC}"
    ((FAILED++))
fi

# Check default shell
if [[ "$SHELL" == *"zsh"* ]]; then
    echo -e "${GREEN}✓${NC} Default shell: ${GREEN}zsh${NC}"
    ((PASSED++))
else
    echo -e "${YELLOW}⚠${NC} Default shell: ${YELLOW}not zsh (current: $SHELL)${NC}"
    ((WARNINGS++))
fi

# ============================================
# SUMMARY
# ============================================
echo ""
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║                                                           ║"
echo "║   📊  Health Check Summary                                ║"
echo "║                                                           ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""

TOTAL=$((PASSED + FAILED + WARNINGS))

echo -e "${GREEN}✓ Passed:${NC}   $PASSED/$TOTAL"
echo -e "${RED}✗ Failed:${NC}   $FAILED/$TOTAL"
echo -e "${YELLOW}⚠ Warnings:${NC} $WARNINGS/$TOTAL"
echo ""

# Determine overall status
if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}🎉 All critical checks passed!${NC}"
    if [ $WARNINGS -gt 0 ]; then
        echo -e "${YELLOW}💡 Some optional components are missing or not running${NC}"
    fi
    echo ""
    exit 0
else
    echo -e "${RED}❌ Some critical checks failed${NC}"
    echo -e "${YELLOW}💡 Run 'bash install.sh' to fix missing components${NC}"
    echo ""
    exit 1
fi
