# SSH & Security

## Choosing how keys are provided

`install.sh` (and `dotfiles install`, which runs it) sets up SSH once, in `scripts/setup-ssh.sh`. The mode comes from `--ssh <mode>`, from the `DOTFILES_SSH_MODE` environment variable, or, with `--interactive`, from a numbered prompt. A non-interactive run with nothing set auto-detects: `1password` when the 1Password agent socket exists, otherwise `skip` with a hint about enabling the agent.

| Mode | Prompt | What it does |
|------|--------|--------------|
| `1password` | 1 | Symlinks `~/.1password/agent.sock` to the 1Password socket and writes a `~/.ssh/config` whose `Host *` sets `IdentityAgent ~/.1password/agent.sock`. No key files on disk; the keys live in the vault. |
| `import` | 2 | Asks for a directory (USB drive, backup folder, iCloud), copies its keys, `.pub` files and `known_hosts` into `~/.ssh/`, then continues like `existing`. Interactive only: the path is always prompted for. |
| `existing` | 3 | Uses the keys already in `~/.ssh/`: writes the config, fixes permissions. Stops with a warning when there is no `.pub` file to work with. |
| `generate` | 4 | Creates `~/.ssh/id_ed25519_personal` (comment: your git email) and, when a work email was given (`--work-email` or `DOTFILES_WORK_EMAIL`), `~/.ssh/id_ed25519_work`. No passphrase; each key is added to the agent with `--apple-use-keychain`; an existing file is kept, not overwritten. Ends by printing the `cat ~/.ssh/id_ed25519_*.pub | pbcopy` lines and where to paste them. |
| `skip` | 5 | Leaves `~/.ssh/` alone. Any unknown value means skip too. |

Every mode except `skip` backs up `~/.ssh/` to the install's backup directory once, asks which Git services you use (GitHub, GitLab, Bitbucket, Codeberg, or a custom Gerrit/self-hosted host; non-interactive runs take GitHub, or the numbers in `DOTFILES_GIT_SERVICES`), offers an alias suffix per service (`work` makes `github.com-work`), regenerates `~/.ssh/config` from scratch, fixes permissions (700 on the directory, 600 on private keys) and prints a troubleshooting guide. Without 1Password each `Host` block also names the key you picked (non-interactively, the only key when there is exactly one) with `IdentityFile`, `IdentitiesOnly yes` and `IdentityAgent none`, so the 1Password agent, if it is ever wired in globally, cannot shadow an on-disk key. With 1Password the host blocks carry no key at all; the vault decides.

To rerun the step later, run the installer again with the mode you want; it is idempotent and the other steps are quick when nothing changed:

```bash
dotfiles install --ssh 1password        # after enabling the agent
dotfiles install --ssh generate         # fresh keys
DOTFILES_SSH_MODE=existing dotfiles install
```

`scripts/setup-ssh.sh` only defines functions for the installer to call, so running it on its own does nothing.

## 1Password SSH Agent (recommended — and auto-detected)

The Brewfile installs the 1Password app + CLI automatically. SSH-agent wiring auto-detects:

- If 1Password is signed in **and** the SSH Agent is enabled before you run `install.sh`, the install wires `~/.ssh/config` to the agent socket automatically.
- If 1Password isn't ready yet, install skips SSH setup and prints a hint.

**Fresh-Mac flow** (the order I recommend):

1. Run `install.sh` — this lands the 1Password app along with everything else.
2. Open 1Password.app → sign in to your account → vaults sync from cloud.
3. **1Password → Settings → Developer → "Set Up SSH Agent"** (toggle ON).
4. Run the SSH wiring step now that the agent is alive:
   ```bash
   dotfiles install --ssh 1password
   ```
5. Test with Touch ID: `ssh -T git@github.com`.

> **Where do my SSH keys come from?** They must already be in your 1Password vault (synced automatically from a previous machine), or added manually via 1Password → New Item → SSH Key (generate or paste). The dotfiles only configure the *agent*, not the keys.

**What this gives you:**

- **Touch ID for git push** — each new terminal session requires biometric approval before SSH operations
- **No key files on disk** — keys live in your 1Password vault, encrypted and synced
- **Works everywhere** — GitHub, GitLab, Bitbucket, Codeberg, self-hosted Git

**How it works under the hood:**

1. Install symlinks `~/.1password/agent.sock` to 1Password's actual socket
2. `~/.ssh/config` sets `IdentityAgent ~/.1password/agent.sock`
3. When you `git push` in a new terminal session, 1Password prompts for Touch ID
4. Approval lasts until 1Password locks (configurable timeout)

**Recommended 1Password settings for maximum security:**

| Setting | Value | Why |
|---------|-------|-----|
| Ask approval for each new | `application and terminal session` | Per-tab approval, not global |
| Remember key approval | `until 1Password locks` | Approval expires on lock |
| Auto-lock after idle | `1 minute` (or shortest you're comfortable with) | Frequent re-authentication |

> **Note:** This is per-session, not per-push. Once you approve in a terminal tab, subsequent pushes in that tab go through until 1Password locks. For additional protection, use a short auto-lock timeout.

> **Debugging tip:** if `git push` suddenly fails with an SSH error, the usual cause is that 1Password isn't running (or is locked) — not a problem with the keys themselves.

## Work hosts

A work identity gets its own key and its own host aliases, kept apart from the personal setup above so the two never share a key or an email.

`dotfiles work setup` (`bin/work-setup`) asks for the work email and directory, then for the key: pick one already in `~/.ssh/`, generate `~/.ssh/id_ed25519_work` (comment: the work email, no passphrase, added to the agent with the keychain), or skip. With a key chosen it asks which services the work account uses and an alias suffix per host (`work` makes `github.com-work`), then rewrites one marked block in `~/.ssh/config`:

```
# === WORK: example.com ===
Host github.com-work
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519_work
    IdentitiesOnly yes

# === END WORK ===
```

The block sits between `# === WORK: <email domain> ===` and `# === END WORK ===`; a rerun removes the old block and appends a fresh one, so the personal hosts above it are never touched. `IdentitiesOnly yes` keeps ssh from offering the personal or vault keys to a work host. Clone with the alias: `git clone git@github.com-work:org/repo.git`, or point an existing checkout at it with `git remote set-url origin git@github.com-work:org/repo.git`.

`dotfiles work status` (`bin/work-status`) reads the `Host` lines between the markers and checks each one with `ssh -G`: the key file it resolves to and whether that file exists (a missing file is reported as a failure), or "1Password or agent-managed" when the host names no file. It warns when it finds `github.com-work`/`gitlab.com-work` aliases outside the markers, which is what an older hand-written config looks like, and when no work hosts are configured at all.

See [QUICK_REFERENCE.md](../QUICK_REFERENCE.md#ssh-setup) for SSH troubleshooting and testing commands.
