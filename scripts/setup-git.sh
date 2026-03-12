#!/usr/bin/env bash

# ============================================
# GIT CONFIGURATION — Identity & Defaults
# ============================================
# Sourced by install.sh — not meant to be run directly.
#
# Reads from caller:
#   DOTFILES_DIR, INTERACTIVE, FORCE_INSTALL
#   GIT_NAME, GIT_EMAIL (personal), GIT_WORK_EMAIL, WORK_DIR
#
# Sets for caller:
#   GIT_PERSONAL_EMAIL, GIT_WORK_EMAIL, WORK_DIR
# ============================================

source "$(dirname "${BASH_SOURCE[0]}")/_helpers.sh"

setup_git() {
    # ── Smart Defaults ────────────────────────────
    print_step "Step 8b: Configuring Git defaults..."

    git config --global core.editor "${EDITOR:-zed --wait}"
    git config --global pull.rebase false
    ln -sf "$DOTFILES_DIR/.gitignore_global" ~/.gitignore_global
    git config --global core.excludesfile ~/.gitignore_global
    git config --global diff.algorithm histogram
    git config --global rerere.enabled true
    git config --global push.autoSetupRemote true
    git config --global branch.sort -committerdate
    git config --global commit.verbose true

    print_success "Git defaults configured (editor, pull, diff, rerere, push, branch sort)"

    # ── Backup Existing Configs ───────────────────
    echo ""
    print_step "Setting up Git identity..."

    backup_if_needed ~/.gitconfig
    backup_if_needed ~/.gitconfig-work

    # ── Resolve name ──────────────────────────────
    local git_name="${GIT_NAME:-}"
    if [[ -z "$git_name" ]]; then
        git_name=$(git config --global user.name 2>/dev/null || true)
    fi
    if [[ -z "$git_name" && "$INTERACTIVE" == true ]]; then
        local existing_name existing_email
        existing_name=$(git config --global user.name 2>/dev/null || true)
        existing_email=$(git config --global user.email 2>/dev/null || true)
        if [[ -n "$existing_name" || -n "$existing_email" ]]; then
            echo "  Current identity: ${existing_name:-<not set>} <${existing_email:-<not set>}>"
            echo ""
        fi
        read -r -p "Your full name (for Git commits): " git_name
    fi

    # ── Resolve email ─────────────────────────────
    GIT_PERSONAL_EMAIL="${GIT_EMAIL:-}"
    if [[ -z "$GIT_PERSONAL_EMAIL" ]]; then
        GIT_PERSONAL_EMAIL=$(git config --global user.email 2>/dev/null || true)
    fi
    if [[ -z "$GIT_PERSONAL_EMAIL" && "$INTERACTIVE" == true ]]; then
        read -r -p "Your personal email: " GIT_PERSONAL_EMAIL
    fi

    # ── Apply identity ────────────────────────────
    if [[ -n "$git_name" && -n "$GIT_PERSONAL_EMAIL" ]]; then
        git config --global user.name "$git_name"
        git config --global user.email "$GIT_PERSONAL_EMAIL"
        print_success "Personal Git identity: $git_name <$GIT_PERSONAL_EMAIL>"
    elif [[ -n "$(git config --global user.name 2>/dev/null)" ]]; then
        print_success "Personal Git identity already configured: $(git config --global user.name) <$(git config --global user.email)>"
    else
        print_warning "Git identity not set — run: git config --global user.name / user.email"
    fi

    # ── Work Identity (Optional) ──────────────────
    local work_email="${GIT_WORK_EMAIL:-}"
    local work_dir="${WORK_DIR:-}"

    if [[ -z "$work_email" && "$INTERACTIVE" == true ]]; then
        echo ""
        read -r -p "Do you have a separate work Git identity? (y/n) " -n 1
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            read -r -p "Work email: " work_email
            read -r -p "Work directory [~/work]: " work_dir
        fi
    fi

    if [[ -n "$work_email" ]]; then
        work_dir="${work_dir:-$HOME/work}"
        work_dir="${work_dir/#\~/$HOME}"

        mkdir -p "$work_dir"
        print_success "Work directory: $work_dir"

        cat > ~/.gitconfig-work <<EOF
[user]
    email = $work_email
EOF
        print_success "Created ~/.gitconfig-work"

        # Remove existing includeIf first (idempotent)
        git config --global --unset-all "includeIf.gitdir:${work_dir}/.path" 2>/dev/null || true
        git config --global "includeIf.gitdir:${work_dir}/.path" "~/.gitconfig-work"

        print_success "Work identity configured: $work_email"
        echo ""
        echo "  How it works:"
        echo "  • Repos in $work_dir/ → $work_email"
        echo "  • Repos everywhere else → $GIT_PERSONAL_EMAIL"

        # Export for setup-ssh.sh
        GIT_WORK_EMAIL="$work_email"
        WORK_DIR="$work_dir"
    elif [[ -f ~/.gitconfig-work ]]; then
        print_success "Work identity already configured: $(git config --file ~/.gitconfig-work user.email 2>/dev/null)"
    else
        print_success "Single identity — work setup skipped"
    fi

    # Create personal projects directory
    mkdir -p "${PROJECTS_DIR:-$HOME/code}"
}
