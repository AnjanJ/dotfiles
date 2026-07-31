#!/usr/bin/env bash

# ============================================
# SSH CONFIGURATION — Keys & Host Config
# ============================================
# Sourced by install.sh — not meant to be run directly.
#
# Expects from caller: BACKUP_DIR, GIT_PERSONAL_EMAIL, GIT_WORK_EMAIL
# ============================================

source "$(dirname "${BASH_SOURCE[0]}")/_helpers.sh"

# ── Known Git Services ────────────────────────
# Format: "display_name|hostname|default_user|default_port"
_GIT_SERVICES=(
    "GitHub|github.com|git|22"
    "GitLab|gitlab.com|git|22"
    "Bitbucket|bitbucket.org|git|22"
    "Codeberg|codeberg.org|git|22"
    "Gerrit (custom host)|CUSTOM|CUSTOM|CUSTOM"
    "Self-hosted Git (custom host)|CUSTOM|CUSTOM|CUSTOM"
)

# ── Helper Functions ──────────────────────────

_list_ssh_keys() {
    local dir="$1"
    local found=false
    for pub in "$dir"/*.pub; do
        [[ -f "$pub" ]] || continue
        local name
        name=$(basename "$pub" .pub)
        local type
        type=$(awk '{print $1}' "$pub")
        local comment
        comment=$(awk '{print $3}' "$pub")
        echo "    • $name ($type) ${comment:+— $comment}"
        found=true
    done
    if [[ "$found" == false ]]; then
        echo "    (no keys found)"
    fi
}

_pick_key() {
    local purpose="$1"
    local dir="${2:-$HOME/.ssh}"
    local keys=()

    for pub in "$dir"/*.pub; do
        [[ -f "$pub" ]] || continue
        local _name
        _name=$(basename "$pub" .pub)
        keys+=("$_name")
    done

    if [[ ${#keys[@]} -eq 0 ]]; then
        echo ""
        return
    fi

    # All human-facing output here goes to stderr. This function is called in
    # a $(...) substitution, so anything on stdout becomes part of the
    # returned key filename — the menu itself would be swallowed into it.
    local i=1
    {
        echo ""
        echo "  Available keys:"
        for k in "${keys[@]}"; do
            local comment
            comment=$(awk '{print $3}' "$dir/$k.pub" 2>/dev/null)
            echo "    $i) $k ${comment:+— $comment}"
            ((i++))
        done
        echo "    $i) None / Skip"
    } >&2

    # This function returns its answer on stdout, so the prompt must go to
    # stderr — otherwise the prompt text is captured as the key filename.
    # A non-interactive run picks the sole key if there's exactly one, and
    # otherwise declines to guess.
    local KEY_NUM=""
    if [[ "${INTERACTIVE:-false}" != true ]]; then
        if [[ ${#keys[@]} -eq 1 ]]; then
            KEY_NUM=1
        else
            echo ""
            return
        fi
    else
        read -r -t 60 -p "  Which key for $purpose? (1-$i): " KEY_NUM >&2 || KEY_NUM=""
    fi

    if [[ "$KEY_NUM" -ge 1 && "$KEY_NUM" -lt "$i" ]] 2>/dev/null; then
        echo "${keys[$((KEY_NUM-1))]}"
    else
        echo ""
    fi
}

SSH_HOSTS=()

_pick_services_and_keys() {
    local use_1password="$1"

    # GitHub is entry 1 in _GIT_SERVICES and the overwhelmingly common case.
    # Used both as the non-interactive default and as the timeout fallback.
    local _default_services="1"

    # A non-interactive run must never block here. This function is called by
    # EVERY handler including the 1password path, which the non-interactive
    # auto-detect selects — so without this guard `install.sh` (which is
    # non-interactive by default) sat forever on a prompt nobody was watching.
    if [[ "${INTERACTIVE:-false}" != true ]]; then
        SELECTED_SERVICES="${DOTFILES_GIT_SERVICES:-$_default_services}"
        print_success "Git services: GitHub (default — set DOTFILES_GIT_SERVICES to override)"
    else
        echo ""
        echo "  Which Git services do you use? (select all that apply)"
        echo ""

        local i=1
        for svc in "${_GIT_SERVICES[@]}"; do
            local display="${svc%%|*}"
            echo "    $i) $display"
            ((i++))
        done
        echo ""
        echo "  Enter numbers separated by spaces (e.g., 1 2 5), or 'none' to skip."
        echo "  Waiting 60s — defaults to GitHub if you don't answer."

        # -t 60: an unattended-but-interactive run (piped from curl, left on a
        # second monitor) should proceed rather than hang overnight. `read`
        # returns non-zero on timeout, so guard it under `set -e`.
        if ! read -r -t 60 -p "  > " SELECTED_SERVICES; then
            SELECTED_SERVICES=""
            echo ""
            print_warning "No answer in 60s — defaulting to GitHub"
        fi
        # Bare Enter means "default", not "none".
        SELECTED_SERVICES="${SELECTED_SERVICES:-$_default_services}"
    fi

    if [[ "$SELECTED_SERVICES" == "none" ]]; then
        return
    fi

    for num in $SELECTED_SERVICES; do
        if ! [[ "$num" =~ ^[0-9]+$ ]] || [[ "$num" -lt 1 || "$num" -gt ${#_GIT_SERVICES[@]} ]]; then
            print_warning "Skipping invalid selection: $num"
            continue
        fi

        local svc="${_GIT_SERVICES[$((num-1))]}"
        local display
        display=$(echo "$svc" | cut -d'|' -f1)
        local hostname
        hostname=$(echo "$svc" | cut -d'|' -f2)
        local user
        user=$(echo "$svc" | cut -d'|' -f3)
        local port
        port=$(echo "$svc" | cut -d'|' -f4)
        local alias_name=""

        echo ""
        print_step "Configuring: $display"

        # Handle custom hosts (Gerrit, self-hosted)
        if [[ "$hostname" == "CUSTOM" ]]; then
            read -r -p "  Hostname (e.g., gerrit.example.com, git.myserver.com): " hostname
            if [[ -z "$hostname" ]]; then
                print_warning "No hostname provided, skipping"
                continue
            fi
            read -r -p "  SSH user [git]: " user
            user="${user:-git}"
            read -r -p "  SSH port [22]: " port
            port="${port:-22}"
        fi

        local alias_suffix=""
        if [[ "${INTERACTIVE:-false}" == true ]]; then
            read -r -t 60 -p "  Alias for this connection? (e.g., 'work' for github.com-work, or Enter for default): " alias_suffix || alias_suffix=""
        fi
        if [[ -n "$alias_suffix" ]]; then
            alias_name="${hostname}-${alias_suffix}"
        else
            alias_name="$hostname"
        fi

        # Pick SSH key (skip for 1Password — it handles key selection internally)
        local keyfile=""
        if [[ "$use_1password" != "true" ]]; then
            keyfile=$(_pick_key "$display ($alias_name)")
        fi

        SSH_HOSTS+=("${alias_name}|${hostname}|${user}|${port}|${keyfile}")
    done
}

_build_ssh_config() {
    local use_1password="$1"

    mkdir -p ~/.ssh
    local config_file=~/.ssh/config

    cat > "$config_file" <<'SSHEOF'
# ============================================
# SSH CONFIGURATION
# ============================================
# Generated by dotfiles install.sh
# Modify freely — re-running install.sh will back up
# this file before regenerating.
# ============================================

SSHEOF

    if [[ "$use_1password" == "true" ]]; then
        cat >> "$config_file" <<'SSHEOF'
# Use 1Password SSH Agent for all connections
# Keys are served from your 1Password vault — no key files needed on disk
Host *
    IdentityAgent ~/.1password/agent.sock

SSHEOF
    else
        cat >> "$config_file" <<'SSHEOF'
# Global defaults
Host *
    AddKeysToAgent yes
    UseKeychain yes
    IdentitiesOnly yes

SSHEOF
    fi

    for entry in "${SSH_HOSTS[@]}"; do
        local alias_name
        alias_name=$(echo "$entry" | cut -d'|' -f1)
        local hostname
        hostname=$(echo "$entry" | cut -d'|' -f2)
        local user
        user=$(echo "$entry" | cut -d'|' -f3)
        local port
        port=$(echo "$entry" | cut -d'|' -f4)
        local keyfile
        keyfile=$(echo "$entry" | cut -d'|' -f5)

        cat >> "$config_file" <<SSHEOF
Host $alias_name
    HostName $hostname
    User $user
SSHEOF

        [[ "$port" != "22" ]] && echo "    Port $port" >> "$config_file"

        if [[ -n "$keyfile" ]]; then
            echo "    IdentityFile ~/.ssh/$keyfile" >> "$config_file"
        fi

        echo "    IdentitiesOnly yes" >> "$config_file"
        echo "" >> "$config_file"

        if [[ "$alias_name" != "$hostname" ]]; then
            print_success "SSH: $alias_name → $hostname (clone: git@${alias_name}:org/repo.git)"
        else
            print_success "SSH: $hostname configured"
        fi
    done

    chmod 644 "$config_file"
    print_success "Generated ~/.ssh/config"
}

_fix_ssh_permissions() {
    chmod 700 ~/.ssh
    for f in ~/.ssh/id_* ~/.ssh/*_rsa ~/.ssh/*_ed25519 ~/.ssh/*_ecdsa; do
        [[ -f "$f" && "$f" != *.pub ]] && chmod 600 "$f"
    done
    for f in ~/.ssh/*.pub; do
        [[ -f "$f" ]] && chmod 644 "$f"
    done
    [[ -f ~/.ssh/config ]] && chmod 644 ~/.ssh/config
    [[ -f ~/.ssh/known_hosts ]] && chmod 644 ~/.ssh/known_hosts
    print_success "SSH permissions fixed"
}

_print_ssh_troubleshooting() {
    echo ""
    echo "────────────────────────────────────────────────────"
    echo "  SSH Troubleshooting Guide"
    echo "────────────────────────────────────────────────────"
    echo ""
    echo "  Test a connection:"
    echo "    ssh -T git@github.com"
    echo "    ssh -T git@gitlab.com"
    echo "    ssh -T git@github.com-work    # (if you set up an alias)"
    echo ""
    echo "  Debug a connection (verbose output):"
    echo "    ssh -vT git@github.com"
    echo "    Look for: 'Offering public key' and 'Server accepts key'"
    echo ""
    echo "  Check which key SSH is using:"
    echo "    ssh -G github.com | grep identityfile"
    echo ""
    echo "  List keys loaded in agent:"
    echo "    ssh-add -l"
    echo ""
    echo "  Add a key to macOS Keychain:"
    echo "    ssh-add --apple-use-keychain ~/.ssh/your_key"
    echo ""
    echo "  Permission denied? Check:"
    echo "    1. Key is added to the service (GitHub/GitLab/etc.)"
    echo "       cat ~/.ssh/your_key.pub | pbcopy  # copy public key"
    echo "    2. Permissions are correct:"
    echo "       ls -la ~/.ssh/  # private keys must be 600, dir must be 700"
    echo "    3. Config points to the right key:"
    echo "       cat ~/.ssh/config"
    echo ""
    echo "  Using an alias (e.g., github.com-work)?"
    echo "    Clone:  git clone git@github.com-work:org/repo.git"
    echo "    Existing repo: git remote set-url origin git@github.com-work:org/repo.git"
    echo ""
    echo "  Restore previous SSH config:"
    echo "    cp -r $BACKUP_DIR/ssh/ ~/.ssh/"
    echo "────────────────────────────────────────────────────"
}

# ── Main Entry Point ──────────────────────────

setup_ssh() {
    echo ""
    print_step "Step 8c: SSH key setup..."

    # Back up existing ~/.ssh/ (idempotent — only if not already backed up)
    if [[ -d ~/.ssh && ! -d "$BACKUP_DIR/ssh" ]]; then
        mkdir -p "$BACKUP_DIR"
        cp -r ~/.ssh "$BACKUP_DIR/ssh"
        print_success "Backed up ~/.ssh/ → $BACKUP_DIR/ssh/"
    fi

    # Determine SSH mode
    local ssh_choice="${SSH_MODE:-}"

    if [[ -z "$ssh_choice" ]]; then
        if [[ "$INTERACTIVE" == true ]]; then
            echo ""
            echo "How would you like to set up SSH keys?"
            echo ""
            echo "  1) 1Password SSH Agent (recommended)"
            echo "     Keys stored in 1Password vault, synced across machines, Touch ID"
            echo ""
            echo "  2) Import keys from another location"
            echo "     Copy existing keys from a USB drive, backup folder, iCloud, etc."
            echo ""
            echo "  3) Use keys already in ~/.ssh/"
            echo "     Configure SSH config + fix permissions for your existing keys"
            echo ""
            echo "  4) Generate new Ed25519 keys"
            echo "     Create fresh keys for this machine"
            echo ""
            echo "  5) Skip"
            echo "     Don't touch SSH configuration"
            echo ""
            read -r -p "Choose (1-5): " ssh_choice
            echo
        else
            # Non-interactive default: auto-detect 1Password SSH agent.
            # If the user has 1Password installed AND has enabled the SSH
            # Agent (Settings → Developer → Set Up SSH Agent), wire it up.
            # Otherwise skip and surface a clear hint at the end of install.
            local _op_socket="$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
            if [[ -S "$_op_socket" ]]; then
                ssh_choice="1password"
                print_success "1Password SSH agent detected — will wire it up"
            else
                ssh_choice="skip"
                if [[ -d "/Applications/1Password.app" ]]; then
                    print_warning "1Password installed but SSH agent not enabled yet"
                    echo "  After signing in, go to: 1Password → Settings → Developer → Set Up SSH Agent"
                    echo "  Then re-run: bash ~/dotfiles/scripts/setup-ssh.sh"
                fi
            fi
        fi
    fi

    # Map named modes to handler numbers
    case "$ssh_choice" in
        1password|1) _setup_ssh_1password ;;
        import|2)    _setup_ssh_import ;;
        existing|3)  _setup_ssh_existing ;;
        generate|4)  _setup_ssh_generate ;;
        skip|5|*)    print_success "SSH setup skipped" ;;
    esac
}

# ── Option Handlers ───────────────────────────

_setup_ssh_1password() {
    print_step "Setting up 1Password SSH Agent..."

    mkdir -p ~/.1password
    local op_socket="$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
    if [[ -S "$op_socket" ]]; then
        ln -sf "$op_socket" ~/.1password/agent.sock
        print_success "1Password SSH agent socket linked"
    else
        print_warning "1Password SSH agent socket not found"
        echo "  Enable it: 1Password → Settings → Developer → Set Up SSH Agent"
        echo "  Then re-run install.sh or manually run:"
        echo "  ln -sf \"$op_socket\" ~/.1password/agent.sock"
    fi

    _pick_services_and_keys "true"
    _build_ssh_config "true"
    _fix_ssh_permissions
    _print_ssh_troubleshooting

    echo ""
    echo "  Next: Add your SSH keys to 1Password"
    echo "  1Password will serve them via the agent — no key files needed on disk"
}

_setup_ssh_import() {
    print_step "Import SSH keys..."
    echo ""
    echo "  Enter the path to your keys (e.g., /Volumes/USB/ssh-keys, ~/Desktop/old-ssh)"
    read -r -p "  Path: " IMPORT_PATH
    IMPORT_PATH="${IMPORT_PATH/#\~/$HOME}"

    if [[ ! -d "$IMPORT_PATH" ]]; then
        print_error "Directory not found: $IMPORT_PATH"
        print_warning "Skipping SSH setup"
        return
    fi

    echo ""
    echo "  Keys found in $IMPORT_PATH:"
    _list_ssh_keys "$IMPORT_PATH"

    echo ""
    read -r -p "  Copy these keys to ~/.ssh/? (y/n) " -n 1
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_warning "Import cancelled"
        return
    fi

    mkdir -p ~/.ssh

    # Copy all key files
    for f in "$IMPORT_PATH"/id_* "$IMPORT_PATH"/*_rsa "$IMPORT_PATH"/*_ed25519 "$IMPORT_PATH"/*_ecdsa "$IMPORT_PATH"/*.pub "$IMPORT_PATH"/known_hosts; do
        [[ -f "$f" ]] && cp "$f" ~/.ssh/
    done

    # Copy any other key-like files (custom names)
    for f in "$IMPORT_PATH"/*; do
        [[ -f "$f" ]] || continue
        local name
        name=$(basename "$f")
        [[ "$name" == ".DS_Store" || "$name" == "*.log" || "$name" == "config" ]] && continue
        [[ ! -f ~/.ssh/"$name" ]] && cp "$f" ~/.ssh/
    done

    print_success "Keys imported to ~/.ssh/"
    _fix_ssh_permissions

    echo ""
    echo "  Keys now in ~/.ssh/:"
    _list_ssh_keys ~/.ssh

    _pick_services_and_keys "false"
    _build_ssh_config "false"
    _print_ssh_troubleshooting
}

_setup_ssh_existing() {
    print_step "Configuring existing SSH keys..."

    if [[ ! -d ~/.ssh ]] || ! ls ~/.ssh/*.pub &>/dev/null; then
        print_warning "No SSH keys found in ~/.ssh/"
        print_warning "Skipping SSH configuration"
        return
    fi

    echo ""
    echo "  Keys found in ~/.ssh/:"
    _list_ssh_keys ~/.ssh

    _pick_services_and_keys "false"
    _build_ssh_config "false"
    _fix_ssh_permissions
    _print_ssh_troubleshooting
}

_setup_ssh_generate() {
    print_step "Generating new SSH keys..."
    mkdir -p ~/.ssh

    # Personal key
    if [[ -n "${GIT_PERSONAL_EMAIL:-}" ]]; then
        local personal_keyfile=~/.ssh/id_ed25519_personal
        if [[ -f "$personal_keyfile" ]]; then
            print_warning "Key already exists: $personal_keyfile (skipping)"
        else
            ssh-keygen -t ed25519 -C "$GIT_PERSONAL_EMAIL" -f "$personal_keyfile" -N ""
            ssh-add --apple-use-keychain "$personal_keyfile" 2>/dev/null || true
            print_success "Generated personal key: $personal_keyfile"
        fi
    fi

    # Work key (if work identity configured)
    if [[ -n "${GIT_WORK_EMAIL:-}" ]]; then
        local work_keyfile=~/.ssh/id_ed25519_work
        if [[ -f "$work_keyfile" ]]; then
            print_warning "Key already exists: $work_keyfile (skipping)"
        else
            ssh-keygen -t ed25519 -C "$GIT_WORK_EMAIL" -f "$work_keyfile" -N ""
            ssh-add --apple-use-keychain "$work_keyfile" 2>/dev/null || true
            print_success "Generated work key: $work_keyfile"
        fi
    fi

    echo ""
    echo "  Keys now in ~/.ssh/:"
    _list_ssh_keys ~/.ssh

    _pick_services_and_keys "false"
    _build_ssh_config "false"
    _fix_ssh_permissions

    echo ""
    echo "  Add your public keys to each service:"
    for pub in ~/.ssh/id_ed25519_*.pub; do
        [[ -f "$pub" ]] || continue
        local name
        name=$(basename "$pub")
        echo "    cat ~/.ssh/$name | pbcopy"
    done
    echo "  Then paste at: GitHub → Settings → SSH keys → New"
    echo "                 GitLab → Preferences → SSH Keys"
    echo "                 Bitbucket → Personal Settings → SSH Keys"
    echo "                 Codeberg → Settings → SSH / GPG Keys"

    _print_ssh_troubleshooting
}
