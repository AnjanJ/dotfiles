# Maintenance

All commands work from anywhere — no need to `cd ~/dotfiles` first.

## Dotfiles CLI

```bash
dotfiles update       # Upgrade system & sync repo (pull → brew upgrade → snapshot → push)
dotfiles sync         # Quick refresh: pull, relink, reapply theme (no upgrades)
dotfiles health       # Verify all tools are installed and configured
dotfiles theme aura   # Switch theme (tokyo-night | aura | catppuccin)
dotfiles add-theme x  # Scaffold a new theme directory with all required files
dotfiles cleanup      # Find/remove Homebrew packages not in Brewfile (--force)
dotfiles doctor       # Auto-fix common issues (symlinks, permissions, SSH keys)
dotfiles backup       # Snapshot dotfiles state (--list, --restore <name>)
dotfiles profile      # Measure shell startup time (--detailed for per-component)
dotfiles export       # Export setup snapshot (--json for machine-readable)
dotfiles install      # Re-run full installer (idempotent)
dotfiles uninstall    # Remove all dotfiles symlinks
dotfiles edit         # Open dotfiles in your editor
dotfiles dir          # Print dotfiles directory path
```

All commands support tab-completion. Shorthand also works: `dotfiles-update`, `dotfiles-sync`, etc.

## What `dotfiles update` does

1. Pull latest changes from git
2. `brew update` + `brew upgrade` + `brew cleanup`
3. Snapshot installed packages and show diff against Brewfile (without overwriting the organized Brewfile)
4. Refresh all symlinks (from `scripts/symlink-map.sh`)
5. Upgrade mise tools
6. Reload live configs (aerospace)
7. Commit & push changes back to repo

**Your Brewfile stays organized.** The Brewfile is organized into `@group` sections (core, editors, work, databases, etc.) and `dotfiles update` never overwrites it. The snapshot step shows you what's new or missing compared to your system.

## Brewfile recovery

Two layers of safety net:

**1. Git history is the source of truth.** Every previous Brewfile is one command away:

```bash
# View the previous version
git -C ~/dotfiles show HEAD~1:Brewfile

# Restore the previous version to a working file
git -C ~/dotfiles show HEAD~1:Brewfile > /tmp/Brewfile.previous

# Roll the tracked Brewfile back N commits and reinstall
git -C ~/dotfiles checkout HEAD~1 -- Brewfile
brew bundle install --file=~/dotfiles/Brewfile
```

**2. `Brewfile.backup` (local only, gitignored).** `dotfiles update` writes a copy of the *previous* Brewfile to `~/dotfiles/Brewfile.backup` before each upgrade. It's not tracked in git (no commit noise) but lives on disk for one-step rollback if an upgrade breaks your machine:

```bash
# Quick rollback after a bad `dotfiles update`
cp ~/dotfiles/Brewfile.backup ~/dotfiles/Brewfile
brew bundle install --file=~/dotfiles/Brewfile

# Inspect what changed before rolling back
diff ~/dotfiles/Brewfile.backup ~/dotfiles/Brewfile
```

The on-disk backup only holds the *most recent* previous state. For older versions, use `git log -- Brewfile` to find the commit and `git show <sha>:Brewfile` to restore.

## Health check

```bash
dotfiles health
```

Verifies: core tools, every managed symlink (swept from `scripts/symlink-map.sh` — a repo file that was never linked fails loudly), language runtimes, running services (PostgreSQL, MySQL, Redis), shell integrations, and work identity.

## Re-run installation

The install script is idempotent — run it any number of times with identical results:

```bash
dotfiles install                    # Non-interactive, skips what's done
dotfiles install --interactive      # Prompt for every choice
dotfiles install --force            # Force reinstall everything
```

## Testing

Every push and PR runs 11 test suites plus shellcheck via GitHub Actions:

- **Shellcheck** — lints all shell scripts
- **Idempotency** — install/setup can run repeatedly with identical results (sandboxed)
- **Work identity** — setup, nuke, switch lifecycle, and status diagnostics
- **SSH config** — adversarial inputs and edge cases
- **Repo cloner** — SSH alias detection and URL rewriting
- **Update flow** — symlink creation and refresh
- **Theme system** — apply, rollback, idempotency, scaffolding
- **Doctor** — auto-fix symlinks, permissions, dry-run mode
- **Git setup** — identity configuration, work/personal split, smart defaults
- **Backup** — create, list, restore, prune cycle
- **Sync** — symlink refresh, broken link repair, dry-run mode

Run locally (needs bash 4+, i.e. `brew install bash` — macOS ships 3.2):

```bash
/opt/homebrew/bin/bash tests/test-idempotency.sh   # or any suite in tests/
```

## Troubleshooting

### Homebrew not found

```bash
# Apple Silicon
eval "$(/opt/homebrew/bin/brew shellenv)"

# Intel
eval "$(/usr/local/bin/brew shellenv)"
```

### Neovim errors

```bash
# Clear cache and reinstall
rm -rf ~/.local/share/nvim
rm -rf ~/.cache/nvim
nvim  # Will reinstall everything
```

### Aerospace not starting

```bash
# Reload configuration
aerospace reload

# Or restart
killall Aerospace
open -a Aerospace
```
