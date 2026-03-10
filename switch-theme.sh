#!/usr/bin/env bash

# ============================================
# SWITCH THEME
# ============================================
# Switch your dotfiles theme across all configured apps
# Usage: bash switch-theme.sh [tokyo-night|aura]
#        bash switch-theme.sh          (interactive picker)
# ============================================

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$DOTFILES_DIR/scripts/theme-utils.sh"
source "$DOTFILES_DIR/scripts/apply-theme.sh"

THEME="${1:-}"

# If no argument, show interactive picker
if [[ -z "$THEME" ]]; then
    THEME=$(prompt_theme_choice)
fi

# Validate
if ! validate_theme "$THEME"; then
    echo "Error: Invalid theme '$THEME'"
    echo "Valid themes: ${VALID_THEMES[*]}"
    exit 1
fi

# Check if already active
CURRENT=$(get_current_theme)
if [[ "$CURRENT" == "$THEME" ]]; then
    echo "Already using the $THEME theme."
    exit 0
fi

echo ""
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║                                                           ║"
echo "║   🎨  Switching theme: $CURRENT → $THEME"
echo "║                                                           ║"
echo "╚═══════════════════════════════════════════════════════════╝"

apply_theme "$THEME"

echo ""
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║                                                           ║"
echo "║   ✅  Theme switched to: $THEME"
echo "║                                                           ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""
