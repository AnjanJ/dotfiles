#!/usr/bin/env bash

# ============================================
# GIT CONFIGURATION — Identity & Defaults
# ============================================
# Sourced by install.sh — not meant to be run directly.
#
# Expects from caller: DOTFILES_DIR, BACKUP_DIR
# Sets for caller:     GIT_PERSONAL_EMAIL, GIT_WORK_EMAIL, WORK_DIR
# (These are intentionally NOT local — install.sh passes them to setup-ssh.sh)
# ============================================

source "$(dirname "${BASH_SOURCE[0]}")/_helpers.sh"

setup_git() {
    # ── Smart Defaults ────────────────────────────
    print_step "Step 9b: Configuring Git defaults..."

    git config --global core.editor "zed --wait"
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

    if [[ -f ~/.gitconfig ]]; then
        cp ~/.gitconfig "$BACKUP_DIR/.gitconfig"
        print_success "Backed up ~/.gitconfig → $BACKUP_DIR/.gitconfig"
    fi
    if [[ -f ~/.gitconfig-work ]]; then
        cp ~/.gitconfig-work "$BACKUP_DIR/.gitconfig-work"
        print_success "Backed up ~/.gitconfig-work → $BACKUP_DIR/.gitconfig-work"
    fi

    echo ""
    echo "Your personal Git identity will be used everywhere by default."
    echo ""

    # Show existing identity if any
    local existing_name existing_email
    existing_name=$(git config --global user.name 2>/dev/null || true)
    existing_email=$(git config --global user.email 2>/dev/null || true)
    if [[ -n "$existing_name" || -n "$existing_email" ]]; then
        echo "  Current identity: ${existing_name:-<not set>} <${existing_email:-<not set>}>"
        echo "  (backed up to $BACKUP_DIR — restore anytime with: cp $BACKUP_DIR/.gitconfig ~/.gitconfig)"
        echo ""
    fi

    # ── Personal Identity ─────────────────────────
    local git_name
    read -p "Your full name (for Git commits): " git_name
    read -p "Your personal email: " GIT_PERSONAL_EMAIL

    if [[ -n "$git_name" && -n "$GIT_PERSONAL_EMAIL" ]]; then
        git config --global user.name "$git_name"
        git config --global user.email "$GIT_PERSONAL_EMAIL"
        print_success "Personal Git identity: $git_name <$GIT_PERSONAL_EMAIL>"
    else
        print_warning "Skipped — set manually: git config --global user.name / user.email"
    fi

    # ── Work Identity (Optional) ──────────────────
    echo ""
    read -p "Do you have a separate work Git identity? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        local work_dir_input
        read -p "Work email: " GIT_WORK_EMAIL
        read -p "Work directory [~/work]: " work_dir_input
        WORK_DIR="${work_dir_input:-$HOME/work}"
        WORK_DIR="${WORK_DIR/#\~/$HOME}"

        if [[ -n "$GIT_WORK_EMAIL" ]]; then
            mkdir -p "$WORK_DIR"
            print_success "Work directory created: $WORK_DIR"

            cat > ~/.gitconfig-work <<EOF
[user]
    email = $GIT_WORK_EMAIL
EOF
            print_success "Created ~/.gitconfig-work"

            # Remove existing includeIf first (idempotent)
            git config --global --unset-all "includeIf.gitdir:${WORK_DIR}/.path" 2>/dev/null || true
            git config --global "includeIf.gitdir:${WORK_DIR}/.path" "~/.gitconfig-work"

            print_success "Work identity configured: $git_name <$GIT_WORK_EMAIL>"
            echo ""
            echo "  How it works:"
            echo "  • Repos in $WORK_DIR/ → $GIT_WORK_EMAIL"
            echo "  • Repos everywhere else → $GIT_PERSONAL_EMAIL"
            echo "  • Verify: cd into a repo and run 'git config user.email'"
        else
            print_warning "No work email provided, skipping work identity"
        fi
    else
        print_success "Single identity configured — work setup skipped"
    fi

    # Create personal projects directory
    mkdir -p "${PROJECTS_DIR:-$HOME/code}"
}
