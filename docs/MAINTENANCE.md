# Maintenance

All commands work from anywhere — no need to `cd ~/dotfiles` first.

## Dotfiles CLI

```bash
dotfiles update       # Upgrade system & sync repo (pull → brew upgrade → snapshot → push)
dotfiles sync         # Quick refresh: pull, relink, reapply theme (no upgrades)
dotfiles health       # Verify all tools are installed and configured
dotfiles theme aura   # Switch theme (tokyo-night | aura | catppuccin | catppuccin-latte | flexoki-light)
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

**Menu rows** of your own live in `~/.config/dotfiles/menu.d/*.tsv`, one `label<TAB>command` per line: an un-nested label joins the root of `dotfiles menu`, `Personal/Notes` appears under a `Personal ▸` submenu (`dotfiles menu personal`), and a label equal to a built-in row replaces that row's command.

**Hooks** let you attach your own scripts to events without editing the repo. Put executable scripts in `~/.config/dotfiles/hooks/<event>.d/` (or a single `~/.config/dotfiles/hooks/<event>` file). Events: `theme-set <theme>` after a theme switch, `post-sync`, `post-update`, `post-install` (once, at the end of `install.sh`), `font-set <family>` after `dotfiles font set`. A failing hook is reported and never stops the caller. The repo's `hooks/<event>.d/*.sample` files are seeded into that directory by install and doctor and stay inert until renamed without `.sample`; `dotfiles hook --list` shows what is installed and `dotfiles hook install <event> <file>` adds your own.

## Unattended installs

`install.sh` never has to prompt. Flags cover every choice, `DOTFILES_*` environment variables mirror them, and a JSON answers file mirrors both: `install.sh --answers <file>`, `DOTFILES_ANSWERS=<file>`, or simply `~/.dotfiles-answers.json` when it exists. Keys are `name`, `email`, `work_email`, `work_dir`, `theme`, `ssh`, `groups` (an array or a comma string), `macos_defaults` and `runtimes` (booleans); `docs/dotfiles-answers.example.json` is a template. Precedence is flags, then environment, then the file, then defaults, so a file can hold the machine's standing choices while a flag overrides one of them for a run. A named file that is missing or invalid stops the install rather than falling back to prompts or defaults, and unknown keys are warned about (typos). The file is read with `plutil` (python3 when plutil cannot), so nothing has to be installed first.

## Testing

Every push and PR runs 33 test suites, an end-to-end install, shellcheck, `dotfiles commands --check`, `dotfiles keys --check` and `dotfiles keys --lint` via GitHub Actions. The suites are discovered from `tests/*-test.sh`, so a new file is in CI the moment it exists:

- **Shellcheck** — lints all shell scripts
- **Idempotency** (`idempotency`) — install/setup can run repeatedly with identical results (sandboxed)
- **Work identity** (`work-nuke`) — setup, nuke and switch lifecycle
- **Work status** (`work-status`) — status diagnostics for the work identity
- **Shell helpers** (`shell`) — the zsh functions in `.zshrc-terminal-enhancements` run under zsh: `gwa`/`gwr` worktrees against a temp repo with a mise stub, `compress`/`decompress` round trip, `fip`/`dip`/`lip` against ssh/pkill/pgrep stubs, usage errors
- **SSH config** (`ssh-adversarial`) — adversarial inputs and edge cases
- **Repo cloner** (`repos-clone`) — SSH alias detection and URL rewriting
- **Update available** (`update-available`) — `dotfiles update available`: behind-origin count against a local bare origin, brew outdated via a stub, migrations and restart markers, the cache file, `--cached`, `--short`, `--quiet`, exit codes, a fetch that cannot reach origin
- **Update flow** (`update`) — symlink creation and refresh, plus the whole pipeline against stubs: lock, transcript, snapshot before upgrade, restart markers, `--yes`
- **Restart** (`restart`) — `dotfiles restart` now/later/pending/list, the AeroSpace process-name case, borders relaunch honouring its toggle
- **Web apps** (`webapp`) — `dotfiles webapp install/remove`: bundle, plist, icon conversion, AeroSpace rule placement and removal, URL and name validation
- **TUIs** (`tui`) — `dotfiles tui install/remove`: Ghostty launch line, default float, Ghostty icon fallback, rule lifecycle
- **Theme system** (`theme`) — render, overrides, atomic swap, render lock, palette preview, failure leaves previous theme, editor settings generated from `settings.base.json` with in-app edits adopted, scaffolding, light-theme mode outputs and the macOS appearance switch
- **Theme backgrounds** (`theme-bg`) — generated palette gradient, candidate order and cycling, `dotfiles theme bg` verbs, desktoppr/osascript setters, the toggle, set-on-switch-only from apply-theme
- **Reminder** (`reminder`) — `dotfiles reminder`: the launchd agent plist, scheduling via a launchctl stub, show/clear, the `--fire` path (notification, self-removal, unload), validation
- **Menu** (`menu`) — `dotfiles menu`: rows per route, active theme and toggle state, launcher rows from installed bundles, user rows from `menu.d/*.tsv` (root rows, nested submenus, overrides, malformed lines), the commands route, `--run`, prompt rows, the numbered fallback picker
- **Font** (`font`) — `dotfiles font`: current/default, list via a fontconfig stub, set with verification, the state file, the re-render carrying `{{ font_family }}` into Ghostty, WezTerm, Zed and VS Code, the `font-set` hook, reset, `/bin/bash` 3.2
- **Hooks** (`hook`) — sample hooks per event, `--seed` never overwriting, samples inert, `--list`, `dotfiles hook install`, every fired event known and sampled, `/bin/bash` 3.2
- **Install answers** (`install-answers`) — `scripts/install-answers.sh`: every key, flag/env precedence, arrays and booleans, unknown-key warnings, missing and invalid files, install.sh's `--answers` / `DOTFILES_ANSWERS` / `~/.dotfiles-answers.json` handling
- **Theme install** (`theme-install`) — `dotfiles theme install/remove/update` against a local git "remote": URL and name validation, the user themes dir, staging only colour data from a cloned theme (dropped code and symlinks named, theme.conf parsed not sourced, nvim fallback), hand-written user themes trusted, reinstall, palette-only repos
- **Theme renderer** (`theme-render`) — token forms, colour maths, derived keys, error exits
- **CLI router** (`cli`) — route resolution, `--help` never executes, required-arg guard, metadata lint, JSON
- **Toggles** (`toggle`) — flag files, `--enabled` exit codes, listing
- **Keys** (`keys`) — aerospace.toml parsing, `# desc:` overrides, markdown, `--update`/`--check`, `--lint` (duplicate chords across modifier order, undescribed bindings, missing scripts) and the real config lints clean
- **Agent** (`agent`) — default-agent state, launch commands, skill files present
- **Debug** (`debug`) — `dotfiles debug`: every section of the report, link states, the written file and clipboard copy, `--print`, `--no-copy`
- **Doctor** (`doctor`) — auto-fix symlinks, permissions, dry-run mode
- **Git setup** (`setup-git`) — identity configuration, work/personal split, smart defaults
- **Backup** (`backup`) — create, list, restore, prune cycle
- **Sync** (`sync`) — symlink refresh, broken link repair, dry-run mode
- **Packages** (`packages`) — Brewfile group parsing, filtering, saved selections
- **Uninstall** (`uninstall`) — removes every mapped symlink, leaves foreign links alone
- **Style** (`style`) — the AGENTS.md rules shellcheck cannot express: shebang and strict mode, no `((VAR++))`, bash 3.2 builtins only on the install path, osascript never aimed at an app outside the watchdogged helpers
- **Docs** (`docs`) — suite counts in README/STRUCTURE/MAINTENANCE, this list, the THEMES.md app table, the skill's command table, toggles and hook events, all derived from the code
- **End-to-end install** (`tests/e2e/install-e2e.sh`) — the real `install.sh` under `/bin/bash` 3.2 into a fresh `HOME` with `--groups core`: every mapped symlink, rendered theme, core formulae, a clean interactive zsh, and an idempotent second run

Every suite sources `tests/base-test.sh`: it gets a fresh temporary `HOME`, TAP `ok`/`not ok` output, and `fail` ends the file at the first broken assertion while `tests/run` continues with the next file. Run locally (needs bash 4+, i.e. `brew install bash` — macOS ships 3.2):

```bash
/opt/homebrew/bin/bash tests/run                # every suite
/opt/homebrew/bin/bash tests/run theme keys     # just these
/bin/bash tests/e2e/install-e2e.sh              # the real install from a copy of the checkout, minutes
```

## Web apps and TUI launchers

`dotfiles webapp install <name> <url> [--workspace N] [--float] [--title-regex R] [--icon <url|path>]` turns a site into `~/Applications/<name>.app`: a two-line bundle that runs `open -na "Google Chrome" --args --app=<url>`, with the site's apple-touch-icon converted to `.icns` by `sips` and `iconutil`. Spotlight, Raycast and the Dock treat it as an app. With `--workspace` or `--float` the launch script places the window itself after `open`: it waits for a Chrome window that did not exist before the launch, prefers the one whose title matches the name (or `--title-regex`), and applies `aerospace layout floating` / `move-node-to-workspace` by window id. It also writes an `[[on-window-detected]]` rule with the same match, but that is only a fallback: AeroSpace evaluates it before Chrome has set the page title (a fresh `--app` window is titled by its URL host first), so the rule rarely fires for the first window.

`dotfiles tui install <name> <command> [--workspace N] [--tile] [--icon <url|path>]` does the same for a terminal program: the bundle runs `open -na Ghostty --args --title=<name> -e /bin/zsh -lic '<command>'`, so PATH, mise runtimes and aliases are all present. TUIs float by default and get Ghostty's icon unless you pass one.

Rules live between the `DOTFILES_LAUNCHERS_START/END` markers near the top of the rules section in `.config/aerospace/aerospace.toml`, ahead of the app-wide rules because AeroSpace applies only the first match. The file is tracked, so commit it to carry launchers to other machines; the bundles themselves are per machine (`dotfiles webapp remove --list` and `dotfiles tui remove --list` show what exists). `dotfiles webapp remove <name>` and `dotfiles tui remove <name>` delete the bundle and its rule; they only touch bundles carrying the `DotfilesLauncher` plist key.

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
