#!/usr/bin/env bash

# ============================================
# THEME UTILITIES
# ============================================
# Shared functions for theme management
# Sourced by: install.sh, apply-theme.sh
# ============================================

THEME_STATE_FILE="$HOME/.dotfiles-theme"

# Auto-discover available themes from themes/*/theme.conf
_discover_themes() {
    local script_dir
    # Support both bash (BASH_SOURCE) and zsh (%x)
    if [[ -n "${BASH_SOURCE[0]:-}" ]]; then
        script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
    else
        # shellcheck disable=SC2296  # zsh-specific syntax
        script_dir="$(cd "$(dirname "${(%):-%x}")/.." && pwd)"
    fi
    local themes_dir="${DOTFILES_DIR:-$script_dir}/themes"
    local themes=()
    for conf in "$themes_dir"/*/theme.conf; do
        [[ -f "$conf" ]] || continue
        themes+=("$(basename "$(dirname "$conf")")")
    done
    echo "${themes[@]+"${themes[@]}"}"
}

# shellcheck disable=SC2207
VALID_THEMES=($(_discover_themes))

# Get the currently active theme (defaults to tokyo-night)
get_current_theme() {
    if [[ -f "$THEME_STATE_FILE" ]]; then
        cat "$THEME_STATE_FILE"
    else
        echo "tokyo-night"
    fi
}

# Save the active theme to state file
set_current_theme() {
    local theme="$1"
    echo "$theme" > "$THEME_STATE_FILE"
}

# Check if a theme name is valid
validate_theme() {
    local theme="$1"
    local valid
    for valid in ${VALID_THEMES[@]+"${VALID_THEMES[@]}"}; do
        if [[ "$valid" == "$theme" ]]; then
            return 0
        fi
    done
    return 1
}

# Theme descriptions for interactive picker
_get_theme_description() {
    case "$1" in
        tokyo-night) printf "Tokyo Night  — Dark blue aesthetic by folke\n     Subtle, calm colors. Blue and purple accents." ;;
        aura)        printf "Aura Dark    — Deep purple aesthetic by daltonmenezes\n     Vibrant, bold colors. Purple and green accents." ;;
        catppuccin)  printf "Catppuccin   — Warm pastel aesthetic by catppuccin\n     Soothing pastels. Lavender and teal accents." ;;
        *)           printf "%s" "$1" ;;
    esac
}

# Interactive theme picker
prompt_theme_choice() {
    echo "" >&2
    echo "Choose your theme:" >&2
    echo "" >&2

    local i=1
    local theme_order=()
    for theme in ${VALID_THEMES[@]+"${VALID_THEMES[@]}"}; do
        theme_order+=("$theme")
        local desc
        desc=$(_get_theme_description "$theme")
        echo -e "  $i) $desc" >&2
        echo "" >&2
        i=$((i + 1))
    done

    read -r -p "Enter choice [1]: " theme_choice
    local idx="${theme_choice:-1}"

    if [[ "$idx" =~ ^[0-9]+$ ]] && [[ "$idx" -ge 1 ]] && [[ "$idx" -le ${#theme_order[@]} ]]; then
        echo "${theme_order[$((idx - 1))]}"
    else
        echo "Invalid choice, defaulting to ${theme_order[0]}" >&2
        echo "${theme_order[0]}"
    fi
}
