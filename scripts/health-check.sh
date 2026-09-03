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

    # Match against the full installed list (formulae + casks) rather than
    # `brew list <name>`, which fails for tapped casks like
    # nikitabobko/tap/aerospace even when they're installed — the cask
    # appears in `brew list --cask` output as its short token but can't be
    # queried by that token directly. Compare the last path segment so
    # "nikitabobko/tap/aerospace" and "aerospace" both match.
    local token="${package##*/}"
    if brew list --formula 2>/dev/null | grep -qx "$token" \
        || brew list --cask 2>/dev/null | grep -qx "$token"; then
        local version
        version=$(brew list --versions "$token" 2>/dev/null | awk '{print $2}')
        if [[ -n "$version" ]]; then
            echo -e "${GREEN}✓${NC} $name: ${GREEN}installed${NC} (${version})"
        else
            echo -e "${GREEN}✓${NC} $name: ${GREEN}installed${NC}"
        fi
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
echo ""
echo "  AJ's Dotfiles Health Check"
echo "  =========================================="

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

check_command zellij "Zellij" false
check_brew_package ghostty "Ghostty"

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

# Zed config links are covered by the managed-symlink sweep in section 5.

# ============================================
# 5. MANAGED SYMLINKS
# ============================================
print_header "5. Managed Symlinks"

# Sweeps every link in scripts/symlink-map.sh — the same single source
# of truth install/update/sync/doctor use. A file added to the repo but
# never linked on this machine (e.g. a new bin/ script) fails here
# instead of passing silently.
_check_managed_link() {
    check_file "$2" "$3" link "$1"
}
source "$DOTFILES_DIR/scripts/symlink-map.sh"
dotfiles_for_each_link _check_managed_link

# ============================================
# 5b. THEME ASSETS
# ============================================
# `dotfiles theme` renders themes/<name>/colors.toml into
# ~/.local/state/dotfiles/current/theme/ and copies a few files to apps
# that cannot read from there. A theme applied on another machine and
# then synced here leaves those missing, which shows up as an unthemed
# app rather than an error — so check them explicitly.
print_header "5b. Theme Assets"

theme_state="$HOME/.local/state/dotfiles/current"
if [[ -f "$HOME/.dotfiles-theme" ]]; then
    active_theme=$(cat "$HOME/.dotfiles-theme")
    theme_dir="$DOTFILES_DIR/themes/$active_theme"
    if [[ -f "$theme_dir/theme.conf" && -f "$theme_dir/colors.toml" ]]; then
        echo -e "${GREEN}✓${NC} Active theme: ${GREEN}$active_theme${NC}"
        ((PASSED++))
        if [[ "$(cat "$theme_state/theme.name" 2>/dev/null)" == "$active_theme" ]]; then
            echo -e "${GREEN}✓${NC} Rendered theme matches: $theme_state/theme"
            ((PASSED++))
        else
            echo -e "${RED}✗${NC} Rendered theme is not '$active_theme' (run: dotfiles theme $active_theme)"
            ((FAILED++))
        fi
        for tpl in "$DOTFILES_DIR"/themes/_templates/*.tpl; do
            [[ -f "$tpl" ]] || continue
            check_file "$theme_state/theme/$(basename "$tpl" .tpl)" "rendered $(basename "$tpl" .tpl)"
        done
        check_file "$theme_state/theme/background.png" "generated background.png"
        check_file "$DOTFILES_DIR/.config/ghostty/theme.generated" "Ghostty theme.generated"
        check_file "$DOTFILES_DIR/.config/zellij/themes/dotfiles.kdl" "Zellij themes/dotfiles.kdl"
        check_file "$DOTFILES_DIR/.config/sketchybar/colors.sh" "sketchybar colors.sh"
        check_file "$DOTFILES_DIR/.config/borders/colors.sh" "borders colors.sh"
        check_file "$HOME/.zshrc-theme-env" "fzf colours (~/.zshrc-theme-env)"
        for asset in "$theme_dir"/bat/*.tmTheme; do
            [[ -f "$asset" ]] || continue
            check_file "$HOME/.config/bat/themes/$(basename "$asset")" "bat theme $(basename "$asset")"
        done
        for asset in "$theme_dir"/zed/*.json; do
            [[ -f "$asset" ]] || continue
            check_file "$HOME/.config/zed/themes/$(basename "$asset")" "Zed theme $(basename "$asset")"
        done
    else
        echo -e "${RED}✗${NC} Active theme '$active_theme' is missing themes/$active_theme/theme.conf or colors.toml"
        ((FAILED++))
    fi
else
    echo -e "${YELLOW}⚠${NC} No theme applied yet (run: dotfiles theme <name>)"
    ((WARNINGS++))
fi

# Pending migrations mean a repo change has not been applied on this machine
if bash "$DOTFILES_DIR/bin/dotfiles-migrate" --pending >/dev/null 2>&1; then
    echo -e "${YELLOW}⚠${NC} Pending migrations (run: dotfiles migrate)"
    ((WARNINGS++))
else
    echo -e "${GREEN}✓${NC} Migrations: up to date"
    ((PASSED++))
fi

# A restart marker left behind means an update or sync was interrupted
# before step 5, or a migration asked and nothing has consumed it yet
if _pending_restarts=$(bash "$DOTFILES_DIR/bin/dotfiles-restart" --list 2>/dev/null); then
    echo -e "${YELLOW}⚠${NC} Pending restarts: $(echo "$_pending_restarts" | tr '\n' ' ')(run: dotfiles restart --pending)"
    ((WARNINGS++))
else
    echo -e "${GREEN}✓${NC} Restarts: nothing pending"
    ((PASSED++))
fi

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
    check_mise_tool erlang "Erlang/OTP"
    check_mise_tool yarn "Yarn"
    check_mise_tool java "Java"
else
    echo -e "${RED}✗${NC} mise not found, skipping language runtime checks"
    ((FAILED+=9))
fi

# Zig (installed via Homebrew, not mise)
check_command zig "Zig" false

# ============================================
# 6b. PROJECT TOOLCHAIN DRIFT
# ============================================
# Catches the class of bug where a project pins a tool version (in
# .tool-versions / mise.toml / .ruby-version etc.) that isn't actually
# installed, so mise silently falls back to the global version and the
# project runs on the wrong toolchain. Five Ruby projects did exactly
# this for months. Scans project roots under the configured code dirs;
# `mise ls --missing` resolves each dir's config and reports only the
# gaps. Warnings (not failures) — a spare-repo drift shouldn't fail an
# otherwise-healthy machine.
print_header "6b. Project Toolchain Drift"

if command -v mise &> /dev/null; then
    # Where projects live. Override by exporting DOTFILES_CODE_DIRS as a
    # space-separated list before running health.
    code_dirs="${DOTFILES_CODE_DIRS:-$HOME/code $HOME/work/code}"
    drift_found=0
    scanned=0

    for base in $code_dirs; do
        [[ -d "$base" ]] || continue
        # One level deep: each immediate subdir is a project root.
        for proj in "$base"/*/; do
            [[ -d "$proj" ]] || continue
            # Only bother if the project pins something. Test each file
            # individually — `ls a b c` has shell-dependent exit status
            # when some paths are missing, so it's not a reliable
            # "any of these exist" check.
            pinned=false
            for vf in .tool-versions .ruby-version .nvmrc mise.toml .mise.toml; do
                if [[ -f "$proj$vf" ]]; then pinned=true; break; fi
            done
            [[ "$pinned" == true ]] || continue
            scanned=$((scanned + 1))
            missing=$(cd "$proj" && mise ls --missing 2>/dev/null)
            if [[ -n "$missing" ]]; then
                drift_found=1
                echo -e "${YELLOW}⚠${NC} $(basename "$proj"): ${YELLOW}pinned tool not installed${NC}"
                # Indent each missing tool line for readability.
                echo "$missing" | awk '{printf "     %s %s\n", $1, $2}'
                ((WARNINGS++))
            fi
        done
    done

    if [[ "$scanned" -eq 0 ]]; then
        echo -e "${GREEN}✓${NC} No pinned projects found under: $code_dirs"
    elif [[ "$drift_found" -eq 0 ]]; then
        echo -e "${GREEN}✓${NC} All $scanned pinned project(s) resolve to installed versions"
        ((PASSED++))
    else
        echo -e "     ${YELLOW}Fix: cd into the project and run 'mise install'${NC}"
    fi
else
    echo -e "${YELLOW}⚠${NC} mise not found — skipping toolchain drift scan"
    ((WARNINGS++))
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
check_command direnv "direnv"
check_command zoxide "zoxide"
check_command starship "Starship"
check_command atuin "atuin" false
check_command gh "GitHub CLI" false
check_command sketchybar "SketchyBar" false
check_command borders "JankyBorders" false
check_command wezterm "WezTerm" false

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

    # macOS ships a /usr/bin/rails STUB that exists, is executable, and exits
    # 0 while printing "Rails is not currently installed on this system."
    # So neither `command -v rails` nor its exit code can tell you anything —
    # the old check reported "installed" and then printed that very error as
    # the version string. Match the actual version output instead.
    _rails_version=$(rails --version 2>/dev/null | grep -oE '^Rails [0-9]+\.[0-9]+\.[0-9.]+' || true)

    if [[ -n "$_rails_version" ]]; then
        echo -e "${GREEN}✓${NC} Rails: ${GREEN}installed${NC} ($_rails_version)"
        ((PASSED++))
    elif [[ "$(command -v rails)" == "/usr/bin/rails" ]]; then
        echo -e "${YELLOW}⚠${NC} Rails: ${YELLOW}not installed (only the macOS system stub) — 'gem install rails'${NC}"
        ((WARNINGS++))
    else
        echo -e "${YELLOW}⚠${NC} Rails: ${YELLOW}not installed (optional) — 'gem install rails'${NC}"
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

# Individual bin/ links are covered by the managed-symlink sweep in
# section 5 (every file in the repo's bin/ is checked, not a hardcoded
# subset that goes stale when scripts are added).

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
echo ""
echo "  Health Check Summary"
echo "  =========================================="
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
