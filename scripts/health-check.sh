#!/usr/bin/env bash

# ============================================
# DOTFILES HEALTH CHECK SCRIPT
# ============================================
# Verifies that all tools are installed and configured correctly
# Usage: bash scripts/health-check.sh
# ============================================

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$DOTFILES_DIR/scripts/_helpers.sh"

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
        local version
        version=$($cmd --version 2>&1 | head -n 1)
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
    local expected_target="${4:-}"  # optional: expected symlink target

    if [[ "$type" == "link" ]]; then
        if [ -L "$file" ]; then
            local target
            target=$(readlink "$file")
            if [[ -n "$expected_target" && "$target" != "$expected_target" ]]; then
                echo -e "${RED}✗${NC} $name: ${RED}wrong target${NC} → $target (expected $expected_target)"
                ((FAILED++))
                return 1
            fi
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
        local version
        version=$(mise current "$tool" 2>/dev/null)
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
        local version
        version=$(brew list --versions "$package" | awk '{print $2}')
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
echo "║   🏥  AJ's Dotfiles Health Check                          ║"
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

# Check Zed config
check_file ~/.config/zed/settings.json "Zed settings" link "$DOTFILES_DIR/.config/zed/settings.json"
check_file ~/.config/zed/tasks.json "Zed tasks" link "$DOTFILES_DIR/.config/zed/tasks.json"
check_file ~/.config/zed/snippets/ruby.json "Zed Ruby snippets" link "$DOTFILES_DIR/.config/zed/snippets/ruby.json"
check_file ~/.config/zed/snippets/erb.json "Zed ERB snippets" link "$DOTFILES_DIR/.config/zed/snippets/erb.json"
check_file ~/.config/zed/snippets/zig.json "Zed Zig snippets" link "$DOTFILES_DIR/.config/zed/snippets/zig.json"

# ============================================
# 5. SHELL CONFIGURATION
# ============================================
print_header "5. Shell Configuration"

check_file ~/.zshrc ".zshrc" link "$DOTFILES_DIR/.zshrc"
check_file ~/.zshrc-dhh-additions ".zshrc-dhh-additions" link "$DOTFILES_DIR/.zshrc-dhh-additions"
check_file ~/.zshrc-elixir-additions ".zshrc-elixir-additions" link "$DOTFILES_DIR/.zshrc-elixir-additions"
check_file ~/.zshrc-terminal-enhancements ".zshrc-terminal-enhancements" link "$DOTFILES_DIR/.zshrc-terminal-enhancements"
check_file ~/.tmux.conf ".tmux.conf" link "$DOTFILES_DIR/.tmux.conf"
check_file ~/.config/starship.toml "starship.toml" link "$DOTFILES_DIR/.config/starship.toml"
check_file ~/.config/mise/config.toml "mise config" link "$DOTFILES_DIR/.config/mise/config.toml"

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

# Zig (installed via Homebrew, not mise)
check_command zig "Zig" false

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
check_command direnv "direnv"
check_command gh "GitHub CLI" false

# ============================================
# 8. DATABASES
# ============================================
print_header "8. Databases"

check_command psql "PostgreSQL"
check_command mysql "MySQL"
check_command redis-cli "Redis"
check_command litecli "litecli (SQLite)" false

# Check if PostgreSQL is running
if pg_isready &> /dev/null; then
    echo -e "${GREEN}✓${NC} PostgreSQL: ${GREEN}running${NC}"
    ((PASSED++))
else
    echo -e "${YELLOW}⚠${NC} PostgreSQL: ${YELLOW}not running${NC}"
    ((WARNINGS++))
fi

# Check if MySQL is running
if mysqladmin ping &> /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} MySQL: ${GREEN}running${NC}"
    ((PASSED++))
else
    echo -e "${YELLOW}⚠${NC} MySQL: ${YELLOW}not running${NC}"
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
# 10. CUSTOM SCRIPTS (~/bin)
# ============================================
print_header "10. Custom Scripts (~/bin)"

# Dotfiles CLI
check_file ~/bin/dotfiles "dotfiles" link
check_file ~/bin/dotfiles-update "dotfiles-update" link
check_file ~/bin/dotfiles-health "dotfiles-health" link
check_file ~/bin/dotfiles-theme "dotfiles-theme" link
check_file ~/bin/dotfiles-install "dotfiles-install" link

# Work management
check_file ~/bin/erb-lint-formatter "erb-lint-formatter" link
check_file ~/bin/work-setup "work-setup" link
check_file ~/bin/work-status "work-status" link
check_file ~/bin/work-nuke "work-nuke" link
check_file ~/bin/repos-clone "repos-clone" link

# Check ~/bin is in PATH
if echo "$PATH" | tr ':' '\n' | grep -q "$HOME/bin"; then
    echo -e "${GREEN}✓${NC} ~/bin in PATH: ${GREEN}yes${NC}"
    ((PASSED++))
else
    echo -e "${YELLOW}⚠${NC} ~/bin in PATH: ${YELLOW}not found (add to .zshrc)${NC}"
    ((WARNINGS++))
fi

# ============================================
# 11. SHELL INTEGRATION
# ============================================
print_header "11. Shell Integration"

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
# 12. WORK IDENTITY (optional)
# ============================================
print_header "12. Work Identity (optional)"

# Source work helpers for detection functions
source "$DOTFILES_DIR/bin/_work-helpers" 2>/dev/null

if is_work_configured 2>/dev/null; then
    local_work_email=$(get_work_email)
    local_work_dir=$(get_work_dir)
    echo -e "${GREEN}✓${NC} Work identity: ${GREEN}configured${NC} ($local_work_email)"
    ((PASSED++))

    if [[ -n "$local_work_dir" && -d "$local_work_dir" ]]; then
        echo -e "${GREEN}✓${NC} Work directory: ${GREEN}$local_work_dir${NC}"
        ((PASSED++))
    elif [[ -n "$local_work_dir" ]]; then
        echo -e "${YELLOW}⚠${NC} Work directory: ${YELLOW}$local_work_dir (not found)${NC}"
        ((WARNINGS++))
    fi

    # Check work SSH hosts
    local_work_hosts=$(get_work_ssh_hosts)
    if [[ -n "$local_work_hosts" ]]; then
        while IFS= read -r host; do
            echo -e "${GREEN}✓${NC} SSH host: ${GREEN}$host${NC}"
            ((PASSED++))
        done <<< "$local_work_hosts"
    fi

    check_file ~/.zshrc-work ".zshrc-work" file
else
    echo -e "${YELLOW}⚠${NC} Work identity: ${YELLOW}not configured (optional — run work-setup)${NC}"
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
