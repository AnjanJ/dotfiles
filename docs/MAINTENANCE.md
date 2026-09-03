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
dotfiles migrate      # Run pending one-off migrations (--pending, --dry-run, --new <slug>)
dotfiles hook <event> # Run ~/.config/dotfiles/hooks/<event>{,.d/*} (theme-set, post-sync, post-update)
dotfiles toggle <f>   # Flip a feature flag: startup-apps, borders, auto-commit (--list)
dotfiles keys         # AeroSpace keybinding cheatsheet (fzf; --markdown, --update, --check)
dotfiles commands     # List every command from its metadata (--json, --plain, --check)
dotfiles default-agent # Which agent the `a` shell function launches (claude|oclaude|gemini|copilot|llm)
dotfiles work setup   # work-* and repos-clone route here too: work status, work nuke, repos clone
dotfiles install      # Re-run full installer (idempotent)
dotfiles uninstall    # Remove all dotfiles symlinks
dotfiles edit         # Open dotfiles in your editor
dotfiles dir          # Print dotfiles directory path
```

There is no command table to maintain: every executable `bin/dotfiles-*` is a command and its filename is its route (`dotfiles add theme x` → `bin/dotfiles-add-theme x`). Each script declares `# dotfiles:summary=` and `# dotfiles:args=` in its header; `dotfiles <cmd> --help` prints them, a command with required args prints usage when called bare, and `dotfiles commands --check` fails CI if a script has no summary. Tab-completion reads the same metadata. Shorthand also works: `dotfiles-update`, `dotfiles-sync`, etc.

## What `dotfiles update` does

1. Pull latest changes from git. A pulled change under `.config/aerospace`, `.config/sketchybar` or `.config/borders` marks that component for a restart in step 6.
2. Take a local APFS snapshot with `tmutil localsnapshot` (`--no-snapshot` skips it), then `brew update` + `brew upgrade` + `brew cleanup`
3. Snapshot installed packages and show diff against Brewfile (without overwriting the organized Brewfile)
4. Refresh all symlinks (from `scripts/symlink-map.sh`) and run pending migrations
5. Upgrade mise tools
6. Restart only what was marked: `dotfiles restart --pending` reloads aerospace and sketchybar and relaunches borders, then clears the markers. Nothing marked, nothing restarted.
7. Commit & push changes back to repo

Around the whole run: a lock in `~/.local/state/dotfiles/update.lock` refuses a second concurrent update (a stale lock from a crashed run is removed automatically), and a transcript of everything printed lands in `~/.local/state/dotfiles/update.log` with the previous run kept as `update.log.1`. `dotfiles update --yes` is a promise not to prompt, for cron, ssh and CI; it also exports `DOTFILES_UPDATE_UNATTENDED=1` for hooks and migrations that ask questions of their own.

**Restart markers.** `dotfiles restart <aerospace|sketchybar|borders>` restarts a component now. `dotfiles restart --later <component>` drops `~/.local/state/dotfiles/restart-<component>-required` for `dotfiles update` and `dotfiles sync` to consume at their end; a migration that edits a live config should do this rather than restart mid-run. `dotfiles restart --list` shows what is pending and `dotfiles health` warns about it. Rolling back a bad upgrade: `tmutil listlocalsnapshots /` shows the snapshot the update took; mount it with `tmutil mount` or browse it in Time Machine.

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

Verifies: core tools, every managed symlink (swept from `scripts/symlink-map.sh` — a repo file that was never linked fails loudly), language runtimes, **project toolchain drift** (scans `~/code` and `~/work/code` for projects that pin a tool version which isn't installed, so they'd silently run on the global version — set `DOTFILES_CODE_DIRS` to change where it looks), running services (PostgreSQL, MySQL, Redis), shell integrations, and work identity.

## Re-run installation

The install script is idempotent — run it any number of times with identical results:

```bash
dotfiles install                    # Non-interactive, skips what's done
dotfiles install --interactive      # Prompt for every choice
dotfiles install --force            # Force reinstall everything
```

## Migrations and hooks

**Migrations** are one-off, idempotent repairs for changes a relink cannot express: a symlink that moved, a generated file that changed location, a stale config to remove. They live in `migrations/<unix-ts>-<slug>.sh`, run in order during `dotfiles sync` and `dotfiles update` with `DOTFILES_DIR` exported, and are marked done per machine in `~/.local/state/dotfiles/migrations/`. A failing migration stays pending and is retried next time; `dotfiles health` warns when any are pending. Create one with `dotfiles migrate --new <slug>`.

**Hooks** let you attach your own scripts to events without editing the repo. Put executable scripts in `~/.config/dotfiles/hooks/<event>.d/` (or a single `~/.config/dotfiles/hooks/<event>` file). Events: `theme-set <theme>` after a theme switch, `post-sync`, `post-update`. A failing hook is reported and never stops the caller.

## Testing

Every push and PR runs 19 test suites, an end-to-end install, shellcheck, `dotfiles commands --check` and `dotfiles keys --check` via GitHub Actions. The suites are discovered from `tests/*-test.sh`, so a new file is in CI the moment it exists:

- **Shellcheck** — lints all shell scripts
- **Idempotency** — install/setup can run repeatedly with identical results (sandboxed)
- **Work identity** — setup, nuke, switch lifecycle, and status diagnostics
- **SSH config** — adversarial inputs and edge cases
- **Repo cloner** — SSH alias detection and URL rewriting
- **Update flow** — symlink creation and refresh, plus the whole pipeline against stubs: lock, transcript, snapshot before upgrade, restart markers, `--yes`
- **Restart** — `dotfiles restart` now/later/pending/list, the AeroSpace process-name case, borders relaunch honouring its toggle
- **Theme system** — render, overrides, atomic swap, failure leaves previous theme, scaffolding
- **Theme renderer** — token forms, colour maths, derived keys, error exits
- **CLI router** — route resolution, `--help` never executes, required-arg guard, metadata lint, JSON
- **Toggles** — flag files, `--enabled` exit codes, listing
- **Keys** — aerospace.toml parsing, `# desc:` overrides, markdown, `--update`/`--check`
- **Agent** — default-agent state, launch commands, skill files present
- **Doctor** — auto-fix symlinks, permissions, dry-run mode
- **Git setup** — identity configuration, work/personal split, smart defaults
- **Backup** — create, list, restore, prune cycle
- **Sync** — symlink refresh, broken link repair, dry-run mode
- **Packages** — Brewfile group parsing, filtering, saved selections
- **Uninstall** — removes every mapped symlink, leaves foreign links alone
- **End-to-end install** (`tests/e2e/install-e2e.sh`) — the real `install.sh` under `/bin/bash` 3.2 into a fresh `HOME` with `--groups core`: every mapped symlink, rendered theme, core formulae, a clean interactive zsh, and an idempotent second run

Every suite sources `tests/base-test.sh`: it gets a fresh temporary `HOME`, TAP `ok`/`not ok` output, and `fail` ends the file at the first broken assertion while `tests/run` continues with the next file. Run locally (needs bash 4+, i.e. `brew install bash` — macOS ships 3.2):

```bash
/opt/homebrew/bin/bash tests/run                # every suite
/opt/homebrew/bin/bash tests/run theme keys     # just these
/bin/bash tests/e2e/install-e2e.sh              # the real install from a copy of the checkout, minutes
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
