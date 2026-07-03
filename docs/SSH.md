# SSH & Security

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
   bash ~/dotfiles/scripts/setup-ssh.sh
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

See [QUICK_REFERENCE.md](../QUICK_REFERENCE.md#ssh-setup) for SSH troubleshooting and testing commands.
