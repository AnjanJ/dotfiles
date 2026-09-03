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
# A theme may also live in ~/.config/dotfiles/themes/<name>/ (yours, or
# cloned by `dotfiles theme install`). A cloned one is a stranger's
# repo: only its colour data is staged (see _theme_sanitized_copy) and
# its Neovim spec is replaced by the palette-driven themes/_shared one.
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
source "$DOTFILES_DIR/scripts/theme-background.sh"

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

# ── Editor settings: base file tracked, live file generated ──
# Zed and VS Code have no include mechanism and both rewrite their own
# settings file when a setting changes in-app. So the repo tracks
# settings.base.json, `dotfiles theme` writes settings.json (gitignored)
# next to it with the theme filled in, and before every render anything
# that changed in the live file outside the theme keys is copied back
# into the base. Theme switches never dirty the repo; in-app edits still
# land in git. When nothing sits at the app's path yet, the link the
# symlink map would have made is created here, so a fresh install whose
# link step ran before the first render is not left without one.

# _link_generated <generated file> <app path>
_link_generated() {
    local src="$1" dst="$2"
    [[ -e "$dst" || -L "$dst" ]] && return 0
    [[ -d "$(dirname "$dst")" ]] || return 0
    ln -s "$src" "$dst"
}

# _render_zed_settings <zed theme name or empty> <light|dark>
_render_zed_settings() {
    local zed_theme="$1" mode="$2"
    local base="$DOTFILES_DIR/.config/zed/settings.base.json"
    local live="$DOTFILES_DIR/.config/zed/settings.json"
    [[ -f "$base" ]] || return 0
    if ! command -v jq &>/dev/null; then
        [[ -f "$live" ]] || cp "$base" "$live"
        _theme_warning "jq not installed: Zed settings copied without the theme"
        return 0
    fi
    local tmp
    tmp=$(mktemp)
    if [[ -f "$live" ]] && ! cmp -s <(jq -S 'del(.theme)' "$live" 2>/dev/null) <(jq -S 'del(.theme)' "$base"); then
        if jq --slurpfile b "$base" '.theme = $b[0].theme' "$live" > "$tmp" 2>/dev/null; then
            mv "$tmp" "$base"
            _theme_success "Zed settings changed in Zed → adopted into .config/zed/settings.base.json"
        else
            _theme_warning "Zed settings.json is not valid JSON; not adopted"
        fi
    fi
    # The other mode's slot keeps its last value so "system" mode still
    # has a pair; a first render takes the base file's defaults.
    local src="$base"
    [[ -f "$live" ]] && jq -e . "$live" >/dev/null 2>&1 && src="$live"
    if [[ -n "$zed_theme" && "$zed_theme" != "-" ]]; then
        jq --arg theme "$zed_theme" --arg mode "$mode" \
            '.theme.mode = $mode | .theme[$mode] = $theme' "$src" > "$tmp"
    else
        cp "$src" "$tmp"
    fi
    if [[ ! -f "$live" ]] || ! cmp -s "$tmp" "$live"; then
        mv "$tmp" "$live"
        chmod 644 "$live"   # mktemp made it 0600
        [[ -n "$zed_theme" && "$zed_theme" != "-" ]] && _theme_success "Zed → $zed_theme ($mode)"
    fi
    rm -f "$tmp"
    _link_generated "$live" "$HOME/.config/zed/settings.json"
}

# _render_vscode_settings <vscode theme name or empty>
# VS Code's file is JSONC (comments, trailing commas), so this works on
# lines: the base carries "workbench.colorTheme": "{{ vscode_theme }}".
_render_vscode_settings() {
    local vscode_theme="$1"
    local base="$DOTFILES_DIR/.config/vscode/settings.base.json"
    local live="$DOTFILES_DIR/.config/vscode/settings.json"
    [[ -f "$base" ]] || return 0
    local placeholder='"workbench.colorTheme": "{{ vscode_theme }}"'
    if [[ -f "$live" ]] && ! cmp -s <(grep -v '"workbench\.colorTheme"' "$live") <(grep -v '"workbench\.colorTheme"' "$base"); then
        sed 's/"workbench\.colorTheme": *"[^"]*"/'"$placeholder"'/' "$live" > "$base"
        _theme_success "VS Code settings changed in VS Code → adopted into .config/vscode/settings.base.json"
    fi
    if [[ -z "$vscode_theme" || "$vscode_theme" == "-" ]]; then
        # Keep whatever the live file already selects; a first render
        # falls back to VS Code's own default.
        vscode_theme=$(grep -o '"workbench\.colorTheme": *"[^"]*"' "$live" 2>/dev/null | sed 's/.*: *"\(.*\)"/\1/')
        [[ -n "$vscode_theme" && "$vscode_theme" != "{{ vscode_theme }}" ]] || vscode_theme="Default Dark Modern"
    fi
    local tmp
    tmp=$(mktemp)
    sed 's/"workbench\.colorTheme": *"[^"]*"/"workbench.colorTheme": "'"$vscode_theme"'"/' "$base" > "$tmp"
    if [[ ! -f "$live" ]] || ! cmp -s "$tmp" "$live"; then
        mv "$tmp" "$live"
        chmod 644 "$live"
        _theme_success "VS Code → $vscode_theme"
    fi
    rm -f "$tmp"
    _link_generated "$live" "$HOME/Library/Application Support/Code/User/settings.json"
}

# _set_macos_appearance <light|dark>
# Follows the theme's `mode`. Off with `dotfiles toggle appearance off` or
# DOTFILES_NO_APPEARANCE=1 (tests, CI). Prefers the `dark-mode` CLI
# (Brewfile), which flips instantly with no permission dialog; falls back
# to System Events via osascript, which macOS gates behind an Automation
# prompt the first time, so it runs under a 5s watchdog rather than
# hanging a sync.
_set_macos_appearance() {
    local mode="$1"
    [[ -z "${DOTFILES_NO_APPEARANCE:-}" ]] || return 0
    [[ "$(uname -s)" == "Darwin" ]] || return 0
    if [[ -f "$DOTFILES_DIR/bin/dotfiles-toggle" ]] \
        && ! bash "$DOTFILES_DIR/bin/dotfiles-toggle" --enabled appearance; then
        return 0
    fi
    if command -v dark-mode &>/dev/null; then
        local want=off
        [[ "$mode" == "dark" ]] && want=on
        if dark-mode "$want" >/dev/null 2>&1; then
            _theme_success "macOS appearance → $mode"
        else
            _theme_warning "macOS appearance not switched (dark-mode $want failed)"
        fi
        return 0
    fi
    local flag=false pid i=0
    [[ "$mode" == "dark" ]] && flag=true
    osascript -e "tell application \"System Events\" to tell appearance preferences to set dark mode to $flag" >/dev/null 2>&1 &
    pid=$!
    while kill -0 "$pid" 2>/dev/null && [[ $i -lt 50 ]]; do
        sleep 0.1
        i=$((i + 1))
    done
    if kill -0 "$pid" 2>/dev/null; then
        kill "$pid" 2>/dev/null || true
        _theme_warning "macOS appearance not switched: osascript timed out (allow Automation for System Events, or brew install dark-mode)"
    elif wait "$pid"; then
        _theme_success "macOS appearance → $mode"
    else
        _theme_warning "macOS appearance not switched (osascript failed)"
    fi
}

# What a cloned theme may contribute: colour data only. Everything else
# it ships can run code somewhere (nvim/*.lua is loaded by Neovim,
# theme.conf is sourced, overrides/ghostty can name a `command`,
# overrides/wezterm.lua is Lua, starship/lazygit/fzf/sketchybar/borders/
# delta overrides run or source shell) and is dropped, by name, at
# staging, so a theme that grows a file later through `git pull` is
# filtered too. Symlinks are dropped at any depth: they point wherever
# the author chose. theme.conf survives but is parsed, not sourced.
THEME_UNTRUSTED_OVERRIDES="claude.json lsd.yaml zellij.kdl"
THEME_UNTRUSTED_ASSET_DIRS="backgrounds bat zed warp xcode sublime-text"

# _theme_sanitized_copy <src> <dst> — prints one dropped path per line
_theme_sanitized_copy() {
    local src="$1" dst="$2" f d rel keep
    mkdir -p "$dst"
    for f in "$src"/* "$src"/.[!.]*; do
        [[ -e "$f" || -L "$f" ]] || continue
        rel="${f#"$src"/}"
        if [[ -L "$f" ]]; then
            echo "$rel (symlink)"
            continue
        fi
        case "$rel" in
            .git) continue ;;
            colors.toml|theme.conf|manual-instructions.txt|README.md|LICENSE|LICENSE.*)
                [[ -f "$f" ]] && cp "$f" "$dst/$rel"
                continue ;;
            overrides)
                [[ -d "$f" ]] || { echo "$rel"; continue; }
                mkdir -p "$dst/overrides"
                for d in "$f"/* "$f"/.[!.]*; do
                    [[ -e "$d" || -L "$d" ]] || continue
                    keep=false
                    if [[ ! -L "$d" && -f "$d" ]]; then
                        case " $THEME_UNTRUSTED_OVERRIDES " in *" $(basename "$d") "*) keep=true ;; esac
                    fi
                    if [[ "$keep" == true ]]; then cp "$d" "$dst/overrides/"
                    elif [[ -L "$d" ]]; then echo "overrides/$(basename "$d") (symlink)"
                    else echo "overrides/$(basename "$d")"; fi
                done
                continue ;;
        esac
        case " $THEME_UNTRUSTED_ASSET_DIRS " in
            *" $rel "*)
                [[ -d "$f" ]] || { echo "$rel"; continue; }
                mkdir -p "$dst/$rel"
                for d in "$f"/* "$f"/.[!.]*; do
                    [[ -e "$d" || -L "$d" ]] || continue
                    if [[ ! -L "$d" && -f "$d" ]]; then cp "$d" "$dst/$rel/"
                    elif [[ -L "$d" ]]; then echo "$rel/$(basename "$d") (symlink)"
                    else echo "$rel/$(basename "$d")"; fi
                done
                ;;
            *) echo "$rel" ;;
        esac
    done
}

# _theme_conf_load <theme.conf> <trusted: true|false>
# Trusted: sourced as before. Untrusted: only key="value" lines for the
# keys the pipeline knows, values without $ ` \ or quotes.
_theme_conf_load() {
    local conf="$1" trusted="$2" line key val
    if [[ "$trusted" == true ]]; then
        # shellcheck source=/dev/null
        source "$conf"
        return 0
    fi
    while IFS= read -r line || [[ -n "$line" ]]; do
        if [[ "$line" =~ ^(nvim_plugin_file|nvim_colorscheme|vscode_theme|zed_theme|bat_theme|delta_theme|warp_theme|warp_custom_file)=\"([^\"\$\`\\]*)\"[[:space:]]*(#.*)?$ ]]; then
            key="${BASH_REMATCH[1]}"; val="${BASH_REMATCH[2]}"
            printf -v "$key" '%s' "$val"
        fi
    done < "$conf"
}

# One render at a time: the menu, `dotfiles sync` and `dotfiles update`
# can all call this, and two staging dirs racing for the atomic swap
# would leave the rendered state half from each. Same mkdir lock as
# update.sh (atomic, no flock on stock bash), with stale-pid detection.
apply_theme() {
    local lock="$DOTFILES_STATE_DIR/theme.lock" holder rc
    mkdir -p "$DOTFILES_STATE_DIR"
    if ! mkdir "$lock" 2>/dev/null; then
        holder=$(cat "$lock/pid" 2>/dev/null || true)
        if [[ -n "$holder" ]] && kill -0 "$holder" 2>/dev/null; then
            echo "Error: another theme render is running (pid $holder); try again when it finishes" >&2
            return 1
        fi
        _theme_warning "Removing stale theme lock (pid ${holder:-unknown} is gone)"
        rm -rf "$lock"
        mkdir "$lock"
    fi
    echo $$ > "$lock/pid"
    rc=0
    _apply_theme_locked "$@" || rc=$?
    rm -rf "$lock"
    return "$rc"
}

# shellcheck disable=SC2154  # theme.conf variables loaded dynamically
_apply_theme_locked() {
    local THEME="$1"
    local QUIET="${2:-false}"  # pass "true" to suppress manual instructions
    local THEMES_DIR="$DOTFILES_DIR/themes/$THEME"
    local TEMPLATES_DIR="$DOTFILES_DIR/themes/_templates"
    local CURRENT_DIR="$DOTFILES_STATE_DIR/current"
    local RENDERED="$CURRENT_DIR/theme"
    local TRUSTED=true SOURCE_DIR="" SANITIZED="" dropped=""

    if ! validate_theme "$THEME"; then
        echo "Error: Invalid theme '$THEME'. Valid themes: ${VALID_THEMES[*]}"
        return 1
    fi
    if [[ ! -d "$THEMES_DIR" ]]; then
        THEMES_DIR="$(theme_dir_of "$THEME" 2>/dev/null || true)"
    fi
    if [[ -z "$THEMES_DIR" || ! -d "$THEMES_DIR" ]]; then
        echo "Error: Theme directory not found: $DOTFILES_DIR/themes/$THEME"
        return 1
    fi

    # ── Load theme registry (non-colour settings) ─────────
    local conf="$THEMES_DIR/theme.conf"
    if [[ ! -f "$conf" ]]; then
        echo "Error: Theme registry not found: $conf"
        echo "Each theme needs a theme.conf file. See themes/tokyo-night/theme.conf for an example."
        return 1
    fi
    if ! theme_is_trusted "$THEMES_DIR"; then
        TRUSTED=false
        SOURCE_DIR="$THEMES_DIR"
        SANITIZED="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-theme-src.XXXXXX")"
        dropped="$(_theme_sanitized_copy "$SOURCE_DIR" "$SANITIZED")"
        THEMES_DIR="$SANITIZED"
        conf="$THEMES_DIR/theme.conf"
        _theme_step "Installed theme (cloned): staging colour data only"
        if [[ -n "$dropped" ]]; then
            _theme_warning "Dropped from $SOURCE_DIR (code or symlink): $(echo "$dropped" | tr '\n' ' ')"
        fi
    fi
    _theme_conf_load "$conf" "$TRUSTED"

    local missing_vars=()
    # vscode_theme / zed_theme may be empty or "-": the editor keeps its theme
    local required_vars=(nvim_colorscheme bat_theme delta_theme)
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

    # Neovim: the theme's own lazy.nvim spec, or the palette-driven
    # fallback (a cloned theme's nvim/*.lua is code and was dropped; a
    # scaffold may not have one yet).
    local nvim_spec="$THEMES_DIR/nvim/$nvim_plugin_file"
    if [[ ! -f "$nvim_spec" ]]; then
        nvim_spec="$DOTFILES_DIR/themes/_shared/nvim/dotfiles-theme.lua"
        # shellcheck disable=SC2034  # read indirectly when the vars file is built
        nvim_colorscheme="dotfiles"
        _theme_warning "No nvim/$nvim_plugin_file for '$THEME'; using the palette-driven 'dotfiles' colorscheme"
    fi

    # ── Pre-flight ───────────────────────────────────────
    _theme_step "Pre-flight validation..."
    local missing_files=()
    [[ -f "$THEMES_DIR/colors.toml" ]] || missing_files+=("themes/$THEME/colors.toml")
    [[ -f "$nvim_spec" ]] || missing_files+=("themes/_shared/nvim/dotfiles-theme.lua")
    if ! compgen -G "$TEMPLATES_DIR/*.tpl" >/dev/null; then
        missing_files+=("themes/_templates/*.tpl")
    fi
    if [[ ${#missing_files[@]} -gt 0 ]]; then
        echo ""
        echo "Error: Pre-flight validation failed. Missing:"
        for f in "${missing_files[@]}"; do echo "  - $f"; done
        echo ""
        echo "Nothing was changed. Fix the above issues and try again."
        [[ -n "$SANITIZED" ]] && rm -rf "$SANITIZED"
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
        # A trusted theme.conf may carry extra keys for its own overrides;
        # the known keys are re-emitted afterwards from the loaded (and,
        # for a cloned theme, filtered) values, and a later line wins.
        [[ "$TRUSTED" == true ]] && cat "$conf"
        local k
        for k in nvim_plugin_file nvim_colorscheme vscode_theme zed_theme bat_theme delta_theme warp_theme warp_custom_file; do
            echo "$k=\"${!k:-}\""
        done
        echo "theme_name=\"$THEME\""
        echo "dotfiles_dir=\"$DOTFILES_DIR\""
        echo "nvim_plugin_spec=\"$nvim_spec\""
        echo "theme_source_dir=\"${SOURCE_DIR:-$THEMES_DIR}\""
        echo "theme_trusted=\"$TRUSTED\""
    } > "$vars"
    # The fallback colorscheme lives beside the rendered palette so its
    # path never depends on where the repo is
    cp -R "$DOTFILES_DIR/themes/_shared/nvim-dotfiles-theme" "$next/nvim-dotfiles-theme"

    # The theme's mode (light|dark): `mode` in colors.toml, else derived
    # from background luminance by the renderer. Rendered here so every
    # consumer below agrees with the templates.
    local theme_mode mode_tpl
    mode_tpl=$(mktemp)
    printf '{{ mode }}' > "$mode_tpl"
    theme_mode=$(theme_render "$next/colors.toml" "$vars" "$mode_tpl" /dev/stdout 2>/dev/null || true)
    rm -f "$mode_tpl"
    [[ "$theme_mode" == "light" ]] || theme_mode="dark"
    echo "$theme_mode" > "$next/theme.mode"

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
            [[ -n "$SANITIZED" ]] && rm -rf "$SANITIZED"
            echo ""
            echo "Error: could not render themes/_templates/$name.tpl for '$THEME'."
            echo "The active theme was left untouched."
            return 1
        fi
        rendered=$((rendered + 1))
    done
    # A desktop picture from the palette, so the theme has a background
    # even with no image in themes/<name>/backgrounds/. Cosmetic: a
    # machine without sips just has no generated one.
    if theme_background_generate "$next/colors.toml" "$next/background.png" "$vars"; then
        rendered=$((rendered + 1))
    fi
    rm -f "$vars"
    echo "$THEME" > "$next/theme.name"
    _theme_success "Rendered $rendered templates ($overridden overridden by themes/$THEME/overrides), mode: $theme_mode"

    # ── Swap ─────────────────────────────────────────────
    local previous_theme
    previous_theme="$(cat "$CURRENT_DIR/theme.name" 2>/dev/null || true)"
    rm -rf "$RENDERED"
    mv "$next" "$RENDERED"
    echo "$THEME" > "$CURRENT_DIR/theme.name"
    _theme_success "Active theme → $RENDERED"

    # ── Desktop background ───────────────────────────────
    # Only when the theme actually changed (or nothing is set yet), so a
    # `dotfiles sync` re-apply never clobbers a background you picked
    # with `dotfiles theme bg set`.
    if [[ "$previous_theme" != "$THEME" || ! -L "$THEME_BG_LINK" ]]; then
        local bg_rc=0
        theme_background_next "$THEME" || bg_rc=$?
        case "$bg_rc" in
            0) _theme_success "Background → $(basename "$(theme_background_current)")" ;;
            2) _theme_warning "Background not set: osascript timed out (allow Automation for System Events, or brew install --cask desktoppr)" ;;
            *) _theme_warning "Background not set (no image and no generated gradient, or the setter failed)" ;;
        esac
    fi

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
    # Best-effort. Zed and VS Code are rendered from their tracked
    # settings.base.json into a gitignored settings.json (see the helpers
    # at the top), so nothing here touches a tracked file.

    # Zed: its registry has no Aura, but it loads theme JSON dropped into
    # ~/.config/zed/themes. Install whatever the theme ships so the name
    # set below actually resolves -- Zed falls back silently otherwise.
    if compgen -G "$THEMES_DIR/zed/*.json" >/dev/null; then
        mkdir -p "$HOME/.config/zed/themes"
        cp "$THEMES_DIR/zed"/*.json "$HOME/.config/zed/themes/"
    fi
    _render_zed_settings "${zed_theme:-}" "$theme_mode"
    _render_vscode_settings "${vscode_theme:-}"

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

    # ── macOS appearance follows the theme's mode ─────────
    _set_macos_appearance "$theme_mode"

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

    [[ -n "$SANITIZED" ]] && rm -rf "$SANITIZED"

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
