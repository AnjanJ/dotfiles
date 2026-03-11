#!/usr/bin/env bash

# ============================================
# APPLY THEME
# ============================================
# Applies the selected theme across all configured apps
# Usage: bash scripts/apply-theme.sh <tokyo-night|aura>
#    or: source scripts/apply-theme.sh && apply_theme <tokyo-night|aura>
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

    # ── Pre-flight validation ──────────────────────────
    # Check ALL required files exist before modifying anything.
    # This prevents a half-applied theme if a file is missing.
    _theme_step "Pre-flight validation..."
    local preflight_ok=true
    local missing_files=()

    # Theme source files (per-theme)
    local required_theme_files
    if [[ "$THEME" == "aura" ]]; then
        required_theme_files=(
            "nvim/aura-theme.lua"
            "tmux/theme-block.conf"
            "starship/palette.toml"
            "zellij/themes/aura.kdl"
            "ghostty/themes/Aura"
            "warp/aura-theme.yaml"
        )
    else
        required_theme_files=(
            "nvim/tokyo-night-theme.lua"
            "tmux/theme-block.conf"
            "starship/palette.toml"
            "zellij/themes/tokyo-night.kdl"
        )
    fi

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
    if [[ "$THEME" == "aura" ]]; then
        # Install custom Aura theme file
        mkdir -p "$DOTFILES_DIR/.config/ghostty/themes"
        cp "$THEMES_DIR/ghostty/themes/Aura" "$DOTFILES_DIR/.config/ghostty/themes/Aura"
        # Update theme line in config
        sed -i '' 's/^theme = .*/theme = Aura/' "$ghostty_config"
    else
        # Tokyo Night is built-in
        sed -i '' 's/^theme = .*/theme = tokyonight_night/' "$ghostty_config"
    fi
    _theme_success "Ghostty → $THEME"

    # ── 2. Neovim ───────────────────────────────────────
    _theme_step "Neovim..."
    local nvim_plugins="$DOTFILES_DIR/.config/nvim/lua/plugins"
    local astroui="$nvim_plugins/astroui.lua"

    # Remove any existing theme plugin files
    rm -f "$nvim_plugins/tokyo-night-theme.lua" "$nvim_plugins/aura-theme.lua"

    if [[ "$THEME" == "aura" ]]; then
        cp "$THEMES_DIR/nvim/aura-theme.lua" "$nvim_plugins/aura-theme.lua"
        local colorscheme="aura-dark"
    else
        cp "$THEMES_DIR/nvim/tokyo-night-theme.lua" "$nvim_plugins/tokyo-night-theme.lua"
        local colorscheme="tokyonight"
    fi

    # Update colorscheme in astroui.lua
    sed -i '' "s/colorscheme = \"[^\"]*\"/colorscheme = \"$colorscheme\"/" "$astroui"
    _theme_success "Neovim → $colorscheme"

    # ── 3. Zellij ───────────────────────────────────────
    _theme_step "Zellij..."
    local zellij_config="$DOTFILES_DIR/.config/zellij/config.kdl"
    local zellij_themes_dir="$DOTFILES_DIR/.config/zellij/themes"

    # Copy theme file
    mkdir -p "$zellij_themes_dir"
    if [[ "$THEME" == "aura" ]]; then
        cp "$THEMES_DIR/zellij/themes/aura.kdl" "$zellij_themes_dir/aura.kdl"
        sed -i '' 's/^theme "[^"]*"/theme "aura"/' "$zellij_config"
    else
        cp "$THEMES_DIR/zellij/themes/tokyo-night.kdl" "$zellij_themes_dir/tokyo-night.kdl"
        sed -i '' 's/^theme "[^"]*"/theme "tokyo-night"/' "$zellij_config"
    fi
    _theme_success "Zellij → $THEME"

    # ── 4. Starship ─────────────────────────────────────
    _theme_step "Starship..."
    local starship_config="$DOTFILES_DIR/.config/starship.toml"
    local palette_file="$THEMES_DIR/starship/palette.toml"

    if [[ "$THEME" == "aura" ]]; then
        sed -i '' 's/^palette = "[^"]*"/palette = "aura"/' "$starship_config"
    else
        sed -i '' 's/^palette = "[^"]*"/palette = "tokyonight"/' "$starship_config"
    fi

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

    _theme_success "Starship → $THEME"

    # ── 5. tmux ─────────────────────────────────────────
    _theme_step "tmux..."
    local tmux_config="$DOTFILES_DIR/.tmux.conf"
    local theme_block="$THEMES_DIR/tmux/theme-block.conf"

    # Replace content between THEME_BLOCK_START and THEME_BLOCK_END
    if grep -q "THEME_BLOCK_START" "$tmux_config" && [[ -f "$theme_block" ]]; then
        # Create a temp file with the replacement
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
    if [[ -f "$vscode_settings" ]]; then
        if [[ "$THEME" == "aura" ]]; then
            local vscode_theme="Aura Dark"
        else
            local vscode_theme="Tokyo Night"
        fi

        # Use python for safe JSON manipulation (always available on macOS)
        if python3 -c "
import json, sys
with open('$vscode_settings', 'r') as f:
    settings = json.load(f)
settings['workbench.colorTheme'] = '$vscode_theme'
with open('$vscode_settings', 'w') as f:
    json.dump(settings, f, indent=2)
" 2>/dev/null; then
            _theme_success "VS Code → $vscode_theme"
        else
            _theme_warning "VS Code: Could not update settings.json (file may not exist yet)"
        fi
    else
        _theme_warning "VS Code: settings.json not found (VS Code may not be installed yet)"
    fi

    # ── 7. Warp ─────────────────────────────────────────
    _theme_step "Warp..."
    if [[ "$THEME" == "aura" ]]; then
        mkdir -p "$HOME/.warp/themes"
        cp "$THEMES_DIR/warp/aura-theme.yaml" "$HOME/.warp/themes/aura-theme.yaml"
        _theme_success "Warp → Aura theme installed to ~/.warp/themes/"
    else
        _theme_success "Warp → Tokyo Night (built-in, select in Warp settings)"
    fi

    # ── 8. Zed ──────────────────────────────────────────
    _theme_step "Zed..."
    local zed_settings="$DOTFILES_DIR/.config/zed/settings.json"
    if [[ -f "$zed_settings" ]]; then
        if [[ "$THEME" == "aura" ]]; then
            local zed_theme="Aura Dark"
        else
            local zed_theme="Tokyo Night"
        fi

        if python3 -c "
import json
with open('$zed_settings', 'r') as f:
    settings = json.load(f)
if 'theme' not in settings:
    settings['theme'] = {}
settings['theme']['dark'] = '$zed_theme'
with open('$zed_settings', 'w') as f:
    json.dump(settings, f, indent=2)
" 2>/dev/null; then
            _theme_success "Zed → $zed_theme"
        else
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
