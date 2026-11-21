#!/usr/bin/env bash

# ============================================
# COMMIT SIGNING — an SSH key held by 1Password, set up per machine
# ============================================
# Sourced by install.sh (step 8d). Also runs on its own:
#   bash scripts/setup-git-signing.sh ["<1Password item name>" | none]
#
# The tracked .gitconfig points gpg.ssh.program at 1Password's op-ssh-sign
# but turns nothing on: which key signs, and whether commits are signed,
# are per machine and stay out of the public repo. This writes:
#   ~/.gitconfig.local              user.signingkey, commit.gpgsign = true,
#                                   gpg.ssh.allowedSignersFile (mode 600)
#   ~/.config/git/allowed_signers   "<email> namespaces="git" <key>", so
#                                   `git log --show-signature` can check
#   ~/.config/git/signing_key.pub   the public key, for `gh ssh-key add`
#
# Which key: SIGNING_KEY (--signing-key, DOTFILES_SIGNING_KEY or the answers
# file's signing_key) names the 1Password item; "none" skips the step. With
# no name, an interactive run lists the agent's keys and asks, and an
# unattended run leaves signing off with a hint: once signing is on, every
# commit fails while 1Password is locked, so it is never switched on for
# someone who did not choose a key. A machine that already has a
# user.signingkey keeps it unless a key is named.
#
# Reads from caller: INTERACTIVE, SIGNING_KEY
# Overrides for tests: DOTFILES_OP_AGENT_SOCK, DOTFILES_OP_SSH_SIGN
# Bash 3.2 compatible: install.sh runs it.
# ============================================

source "$(dirname "${BASH_SOURCE[0]}")/_helpers.sh"

_signing_agent_sock() {
    printf '%s' "${DOTFILES_OP_AGENT_SOCK:-$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock}"
}

_signing_program() {
    printf '%s' "${DOTFILES_OP_SSH_SIGN:-/Applications/1Password.app/Contents/MacOS/op-ssh-sign}"
}

# The agent's public keys, one "<type> <key> <item name>" per line. The
# agent answers "no identities" on stdout with exit 1 when it holds none.
_signing_agent_keys() {
    SSH_AUTH_SOCK="$(_signing_agent_sock)" ssh-add -L 2>/dev/null | /usr/bin/grep '^ssh-' || true
}

# _signing_find <item name> — prints "<type> <key>" for that agent key.
_signing_find() {
    local want="$1" type key label
    while read -r type key label; do
        if [[ -n "$key" && "$label" == "$want" ]]; then
            printf '%s %s\n' "$type" "$key"
            return 0
        fi
    done <<EOF
$(_signing_agent_keys)
EOF
    return 1
}

# _signing_allow <public key> — lets git check signatures made with the key
# by listing it, under the git email, in ~/.config/git/allowed_signers.
_signing_allow() {
    local pub="$1" email line type key file="$HOME/.config/git/allowed_signers"
    email=$(git config --global user.email 2>/dev/null || true)
    if [[ -z "$email" ]]; then
        print_warning "No Git email yet, so signatures cannot be checked on this machine"
        return 0
    fi
    # A key set by hand may carry its label as a trailing comment; the
    # same key with or without one is one signer, not two.
    read -r type key _ <<EOF
$pub
EOF
    line="$email namespaces=\"git\" $type $key"
    mkdir -p "$(dirname "$file")"
    if [[ ! -f "$file" ]] || ! /usr/bin/grep -qF "$line" "$file"; then
        printf '%s\n' "$line" >> "$file"
    fi
    chmod 600 "$file"
    # shellcheck disable=SC2088  # git expands the tilde itself
    git config -f "$HOME/.gitconfig.local" gpg.ssh.allowedSignersFile "~/.config/git/allowed_signers"
}

_signing_apply() {
    local pub="$1" label="$2" cfg="$HOME/.gitconfig.local"
    [[ -f "$cfg" ]] || : > "$cfg"
    chmod 600 "$cfg"
    git config -f "$cfg" user.signingkey "$pub"
    git config -f "$cfg" commit.gpgsign true
    _signing_allow "$pub"
    mkdir -p "$HOME/.config/git"
    printf '%s %s\n' "$pub" "$label" > "$HOME/.config/git/signing_key.pub"
    print_success "Commits are signed with \"$label\" from 1Password (it asks to approve)"
    echo "  Once per key, register it on GitHub so signed commits show as Verified:"
    echo "    gh auth refresh -h github.com -s admin:ssh_signing_key"
    echo "    gh ssh-key add ~/.config/git/signing_key.pub --type signing --title \"$label\""
}

setup_git_signing() {
    local want="${SIGNING_KEY:-}" existing keys label choice n pub
    local self
    self="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/setup-git-signing.sh"
    echo ""
    print_step "Step 8d: Commit signing..."

    if [[ "$want" == "none" ]]; then
        print_success "Commit signing skipped"
        return 0
    fi

    existing=$(git config -f "$HOME/.gitconfig.local" user.signingkey 2>/dev/null || true)
    if [[ -z "$want" && -n "$existing" ]]; then
        _signing_allow "$existing"
        print_success "Commit signing already set up on this machine"
        return 0
    fi

    if [[ ! -x "$(_signing_program)" || ! -S "$(_signing_agent_sock)" ]]; then
        if [[ -n "$want" ]]; then
            print_warning "Commit signing needs 1Password's SSH agent; skipped"
            echo "  Enable it: 1Password → Settings → Developer → Set Up SSH Agent"
            echo "  Then run: bash \"$self\" \"$want\""
        else
            print_success "Commit signing skipped (no 1Password SSH agent)"
        fi
        return 0
    fi

    keys=$(_signing_agent_keys)
    if [[ -z "$keys" ]]; then
        print_success "Commit signing skipped (1Password's SSH agent holds no keys)"
        return 0
    fi

    if [[ -z "$want" ]]; then
        if [[ "$INTERACTIVE" != true ]]; then
            print_success "Commit signing left off"
            echo "  To sign with a key in 1Password: bash \"$self\" \"<item name>\""
            return 0
        fi
        local labels=()
        echo ""
        echo "Sign Git commits with an SSH key from 1Password?"
        while read -r _ _ label; do
            labels+=("$label")
            echo "  ${#labels[@]}) $label"
        done <<EOF
$keys
EOF
        n=${#labels[@]}
        echo "  0) Don't sign commits"
        read -r -p "Choose (0-$n): " choice
        if [[ ! "$choice" =~ ^[0-9]+$ ]] || (( choice < 1 || choice > n )); then
            print_success "Commit signing left off"
            return 0
        fi
        want="${labels[$((choice - 1))]}"
    fi

    if ! pub=$(_signing_find "$want"); then
        print_warning "No key named \"$want\" in 1Password's SSH agent; commit signing skipped"
        return 0
    fi
    _signing_apply "$pub" "$want"
}

# Run directly: the first argument names the key; ask when on a terminal.
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    set -eu
    SIGNING_KEY="${1:-${DOTFILES_SIGNING_KEY:-}}"
    INTERACTIVE=false
    [[ -t 0 ]] && INTERACTIVE=true
    setup_git_signing
fi
