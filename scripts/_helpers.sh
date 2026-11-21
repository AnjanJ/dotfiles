#!/usr/bin/env bash

# ============================================
# SHARED HELPERS — Colors & Print Functions
# ============================================
# Sourced by: install.sh, scripts/*.sh, bin/_work-helpers
# Not meant to be run directly.
# ============================================

# Source guard — prevent double-sourcing
[[ -n "${_HELPERS_LOADED:-}" ]] && return 0
_HELPERS_LOADED=1

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_step() {
    echo -e "${BLUE}==>${NC} ${GREEN}$1${NC}"
}

print_warning() {
    echo -e "${YELLOW}Warning:${NC} $1"
}

print_error() {
    echo -e "${RED}Error:${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_fail() {
    echo -e "${RED}✗${NC} $1"
}

# ── Shared Constants ──────────────────────────

BACKUP_DIR="${BACKUP_DIR:-$HOME/.dotfiles_backup}"

# ── Backup ────────────────────────────────────
# Copies a real file or directory that is about to be replaced into
# $BACKUP_DIR at its path relative to $HOME (~/.config/zed/settings.json →
# $BACKUP_DIR/.config/zed/settings.json), so targets that share a name
# never share a backup. Symlinks are ours and are skipped. A backup that
# already exists is kept and the new copy gets a timestamp suffix: a real
# file showing up again at a managed path is new data, never a duplicate.

backup_if_needed() {
    local target="$1"

    # Nothing to back up
    [[ -e "$target" ]] || return 0

    # Symlinks are ours — no backup needed
    [[ -L "$target" ]] && return 0

    local rel="${target#"$HOME"/}"
    [[ "$rel" == "$target" ]] && rel="${target#/}"
    local dest="$BACKUP_DIR/$rel"
    [[ -e "$dest" || -L "$dest" ]] && dest="$dest.$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$(dirname "$dest")"
    cp -R "$target" "$dest"
    print_warning "Backed up $target → $dest"
}
