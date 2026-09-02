#!/usr/bin/env bash

# ============================================
# APPLY THEME — palette-first
# ============================================
# One palette file per theme (themes/<name>/colors.toml) is rendered
# through themes/_templates/*.tpl into a staging directory, swapped
# atomically into ~/.local/state/dotfiles/current/theme/, and then
# installed into the apps that cannot read from there directly.
#
#   themes/<name>/colors.toml      the palette (Omarchy-compatible keys)
#   themes/<name>/theme.conf       non-colour settings (editor theme names…)
#   themes/<name>/overrides/<out>  hand-written file that beats the template
#   themes/_templates/<out>.tpl    one template per rendered file
#
# Nothing tracked in git is modified by a theme switch: apps either
# include the rendered file (ghostty, starship, lazygit, wezterm, nvim,
# delta, fzf) or get a gitignored generated copy inside their config dir
# (zellij, sketchybar, borders). A few GUI apps still need their own
# settings edited (Zed, VS Code, Warp); those stay best-effort.
#
# Usage: bash scripts/apply-theme.sh <theme>
#    or: source scripts/apply-theme.sh && apply_theme <theme> [quiet]
# ============================================

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

source "$DOTFILES_DIR/scripts/theme-utils.sh"
source "$DOTFILES_DIR/scripts/theme-render.sh"

# Rendered-theme state root. Tests point HOME at a sandbox, so derive
# from HOME rather than hard-coding the user's path.
DOTFILES_STATE_DIR="${DOTFILES_STATE_DIR:-$HOME/.local/state/dotfiles}"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

_theme_success() { echo -e "${GREEN}✓${NC} $1"; }
_theme_warning() { echo -e "${YELLOW}Warning:${NC} $1"; }
_theme_step()    { echo -e "${BLUE}==>${NC} $1"; }

# _install_rendered <rendered-name> <destination>
# Copies one rendered file to where an app expects it.
_install_rendered() {
    local src="$DOTFILES_STATE_DIR/current/theme/$1" dst="$2"
    [[ -f "$src" ]] || return 1
    mkdir -p "$(dirname "$dst")"
    cp "$src" "$dst"
}

# shellcheck disable=SC2154  # theme.conf variables loaded dynamically
apply_theme() {
    local THEME="$1"
    local QUIET="${2:-false}"  # pass "true" to suppress manual instructions
    local THEMES_DIR="$DOTFILES_DIR/themes/$THEME"
    local TEMPLATES_DIR="$DOTFILES_DIR/themes/_templates"
    local CURRENT_DIR="$DOTFILES_STATE_DIR/current"
    local RENDERED="$CURRENT_DIR/theme"

    if ! validate_theme "$THEME"; then
        echo "Error: Invalid theme '$THEME'. Valid themes: ${VALID_THEMES[*]}"
        return 1
    fi
    if [[ ! -d "$THEMES_DIR" ]]; then
        echo "Error: Theme directory not found: $THEMES_DIR"
        return 1
    fi

    # ── Load theme registry (non-colour settings) ─────────
    local conf="$THEMES_DIR/theme.conf"
    if [[ ! -f "$conf" ]]; then
        echo "Error: Theme registry not found: $conf"
        echo "Each theme needs a theme.conf file. See themes/tokyo-night/theme.conf for an example."
        return 1
    fi
    # shellcheck source=/dev/null
    source "$conf"

    local missing_vars=()
    local required_vars=(nvim_colorscheme vscode_theme zed_theme bat_theme delta_theme)
    for var in "${required_vars[@]}"; do
        [[ -z "${!var:-}" ]] && missing_vars+=("$var")
    done
    if [[ ${#missing_vars[@]} -gt 0 ]]; then
        echo "Error: theme.conf is missing required variables:"
        for v in "${missing_vars[@]}"; do echo "  - $v"; done
        echo ""
        echo "See themes/tokyo-night/theme.conf for an example."
        return 1
    fi
    local nvim_plugin_file="${nvim_plugin_file:-$THEME-theme.lua}"

    # ── Pre-flight ───────────────────────────────────────
    _theme_step "Pre-flight validation..."
    local missing_files=()
    [[ -f "$THEMES_DIR/colors.toml" ]] || missing_files+=("themes/$THEME/colors.toml")
    [[ -f "$THEMES_DIR/nvim/$nvim_plugin_file" ]] || missing_files+=("themes/$THEME/nvim/$nvim_plugin_file")
    if ! compgen -G "$TEMPLATES_DIR/*.tpl" >/dev/null; then
        missing_files+=("themes/_templates/*.tpl")
    fi
    if [[ ${#missing_files[@]} -gt 0 ]]; then
        echo ""
        echo "Error: Pre-flight validation failed. Missing:"
        for f in "${missing_files[@]}"; do echo "  - $f"; done
        echo ""
        echo "Nothing was changed. Fix the above issues and try again."
        return 1
    fi
    _theme_success "Palette, templates and theme.conf verified"

    echo ""
    _theme_step "Applying theme: $THEME"
    echo ""

    # ── Stage: render everything into next-theme ──────────
    # The live theme dir is untouched until every template has rendered,
    # so a broken template or palette can never leave apps half-themed.
    _theme_step "Rendering templates..."
    local next="$CURRENT_DIR/next-theme"
    rm -rf "$next"
    mkdir -p "$next"
    cp "$THEMES_DIR/colors.toml" "$next/colors.toml"

    # Hand-written overrides beat templates (copied first; render skips
    # any output that already exists)
    if [[ -d "$THEMES_DIR/overrides" ]]; then
        cp -R "$THEMES_DIR/overrides/." "$next/"
    fi

    # Template variables beyond the palette: theme.conf plus a few facts
    local vars
    vars=$(mktemp)
    {
        cat "$conf"
        echo "theme_name=\"$THEME\""
        echo "dotfiles_dir=\"$DOTFILES_DIR\""
        echo "nvim_plugin_spec=\"$THEMES_DIR/nvim/$nvim_plugin_file\""
    } > "$vars"

    local tpl out name rendered=0 overridden=0
    for tpl in "$TEMPLATES_DIR"/*.tpl; do
        name=$(basename "$tpl" .tpl)
        out="$next/$name"
        if [[ -f "$out" ]]; then
            overridden=$((overridden + 1))
            continue
        fi
        if ! theme_render "$next/colors.toml" "$vars" "$tpl" "$out"; then
            rm -f "$vars"
            rm -rf "$next"
            echo ""
            echo "Error: could not render themes/_templates/$name.tpl for '$THEME'."
            echo "The active theme was left untouched."
            return 1
        fi
        rendered=$((rendered + 1))
    done
    rm -f "$vars"
    echo "$THEME" > "$next/theme.name"
    _theme_success "Rendered $rendered templates ($overridden overridden by themes/$THEME/overrides)"

    # ── Swap ─────────────────────────────────────────────
    rm -rf "$RENDERED"
    mv "$next" "$RENDERED"
    echo "$THEME" > "$CURRENT_DIR/theme.name"
    _theme_success "Active theme → $RENDERED"

    # ── Install into apps ─────────────────────────────────
    # Apps that can include the rendered file need nothing here: ghostty
    # (config-file), starship ($STARSHIP_CONFIG), lazygit ($LG_CONFIG_FILE),
    # wezterm (dofile), nvim (dofile), git-delta ([include]).
    echo ""

    # Generated, gitignored copies inside linked config dirs (these apps
    # cannot take an absolute include path)
    _install_rendered ghostty "$DOTFILES_DIR/.config/ghostty/theme.generated" \
        && _theme_success "Ghostty → .config/ghostty/theme.generated"
    _install_rendered zellij.kdl "$DOTFILES_DIR/.config/zellij/themes/dotfiles.kdl" \
        && _theme_success "Zellij → .config/zellij/themes/dotfiles.kdl"
    _install_rendered sketchybar-colors.sh "$DOTFILES_DIR/.config/sketchybar/colors.sh" \
        && _theme_success "sketchybar → .config/sketchybar/colors.sh"
    _install_rendered borders-colors.sh "$DOTFILES_DIR/.config/borders/colors.sh" \
        && _theme_success "borders → .config/borders/colors.sh"

    # Files that live outside the repo
    _install_rendered fzf.zsh "$HOME/.zshrc-theme-env" \
        && _theme_success "fzf → ~/.zshrc-theme-env"

    if command -v lsd &>/dev/null; then
        _install_rendered lsd.yaml "$HOME/.config/lsd/colors.yaml" \
            && _theme_success "lsd → ~/.config/lsd/colors.yaml"
    fi

    if command -v bat &>/dev/null; then
        # Some themes ship a custom .tmTheme (bat has no built-in Aura).
        # Install it and rebuild the cache, or --theme names a theme bat
        # does not know and it silently falls back to the default.
        if compgen -G "$THEMES_DIR/bat/*.tmTheme" >/dev/null; then
            mkdir -p "$HOME/.config/bat/themes"
            cp "$THEMES_DIR/bat"/*.tmTheme "$HOME/.config/bat/themes/"
            bat cache --build &>/dev/null
        fi
        _install_rendered bat.conf "$HOME/.config/bat/config" \
            && _theme_success "bat → $bat_theme"
    fi

    # Claude Code watches ~/.claude/themes and hot-reloads the file, so a
    # running session retints. settings.json selects "custom:dotfiles".
    if [[ -d "$HOME/.claude" ]]; then
        _install_rendered claude.json "$HOME/.claude/themes/dotfiles.json" \
            && _theme_success "Claude Code → ~/.claude/themes/dotfiles.json"
    fi

    # ── GUI apps that only accept their own settings edits ─
    # Best-effort, and none of them are tracked-file mutations except Zed
    # and VS Code, whose settings.json files are symlinked into the repo.

    # Zed: its registry has no Aura, but it loads theme JSON dropped into
    # ~/.config/zed/themes. Install whatever the theme ships so the name
    # set below actually resolves -- Zed falls back silently otherwise.
    local zed_settings="$DOTFILES_DIR/.config/zed/settings.json"
    if compgen -G "$THEMES_DIR/zed/*.json" >/dev/null; then
        mkdir -p "$HOME/.config/zed/themes"
        cp "$THEMES_DIR/zed"/*.json "$HOME/.config/zed/themes/"
    fi
    if [[ -f "$zed_settings" ]] && command -v jq &>/dev/null; then
        local tmpfile
        tmpfile=$(mktemp)
        if jq --arg theme "$zed_theme" '.theme.dark = $theme' "$zed_settings" > "$tmpfile" 2>/dev/null \
            && ! cmp -s "$tmpfile" "$zed_settings"; then
            mv "$tmpfile" "$zed_settings"
            _theme_success "Zed → $zed_theme"
        else
            rm -f "$tmpfile"
        fi
    fi

    # VS Code uses JSONC, so sed rather than jq. Resolve the symlink first:
    # BSD sed -i refuses to edit symlinks.
    local vscode_settings="$HOME/Library/Application Support/Code/User/settings.json"
    [[ -L "$vscode_settings" ]] && vscode_settings=$(readlink "$vscode_settings")
    if [[ -f "$vscode_settings" ]]; then
        if grep -q '"workbench\.colorTheme"' "$vscode_settings"; then
            if ! grep -q "\"workbench\.colorTheme\": *\"$vscode_theme\"" "$vscode_settings"; then
                sed -i '' 's/"workbench\.colorTheme": *"[^"]*"/"workbench.colorTheme": "'"$vscode_theme"'"/' "$vscode_settings"
                _theme_success "VS Code → $vscode_theme"
            fi
        elif head -1 "$vscode_settings" | grep -q '^{'; then
            sed -i '' '1a\
\  "workbench.colorTheme": "'"$vscode_theme"'",
' "$vscode_settings"
            _theme_success "VS Code → $vscode_theme (key added)"
        fi
    fi

    if [[ -n "${warp_theme:-}" ]] && { command -v warp-cli &>/dev/null || [[ -d "/Applications/Warp.app" ]]; }; then
        local warp_themes_dir="$HOME/.warp/themes"
        if [[ -n "${warp_custom_file:-}" && -f "$THEMES_DIR/$warp_custom_file" ]]; then
            mkdir -p "$warp_themes_dir"
            cp "$THEMES_DIR/$warp_custom_file" "$warp_themes_dir/"
            local yaml_name yaml_path
            yaml_name=$(basename "$warp_custom_file" .yaml)
            yaml_path="$warp_themes_dir/$(basename "$warp_custom_file")"
            defaults write dev.warp.Warp-Stable Theme "\"Custom\""
            defaults write dev.warp.Warp-Stable SelectedSystemThemes -string \
                '{"light":"Light","dark":{"Custom":{"name":"'"${yaml_name}"'","path":"'"${yaml_path}"'"}}}'
            _theme_success "Warp → $warp_theme (custom)"
        else
            defaults write dev.warp.Warp-Stable Theme "\"${warp_theme}\""
            _theme_success "Warp → $warp_theme (built-in)"
        fi
    fi

    # Xcode reads .xccolortheme files from its UserData dir; still has to
    # be picked once in Settings -> Themes.
    if [[ -d "/Applications/Xcode.app" ]] && compgen -G "$THEMES_DIR/xcode/*.xccolortheme" >/dev/null; then
        local xcode_themes="$HOME/Library/Developer/Xcode/UserData/FontAndColorThemes"
        mkdir -p "$xcode_themes"
        cp "$THEMES_DIR/xcode"/*.xccolortheme "$xcode_themes/"
        _theme_success "Xcode → $THEME (select it in Settings → Themes)"
    fi

    if [[ -d "/Applications/Sublime Text.app" ]] && compgen -G "$THEMES_DIR/sublime-text/*.tmTheme" >/dev/null; then
        local st_user="$HOME/Library/Application Support/Sublime Text/Packages/User"
        if [[ -d "$st_user" ]]; then
            cp "$THEMES_DIR/sublime-text"/*.tmTheme "$st_user/"
            _theme_success "Sublime Text → $THEME"
        fi
    fi

    # ── Retint running apps (best-effort) ────────────────
    if command -v sketchybar &>/dev/null && pgrep -x sketchybar >/dev/null 2>&1; then
        sketchybar --reload &>/dev/null && _theme_success "sketchybar reloaded"
    fi

    # ── Save state ────────────────────────────────────────
    set_current_theme "$THEME"

    # ── User hooks: ~/.config/dotfiles/hooks/theme-set{,.d/} ─
    if [[ -x "$DOTFILES_DIR/bin/dotfiles-hook" ]]; then
        "$DOTFILES_DIR/bin/dotfiles-hook" theme-set "$THEME"
    fi

    # ── Manual steps (skipped in quiet mode, e.g. during sync) ──
    if [[ "$QUIET" != "true" ]]; then
        echo ""
        local manual_file="$THEMES_DIR/manual-instructions.txt"
        [[ -f "$manual_file" ]] && cat "$manual_file"
        echo ""
        echo "────────────────────────────────────────────────────"
        echo "  Post-apply reminders:"
        echo "────────────────────────────────────────────────────"
        echo "  • New shells pick up the prompt/fzf colours; run: source ~/.zshrc"
        echo "  • Ghostty: reload config (cmd+shift+,); WezTerm and Zellij on next launch"
        echo "  • Neovim: restart, then :Lazy sync if the theme plugin is new"
        echo "────────────────────────────────────────────────────"
        echo ""
    fi
}

# Allow running directly: bash scripts/apply-theme.sh <theme>
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    if [[ -z "${1:-}" ]]; then
        echo "Usage: bash scripts/apply-theme.sh <${VALID_THEMES[*]// /|}>"
        exit 1
    fi
    apply_theme "$1"
fi
