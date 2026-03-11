#!/usr/bin/env bash

# ============================================
# APPLY THEME
# ============================================
# Applies the selected theme across all configured apps
# Usage: bash scripts/apply-theme.sh <tokyo-night|aura>
#    or: source scripts/apply-theme.sh && apply_theme <tokyo-night|aura>
#
# Theme settings are defined in themes/<name>/theme.conf
# To add a new theme, create a directory under themes/ with
# the required files and a theme.conf registry file.
# ============================================

# Get dotfiles directory (relative to this script)
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Source utilities
source "$DOTFILES_DIR/scripts/theme-utils.sh"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

_theme_success() {
    echo -e "${GREEN}✓${NC} $1"
}

_theme_warning() {
    echo -e "${YELLOW}Warning:${NC} $1"
}

_theme_step() {
    echo -e "${BLUE}==>${NC} $1"
}

# shellcheck disable=SC2154  # theme.conf variables loaded dynamically
apply_theme() {
    local THEME="$1"
    local QUIET="${2:-false}"  # pass "true" to suppress manual instructions
    local THEMES_DIR="$DOTFILES_DIR/themes/$THEME"

    if ! validate_theme "$THEME"; then
        echo "Error: Invalid theme '$THEME'. Valid themes: ${VALID_THEMES[*]}"
        return 1
    fi

    if [[ ! -d "$THEMES_DIR" ]]; then
        echo "Error: Theme directory not found: $THEMES_DIR"
        return 1
    fi

    # ── Load theme registry ──────────────────────────
    local conf="$THEMES_DIR/theme.conf"
    if [[ ! -f "$conf" ]]; then
        echo "Error: Theme registry not found: $conf"
        echo "Each theme needs a theme.conf file. See themes/tokyo-night/theme.conf for an example."
        return 1
    fi

    # shellcheck source=/dev/null
    # Variables loaded from theme.conf: ghostty_theme, ghostty_custom_file,
    # nvim_plugin_file, nvim_colorscheme, zellij_theme_file, zellij_theme_name,
    # starship_palette, vscode_theme, zed_theme
    source "$conf"

    # Validate required variables from theme.conf
    local missing_vars=()
    local required_vars=(ghostty_theme nvim_plugin_file nvim_colorscheme
        zellij_theme_file zellij_theme_name starship_palette vscode_theme zed_theme)
    for var in "${required_vars[@]}"; do
        if [[ -z "${!var:-}" ]]; then
            missing_vars+=("$var")
        fi
    done
    if [[ ${#missing_vars[@]} -gt 0 ]]; then
        echo "Error: theme.conf is missing required variables:"
        for v in "${missing_vars[@]}"; do
            echo "  - $v"
        done
        echo ""
        echo "See themes/tokyo-night/theme.conf for an example."
        return 1
    fi

    # ── Pre-flight validation ──────────────────────────
    _theme_step "Pre-flight validation..."
    local preflight_ok=true
    local missing_files=()

    # Required theme source files (derived from registry)
    local required_theme_files=(
        "nvim/$nvim_plugin_file"
        "tmux/theme-block.conf"
        "starship/palette.toml"
        "zellij/themes/$zellij_theme_file"
    )
    [[ -n "$ghostty_custom_file" ]] && required_theme_files+=("$ghostty_custom_file")

    for f in "${required_theme_files[@]}"; do
        if [[ ! -f "$THEMES_DIR/$f" ]]; then
            missing_files+=("themes/$THEME/$f")
            preflight_ok=false
        fi
    done

    # Target config files that we'll modify
    local required_configs=(
        "$DOTFILES_DIR/.config/ghostty/config"
        "$DOTFILES_DIR/.config/nvim/lua/plugins/astroui.lua"
        "$DOTFILES_DIR/.config/zellij/config.kdl"
        "$DOTFILES_DIR/.config/starship.toml"
        "$DOTFILES_DIR/.tmux.conf"
    )

    for f in "${required_configs[@]}"; do
        if [[ ! -f "$f" ]]; then
            missing_files+=("$f")
            preflight_ok=false
        fi
    done

    # Check sentinel markers exist in target configs
    if [[ -f "$DOTFILES_DIR/.config/starship.toml" ]] && ! grep -q "THEME_PALETTE_START" "$DOTFILES_DIR/.config/starship.toml"; then
        missing_files+=("starship.toml: missing THEME_PALETTE_START/END markers")
        preflight_ok=false
    fi
    if [[ -f "$DOTFILES_DIR/.tmux.conf" ]] && ! grep -q "THEME_BLOCK_START" "$DOTFILES_DIR/.tmux.conf"; then
        missing_files+=(".tmux.conf: missing THEME_BLOCK_START/END markers")
        preflight_ok=false
    fi

    if [[ "$preflight_ok" == false ]]; then
        echo ""
        echo "Error: Pre-flight validation failed. Missing:"
        for f in "${missing_files[@]}"; do
            echo "  - $f"
        done
        echo ""
        echo "No configs were modified. Fix the above issues and try again."
        return 1
    fi

    _theme_success "All theme files and configs verified"

    echo ""
    _theme_step "Applying theme: $THEME"
    echo ""

    # ── 1. Ghostty ──────────────────────────────────────
    _theme_step "Ghostty..."
    local ghostty_config="$DOTFILES_DIR/.config/ghostty/config"
    if [[ -n "$ghostty_custom_file" ]]; then
        mkdir -p "$DOTFILES_DIR/.config/ghostty/themes"
        cp "$THEMES_DIR/$ghostty_custom_file" "$DOTFILES_DIR/.config/ghostty/themes/"
    fi
    sed -i '' "s/^theme = .*/theme = $ghostty_theme/" "$ghostty_config"
    _theme_success "Ghostty → $ghostty_theme"

    # ── 2. Neovim ───────────────────────────────────────
    _theme_step "Neovim..."
    local nvim_plugins="$DOTFILES_DIR/.config/nvim/lua/plugins"
    local astroui="$nvim_plugins/astroui.lua"

    # Remove any existing theme plugin files, then install the right one
    rm -f "$nvim_plugins/tokyo-night-theme.lua" "$nvim_plugins/aura-theme.lua"
    cp "$THEMES_DIR/nvim/$nvim_plugin_file" "$nvim_plugins/$nvim_plugin_file"

    # Update colorscheme in astroui.lua
    sed -i '' "s/colorscheme = \"[^\"]*\"/colorscheme = \"$nvim_colorscheme\"/" "$astroui"
    _theme_success "Neovim → $nvim_colorscheme"

    # ── 3. Zellij ───────────────────────────────────────
    _theme_step "Zellij..."
    local zellij_config="$DOTFILES_DIR/.config/zellij/config.kdl"
    local zellij_themes_dir="$DOTFILES_DIR/.config/zellij/themes"

    mkdir -p "$zellij_themes_dir"
    cp "$THEMES_DIR/zellij/themes/$zellij_theme_file" "$zellij_themes_dir/$zellij_theme_file"
    sed -i '' "s/^theme \"[^\"]*\"/theme \"$zellij_theme_name\"/" "$zellij_config"
    _theme_success "Zellij → $zellij_theme_name"

    # ── 4. Starship ─────────────────────────────────────
    _theme_step "Starship..."
    local starship_config="$DOTFILES_DIR/.config/starship.toml"
    local palette_file="$THEMES_DIR/starship/palette.toml"

    sed -i '' "s/^palette = \"[^\"]*\"/palette = \"$starship_palette\"/" "$starship_config"

    # Replace palette section between sentinel comments
    if grep -q "THEME_PALETTE_START" "$starship_config" && [[ -f "$palette_file" ]]; then
        local tmpfile
        tmpfile=$(mktemp)
        local in_block=false

        while IFS= read -r line; do
            if [[ "$line" == "# THEME_PALETTE_START" ]]; then
                echo "# THEME_PALETTE_START" >> "$tmpfile"
                cat "$palette_file" >> "$tmpfile"
                in_block=true
            elif [[ "$line" == "# THEME_PALETTE_END" ]]; then
                echo "# THEME_PALETTE_END" >> "$tmpfile"
                in_block=false
            elif [[ "$in_block" == false ]]; then
                echo "$line" >> "$tmpfile"
            fi
        done < "$starship_config"

        mv "$tmpfile" "$starship_config"
    fi

    _theme_success "Starship → $starship_palette"

    # ── 5. tmux ─────────────────────────────────────────
    _theme_step "tmux..."
    local tmux_config="$DOTFILES_DIR/.tmux.conf"
    local theme_block="$THEMES_DIR/tmux/theme-block.conf"

    # Replace content between THEME_BLOCK_START and THEME_BLOCK_END
    if grep -q "THEME_BLOCK_START" "$tmux_config" && [[ -f "$theme_block" ]]; then
        local tmpfile
        tmpfile=$(mktemp)
        local in_block=false

        while IFS= read -r line; do
            if [[ "$line" == "# THEME_BLOCK_START" ]]; then
                echo "# THEME_BLOCK_START" >> "$tmpfile"
                cat "$theme_block" >> "$tmpfile"
                in_block=true
            elif [[ "$line" == "# THEME_BLOCK_END" ]]; then
                echo "# THEME_BLOCK_END" >> "$tmpfile"
                in_block=false
            elif [[ "$in_block" == false ]]; then
                echo "$line" >> "$tmpfile"
            fi
        done < "$tmux_config"

        mv "$tmpfile" "$tmux_config"
        _theme_success "tmux → $THEME"
    else
        _theme_warning "tmux: Could not find THEME_BLOCK markers in .tmux.conf"
    fi

    # ── 6. VS Code ──────────────────────────────────────
    _theme_step "VS Code..."
    local vscode_settings="$HOME/Library/Application Support/Code/User/settings.json"
    if [[ -f "$vscode_settings" ]] && command -v jq &>/dev/null; then
        local tmpfile
        tmpfile=$(mktemp)
        if jq --arg theme "$vscode_theme" '.["workbench.colorTheme"] = $theme' "$vscode_settings" > "$tmpfile" 2>/dev/null; then
            mv "$tmpfile" "$vscode_settings"
            _theme_success "VS Code → $vscode_theme"
        else
            rm -f "$tmpfile"
            _theme_warning "VS Code: Could not update settings.json"
        fi
    elif [[ ! -f "$vscode_settings" ]]; then
        _theme_warning "VS Code: settings.json not found (VS Code may not be installed yet)"
    else
        _theme_warning "VS Code: jq not installed, skipping"
    fi

    # ── 7. Zed ──────────────────────────────────────────
    _theme_step "Zed..."
    local zed_settings="$DOTFILES_DIR/.config/zed/settings.json"
    if [[ -f "$zed_settings" ]] && command -v jq &>/dev/null; then
        local tmpfile
        tmpfile=$(mktemp)
        if jq --arg theme "$zed_theme" '.theme.dark = $theme' "$zed_settings" > "$tmpfile" 2>/dev/null; then
            mv "$tmpfile" "$zed_settings"
            _theme_success "Zed → $zed_theme"
        else
            rm -f "$tmpfile"
            _theme_warning "Zed: Could not update settings.json"
        fi
    fi

    # ── Save state ──────────────────────────────────────
    set_current_theme "$THEME"

    # ── Print manual steps (skip in quiet mode, e.g. during update.sh) ──
    if [[ "$QUIET" != "true" ]]; then
        echo ""
        local manual_file="$THEMES_DIR/manual-instructions.txt"
        if [[ -f "$manual_file" ]]; then
            cat "$manual_file"
        fi

        echo ""
        echo "────────────────────────────────────────────────────"
        echo "  Post-apply reminders:"
        echo "────────────────────────────────────────────────────"
        echo "  • Restart your terminal or run: source ~/.zshrc"
        echo "  • In tmux: prefix + r to reload, then prefix + I to install plugins"
        echo "  • In Neovim: run :Lazy sync to install the theme plugin"
        echo "────────────────────────────────────────────────────"
        echo ""
    fi
}

# Allow running directly: bash scripts/apply-theme.sh <theme>
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    if [[ -z "$1" ]]; then
        echo "Usage: bash scripts/apply-theme.sh <tokyo-night|aura>"
        exit 1
    fi
    apply_theme "$1"
fi
