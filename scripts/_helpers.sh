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
