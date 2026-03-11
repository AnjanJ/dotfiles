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

# ── Idempotent Backup ─────────────────────────
# Only backs up real files/dirs that are about to be replaced.
# Skips symlinks (those are ours) and already-backed-up files.

backup_if_needed() {
    local target="$1"

    # Nothing to back up
    [[ -e "$target" ]] || return 0

    # Symlinks are ours — no backup needed
    [[ -L "$target" ]] && return 0

    mkdir -p "$BACKUP_DIR"
    local name
    name=$(basename "$target")

    # Don't overwrite an existing backup
    if [[ ! -e "$BACKUP_DIR/$name" ]]; then
        cp -r "$target" "$BACKUP_DIR/$name"
        print_warning "Backed up $target → $BACKUP_DIR/$name"
    fi
}
