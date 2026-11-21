#!/usr/bin/env bash
# doc: Git signing — `scripts/setup-git-signing.sh`: picks a 1Password SSH key by item name or prompt, writes ~/.gitconfig.local and allowed_signers, leaves unattended runs and machines without the agent alone, runs under bash 3.2

# Uses a temporary HOME, a stub ssh-add and a real Unix socket standing in
# for 1Password's agent; no real config or agent is touched.
# Usage: tests/run git-signing

set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

SCRIPT="$ROOT/scripts/setup-git-signing.sh"
STUB="$TEST_TMP/stub"
mkdir -p "$STUB"
KEY_A="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKeyForGitSigningTestOnly"
KEY_B="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOtherKeyTestOnly"
printf '%s Git signing\n%s Server login\n' "$KEY_A" "$KEY_B" > "$TEST_TMP/agent-keys"

# ssh-add -L prints whatever the fake agent holds; like the real one, it
# says so on stdout and exits 1 when it holds nothing.
cat > "$STUB/ssh-add" <<EOF
#!/bin/bash
if [[ -s "$TEST_TMP/agent-keys" ]]; then cat "$TEST_TMP/agent-keys"; else echo "The agent has no identities."; exit 1; fi
EOF
printf '#!/bin/bash\nexit 0\n' > "$TEST_TMP/op-ssh-sign"
chmod +x "$STUB/ssh-add" "$TEST_TMP/op-ssh-sign"
export PATH="$STUB:$PATH"

SOCK="$TEST_TMP/agent.sock"
python3 -c 'import socket, sys; socket.socket(socket.AF_UNIX).bind(sys.argv[1])' "$SOCK"
export DOTFILES_OP_AGENT_SOCK="$SOCK" DOTFILES_OP_SSH_SIGN="$TEST_TMP/op-ssh-sign"

LOCAL="$HOME/.gitconfig.local"
SIGNERS="$HOME/.config/git/allowed_signers"

fresh() {
    rm -rf "$LOCAL" "$HOME/.config/git"
    printf '[user]\n\temail = signer@example.com\n' > "$HOME/.gitconfig"
}

# run [stdin] — the script as install.sh uses it: sourced, then called.
run() {
    local input="${1:-}"
    # shellcheck disable=SC2016  # expanded by the inner bash
    printf '%s\n' "$input" | /opt/homebrew/bin/bash -c 'source "$1"; setup_git_signing' _ "$SCRIPT" 2>&1
}

local_get() { git config -f "$LOCAL" "$1" 2>/dev/null || true; }

section "a named key"
fresh
out=$(SIGNING_KEY="Git signing" INTERACTIVE=false run)
assert_contains "$out" 'Commits are signed with "Git signing"' "reports the key it chose"
assert_eq "$(local_get user.signingkey)" "$KEY_A" "the key goes into ~/.gitconfig.local"
assert_eq "$(local_get commit.gpgsign)" "true" "and signing is switched on"
assert_eq "$(local_get gpg.ssh.allowedSignersFile)" "~/.config/git/allowed_signers" "with the allowed signers file named"
assert_eq "$(/bin/cat "$SIGNERS")" "signer@example.com namespaces=\"git\" $KEY_A" "allowed_signers lists the key under the Git email"
assert_eq "$(stat -f %Lp "$LOCAL")" "600" "~/.gitconfig.local is private"
assert_eq "$(stat -f %Lp "$SIGNERS")" "600" "allowed_signers is private"
assert_eq "$(/bin/cat "$HOME/.config/git/signing_key.pub")" "$KEY_A Git signing" "the public key is saved for gh ssh-key add"
assert_contains "$out" "gh ssh-key add ~/.config/git/signing_key.pub --type signing" "and the GitHub step is printed"

SIGNING_KEY="Git signing" INTERACTIVE=false run >/dev/null
assert_eq "$(/usr/bin/grep -c . "$SIGNERS")" "1" "a second run adds no duplicate line"

section "nothing named"
fresh
out=$(INTERACTIVE=false run)
assert_contains "$out" "Commit signing left off" "an unattended run does not pick a key"
assert_contains "$out" "bash \"$SCRIPT\" \"<item name>\"" "and its hint names this script's real path"
assert_file_not_exists "$LOCAL" "and writes nothing"

out=$(INTERACTIVE=true run 2)
assert_contains "$out" "1) Git signing" "an interactive run lists the agent's keys"
assert_contains "$out" "2) Server login" "by their 1Password item names"
assert_eq "$(local_get user.signingkey)" "$KEY_B" "and signs with the one chosen"

fresh
out=$(INTERACTIVE=true run 0)
assert_contains "$out" "Commit signing left off" "0 declines"
assert_file_not_exists "$LOCAL" "and writes nothing"
out=$(INTERACTIVE=true run x)
assert_file_not_exists "$LOCAL" "so does an answer that is not a number"

section "an existing setup"
fresh
printf '[user]\n\tsigningkey = %s\n[commit]\n\tgpgsign = false\n' "$KEY_B" > "$LOCAL"
out=$(INTERACTIVE=true run 1)
assert_contains "$out" "already set up" "a machine with a signing key keeps it"
assert_eq "$(local_get user.signingkey)" "$KEY_B" "the key is unchanged"
assert_eq "$(local_get commit.gpgsign)" "false" "and so is the switch"
assert_file_contains "$SIGNERS" "$KEY_B" "but its key can now be checked"
SIGNING_KEY="Git signing" INTERACTIVE=false run >/dev/null
assert_eq "$(local_get user.signingkey)" "$KEY_A" "naming a key replaces the old one"
assert_eq "$(local_get commit.gpgsign)" "true" "and switches signing on"
fresh
printf '[user]\n\tsigningkey = %s Git signing\n' "$KEY_A" > "$LOCAL"
INTERACTIVE=false run >/dev/null
SIGNING_KEY="Git signing" INTERACTIVE=false run >/dev/null
assert_eq "$(/usr/bin/grep -c . "$SIGNERS")" "1" "a key stored with its label is the same signer as without"

section "skips"
fresh
out=$(SIGNING_KEY=none INTERACTIVE=true run 1)
assert_contains "$out" "Commit signing skipped" "none skips the step"
assert_file_not_exists "$LOCAL" "without writing"
out=$(SIGNING_KEY="No such item" INTERACTIVE=false run)
assert_contains "$out" 'No key named "No such item"' "an unknown item name warns"
assert_file_not_exists "$LOCAL" "and writes nothing"
out=$(SIGNING_KEY="Git signing" DOTFILES_OP_AGENT_SOCK="$TEST_TMP/absent.sock" INTERACTIVE=false run)
assert_contains "$out" "needs 1Password's SSH agent" "a named key without the agent says what is missing"
assert_file_not_exists "$LOCAL" "and writes nothing"
out=$(DOTFILES_OP_AGENT_SOCK="$TEST_TMP/absent.sock" INTERACTIVE=false run)
assert_contains "$out" "skipped (no 1Password SSH agent)" "with nothing named, no agent is a quiet skip"
out=$(SIGNING_KEY="Git signing" DOTFILES_OP_SSH_SIGN="$TEST_TMP/absent" INTERACTIVE=false run)
assert_file_not_exists "$LOCAL" "no op-ssh-sign, no signing"
: > "$TEST_TMP/agent-keys"
out=$(INTERACTIVE=true run 1)
assert_contains "$out" "holds no keys" "an empty agent is a quiet skip"
assert_file_not_exists "$LOCAL" "and writes nothing"
printf '%s Git signing\n%s Server login\n' "$KEY_A" "$KEY_B" > "$TEST_TMP/agent-keys"

fresh
printf '' > "$HOME/.gitconfig"
SIGNING_KEY="Git signing" INTERACTIVE=false run >/dev/null
assert_eq "$(local_get user.signingkey)" "$KEY_A" "with no Git email, signing still works"
assert_file_not_exists "$SIGNERS" "but nothing can be listed as allowed"

section "bash 3.2, run directly"
fresh
rc=0
out=$(/bin/bash "$SCRIPT" "Git signing" </dev/null 2>&1) || rc=$?
assert_eq "$rc" "0" "/bin/bash runs it with an item name"
assert_eq "$(local_get user.signingkey)" "$KEY_A" "and sets the key"
assert_eq "$(/bin/bash -n "$SCRIPT" && echo ok)" "ok" "parses under /bin/bash"
