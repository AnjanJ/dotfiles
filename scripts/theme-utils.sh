#!/usr/bin/env bash

# ============================================
# THEME UTILITIES
# ============================================
# Shared functions for theme management
# Sourced by: install.sh, apply-theme.sh
# ============================================

THEME_STATE_FILE="$HOME/.dotfiles-theme"
VALID_THEMES=("tokyo-night" "aura")

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
    for valid in "${VALID_THEMES[@]}"; do
        if [[ "$valid" == "$theme" ]]; then
            return 0
        fi
    done
    return 1
}

# Interactive theme picker
prompt_theme_choice() {
    echo ""
    echo "Choose your theme:"
    echo ""
    echo "  1) Tokyo Night  — Dark blue aesthetic by folke"
    echo "     Subtle, calm colors. Blue and purple accents."
    echo ""
    echo "  2) Aura Dark    — Deep purple aesthetic by daltonmenezes"
    echo "     Vibrant, bold colors. Purple and green accents."
    echo ""
    read -p "Enter choice [1]: " theme_choice
    case "${theme_choice:-1}" in
        1) echo "tokyo-night" ;;
        2) echo "aura" ;;
        *)
            echo "Invalid choice, defaulting to Tokyo Night" >&2
            echo "tokyo-night"
            ;;
    esac
}
