#!/usr/bin/env bash

# ============================================
# APPLY THEME
# ============================================
# Applies the selected theme across all configured apps
# Usage: bash scripts/apply-theme.sh <tokyo-night|aura|catppuccin>
#    or: source scripts/apply-theme.sh && apply_theme <tokyo-night|aura|catppuccin>
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
    # starship_palette, vscode_theme, zed_theme, bat_theme, delta_theme,
    # fzf_colors, borders_active, borders_inactive, borders_background
    source "$conf"

    # Validate required variables from theme.conf
    local missing_vars=()
    local required_vars=(ghostty_theme nvim_plugin_file nvim_colorscheme
        zellij_theme_file zellij_theme_name starship_palette vscode_theme zed_theme
        bat_theme delta_theme fzf_colors borders_active borders_inactive)
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
    )

    for f in "${required_configs[@]}"; do
        if [[ ! -f "$f" ]]; then
            missing_files+=("$f")
            preflight_ok=false
        fi
    done

    # Check sentinel markers exist in target configs
    if [[ -f "$DOTFILES_DIR/.config/ghostty/config" ]] && ! grep -q "THEME_START" "$DOTFILES_DIR/.config/ghostty/config"; then
        missing_files+=("ghostty/config: missing THEME_START/END markers")
        preflight_ok=false
    fi
    if [[ -f "$DOTFILES_DIR/.config/starship.toml" ]] && ! grep -q "THEME_PALETTE_START" "$DOTFILES_DIR/.config/starship.toml"; then
        missing_files+=("starship.toml: missing THEME_PALETTE_START/END markers")
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

    # ── Backup for rollback ────────────────────────────
    local _ROLLBACK_DIR
    _ROLLBACK_DIR=$(mktemp -d)
    local _ROLLBACK_FILES=()

    _backup_for_rollback() {
        local filepath="$1"
        if [[ -f "$filepath" ]]; then
            local safename
            safename=$(echo "$filepath" | tr '/' '_')
            cp "$filepath" "$_ROLLBACK_DIR/$safename"
            _ROLLBACK_FILES+=("$filepath|$_ROLLBACK_DIR/$safename")
        fi
    }

    _rollback_theme() {
        echo ""
        echo "Error: Theme apply failed — rolling back all changes..."
        for entry in "${_ROLLBACK_FILES[@]}"; do
            local orig="${entry%%|*}"
            local bak="${entry##*|}"
            if [[ -f "$bak" ]]; then
                cp "$bak" "$orig"
            fi
        done
        rm -rf "$_ROLLBACK_DIR"
        echo "All configs restored to their previous state."
    }

    # Back up all configs that will be modified
    _backup_for_rollback "$DOTFILES_DIR/.config/ghostty/config"
    _backup_for_rollback "$DOTFILES_DIR/.config/nvim/lua/plugins/astroui.lua"
    _backup_for_rollback "$DOTFILES_DIR/.config/nvim/lua/plugins/tokyo-night-theme.lua"
    _backup_for_rollback "$DOTFILES_DIR/.config/nvim/lua/plugins/aura-theme.lua"
    _backup_for_rollback "$DOTFILES_DIR/.config/nvim/lua/plugins/catppuccin-theme.lua"
    _backup_for_rollback "$DOTFILES_DIR/.config/zellij/config.kdl"
    _backup_for_rollback "$DOTFILES_DIR/.config/starship.toml"
    _backup_for_rollback "$DOTFILES_DIR/.config/zed/settings.json"
    _backup_for_rollback "$HOME/.config/bat/config"
    _backup_for_rollback "$HOME/.zshrc-theme-env"
    _backup_for_rollback "$DOTFILES_DIR/.config/lazygit/config.yml"
    _backup_for_rollback "$DOTFILES_DIR/.config/borders/bordersrc"
    _backup_for_rollback "$DOTFILES_DIR/.config/sketchybar/sketchybarrc"
    _backup_for_rollback "$HOME/.config/yazi/theme.toml"
    _backup_for_rollback "$HOME/.config/gitui/theme.ron"
    _backup_for_rollback "$HOME/.config/lsd/colors.yaml"

    # Set ERR trap for automatic rollback (requires errtrace for functions)
    set -o errtrace
    trap '_rollback_theme; return 1' ERR

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
    # Replace theme line between THEME_START/THEME_END markers
    if grep -q "THEME_START" "$ghostty_config"; then
        local tmpfile
        tmpfile=$(mktemp)
        local in_block=false
        while IFS= read -r line; do
            if [[ "$line" == "# THEME_START" ]]; then
                echo "# THEME_START" >> "$tmpfile"
                echo "theme = $ghostty_theme" >> "$tmpfile"
                in_block=true
            elif [[ "$line" == "# THEME_END" ]]; then
                echo "# THEME_END" >> "$tmpfile"
                in_block=false
            elif [[ "$in_block" == false ]]; then
                echo "$line" >> "$tmpfile"
            fi
        done < "$ghostty_config"
        mv "$tmpfile" "$ghostty_config"
    else
        # Fallback: simple sed replacement
        sed -i '' "s/^theme = .*/theme = $ghostty_theme/" "$ghostty_config"
    fi
    _theme_success "Ghostty → $ghostty_theme"

    # ── 2. Neovim ───────────────────────────────────────
    _theme_step "Neovim..."
    local nvim_plugins="$DOTFILES_DIR/.config/nvim/lua/plugins"
    local astroui="$nvim_plugins/astroui.lua"

    # Remove any existing theme plugin files, then install the right one
    rm -f "$nvim_plugins/tokyo-night-theme.lua" "$nvim_plugins/aura-theme.lua" "$nvim_plugins/catppuccin-theme.lua"
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

    # ── Mandatory sections done — disable ERR trap ─────
    # Sections 5+ are optional (guarded by command -v). Failures in
    # these should not trigger a full rollback of the core theme configs.
    trap - ERR
    set +o errtrace

    # ── 5. VS Code ──────────────────────────────────────
    _theme_step "VS Code..."
    local vscode_settings="$HOME/Library/Application Support/Code/User/settings.json"
    # VS Code's settings.json is a symlink into this repo, and BSD `sed -i`
    # refuses to edit symlinks ("in-place editing only works for regular
    # files"). Resolve to the real path first, or every edit below fails.
    if [[ -L "$vscode_settings" ]]; then
        vscode_settings=$(readlink "$vscode_settings")
    fi
    if [[ -f "$vscode_settings" ]]; then
        # VS Code uses JSONC (JSON with Comments), so use sed rather than jq.
        if grep -q '"workbench\.colorTheme"' "$vscode_settings"; then
            sed -i '' 's/"workbench\.colorTheme": *"[^"]*"/"workbench.colorTheme": "'"$vscode_theme"'"/' "$vscode_settings"
            _theme_success "VS Code → $vscode_theme"
        elif head -1 "$vscode_settings" | grep -q '^{'; then
            # The key is absent. A bare `sed` substitution matches nothing and
            # still exits 0, so the old code reported success while changing
            # nothing -- VS Code kept whatever theme it had. Insert it instead.
            sed -i '' '1a\
\  "workbench.colorTheme": "'"$vscode_theme"'",
' "$vscode_settings"
            _theme_success "VS Code → $vscode_theme (key added)"
        else
            _theme_warning "VS Code: settings.json does not start with '{', not editing"
        fi
    else
        _theme_warning "VS Code: settings.json not found (VS Code may not be installed yet)"
    fi

    # ── 6. Zed ──────────────────────────────────────────
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

    # ── 7. Warp ───────────────────────────────────────────
    if command -v warp-cli &>/dev/null || [[ -d "/Applications/Warp.app" ]]; then
        _theme_step "Warp..."
        local warp_themes_dir="$HOME/.warp/themes"

        # Copy custom theme YAML if needed
        if [[ -n "${warp_custom_file:-}" ]]; then
            mkdir -p "$warp_themes_dir"
            cp "$THEMES_DIR/$warp_custom_file" "$warp_themes_dir/"
            local yaml_name
            yaml_name=$(basename "$warp_custom_file" .yaml)
            # Set Warp to use the custom theme (dark mode)
            defaults write dev.warp.Warp-Stable Theme "\"Custom\""
            # Update SelectedSystemThemes to point to the custom file
            local yaml_path
            yaml_path="$warp_themes_dir/$(basename "$warp_custom_file")"
            local theme_json='{"light":"Light","dark":{"Custom":{"name":"'"${yaml_name}"'","path":"'"${yaml_path}"'"}}}'
            defaults write dev.warp.Warp-Stable SelectedSystemThemes -string "$theme_json"
            _theme_success "Warp → $warp_theme (custom)"
        else
            # Built-in theme — set directly
            defaults write dev.warp.Warp-Stable Theme "\"${warp_theme}\""
            _theme_success "Warp → $warp_theme (built-in)"
        fi
    fi

    # ── 8. bat ────────────────────────────────────────────
    if command -v bat &>/dev/null; then
        _theme_step "bat..."
        mkdir -p "$HOME/.config/bat"
        echo "--theme=\"${bat_theme}\"" > "$HOME/.config/bat/config"
        _theme_success "bat → $bat_theme"
    fi

    # ── 9. git-delta ─────────────────────────────────────
    if command -v delta &>/dev/null; then
        _theme_step "git-delta..."
        git config --global delta.syntax-theme "$delta_theme"
        _theme_success "git-delta → $delta_theme"
    fi

    # ── 10. fzf ────────────────────────────────────────────
    if command -v fzf &>/dev/null; then
        _theme_step "fzf..."
        local fzf_env_file="$HOME/.zshrc-theme-env"
        cat > "$fzf_env_file" <<FZFEOF
# Auto-generated by apply-theme.sh — do not edit manually
# Theme: $THEME
export FZF_THEME_COLORS="--color=${fzf_colors}"
FZFEOF
        _theme_success "fzf → $THEME colors"
    fi

    # ── 11. lazygit ────────────────────────────────────────
    if command -v lazygit &>/dev/null; then
        _theme_step "lazygit..."
        local lazygit_config="$DOTFILES_DIR/.config/lazygit/config.yml"
        local lazygit_theme="$THEMES_DIR/lazygit/theme.yml"
        if [[ -f "$lazygit_config" ]] && grep -q "THEME_START" "$lazygit_config" && [[ -f "$lazygit_theme" ]]; then
            local tmpfile
            tmpfile=$(mktemp)
            local in_block=false
            while IFS= read -r line; do
                if [[ "$line" == *"# THEME_START"* ]]; then
                    echo "  # THEME_START" >> "$tmpfile"
                    cat "$lazygit_theme" >> "$tmpfile"
                    in_block=true
                elif [[ "$line" == *"# THEME_END"* ]]; then
                    echo "  # THEME_END" >> "$tmpfile"
                    in_block=false
                elif [[ "$in_block" == false ]]; then
                    echo "$line" >> "$tmpfile"
                fi
            done < "$lazygit_config"
            mv "$tmpfile" "$lazygit_config"
            _theme_success "lazygit → $THEME"
        else
            _theme_warning "lazygit: config not found or missing THEME_START/END markers"
        fi
    fi

    # ── 12. borders (JankyBorders) ────────────────────────
    if command -v borders &>/dev/null; then
        _theme_step "borders..."
        local borders_config="$DOTFILES_DIR/.config/borders/bordersrc"
        if [[ -f "$borders_config" ]]; then
            sed -i '' "s/active_color=0x[0-9a-fA-F]*/active_color=${borders_active}/" "$borders_config"
            sed -i '' "s/inactive_color=0x[0-9a-fA-F]*/inactive_color=${borders_inactive}/" "$borders_config"
            sed -i '' "s/background_color=0x[0-9a-fA-F]*/background_color=${borders_background}/" "$borders_config"
            _theme_success "borders → $THEME"
        else
            _theme_warning "borders: bordersrc not found"
        fi
    fi

    # ── 13. sketchybar ─────────────────────────────────────
    if command -v sketchybar &>/dev/null; then
        _theme_step "sketchybar..."
        local sketchybar_config="$DOTFILES_DIR/.config/sketchybar/sketchybarrc"
        local sketchybar_colors="$THEMES_DIR/sketchybar/colors.sh"
        if [[ -f "$sketchybar_config" ]] && grep -q "THEME_COLORS_START" "$sketchybar_config" && [[ -f "$sketchybar_colors" ]]; then
            local tmpfile
            tmpfile=$(mktemp)
            local in_block=false
            while IFS= read -r line; do
                if [[ "$line" == "# THEME_COLORS_START" ]]; then
                    echo "# THEME_COLORS_START" >> "$tmpfile"
                    cat "$sketchybar_colors" >> "$tmpfile"
                    in_block=true
                elif [[ "$line" == "# THEME_COLORS_END" ]]; then
                    echo "# THEME_COLORS_END" >> "$tmpfile"
                    in_block=false
                elif [[ "$in_block" == false ]]; then
                    echo "$line" >> "$tmpfile"
                fi
            done < "$sketchybar_config"
            mv "$tmpfile" "$sketchybar_config"

            # Plugins cannot inherit the exports above: sketchybar spawns them
            # from the bar daemon's own environment, not from the shell that
            # ran sketchybarrc. Drop the same palette into a standalone file
            # for plugins to source, so a theme switch reaches them too.
            local plugin_colors="$DOTFILES_DIR/.config/sketchybar/colors.sh"
            {
                echo "#!/bin/bash"
                echo "# Generated by apply-theme.sh -- do not edit by hand."
                echo "# Sourced by sketchybar plugins, which do not inherit the"
                echo "# environment sketchybarrc sets up. Theme: $THEME"
                cat "$sketchybar_colors"
            } > "$plugin_colors"
            chmod +x "$plugin_colors"

            _theme_success "sketchybar → $THEME"
        else
            _theme_warning "sketchybar: config not found or missing THEME_COLORS markers"
        fi
    fi

    # ── 14. yazi ────────────────────────────────────────────
    if command -v yazi &>/dev/null; then
        _theme_step "yazi..."
        local yazi_theme="$THEMES_DIR/yazi/theme.toml"
        if [[ -f "$yazi_theme" ]]; then
            mkdir -p "$HOME/.config/yazi"
            cp "$yazi_theme" "$HOME/.config/yazi/theme.toml"
            _theme_success "yazi → $THEME"
        else
            _theme_warning "yazi: theme file not found at $yazi_theme"
        fi
    fi

    # ── 15. gitui ───────────────────────────────────────────
    if command -v gitui &>/dev/null; then
        _theme_step "gitui..."
        local gitui_theme="$THEMES_DIR/gitui/theme.ron"
        if [[ -f "$gitui_theme" ]]; then
            mkdir -p "$HOME/.config/gitui"
            cp "$gitui_theme" "$HOME/.config/gitui/theme.ron"
            _theme_success "gitui → $THEME"
        else
            _theme_warning "gitui: theme file not found at $gitui_theme"
        fi
    fi

    # ── 16. lsd ─────────────────────────────────────────────
    if command -v lsd &>/dev/null; then
        _theme_step "lsd..."
        local lsd_colors="$THEMES_DIR/lsd/colors.yaml"
        if [[ -f "$lsd_colors" ]]; then
            mkdir -p "$HOME/.config/lsd"
            cp "$lsd_colors" "$HOME/.config/lsd/colors.yaml"
            _theme_success "lsd → $THEME"
        else
            _theme_warning "lsd: colors file not found at $lsd_colors"
        fi
    fi

    # ── Clean up rollback backups ────────────────────────
    rm -rf "$_ROLLBACK_DIR"

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
        echo "  • In Neovim: run :Lazy sync to install the theme plugin"
        echo "────────────────────────────────────────────────────"
        echo ""
    fi
}

# Allow running directly: bash scripts/apply-theme.sh <theme>
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    if [[ -z "$1" ]]; then
        echo "Usage: bash scripts/apply-theme.sh <tokyo-night|aura|catppuccin>"
        exit 1
    fi
    apply_theme "$1"
fi
