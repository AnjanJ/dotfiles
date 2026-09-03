# The `dotfiles` CLI, toggles, hooks, migrations

## Everyday

| Command | Does | Safe to run unasked |
|---------|------|---------------------|
| `dotfiles debug --print` | one read-only report: versions, repo revision and dirt, theme, toggles, pending migrations/restarts/updates, every managed link's state, the full health check, the last update transcript. **Run this first when something is wrong.** Without `--print` it writes `~/.local/state/dotfiles/debug.log` and copies it to the clipboard | yes |
| `dotfiles health` | 130+ read-only checks: tools, symlinks, runtimes, services, theme assets, pending migrations | yes |
| `dotfiles sync` | `git pull`, relink from the symlink map, run pending migrations, re-render the theme, fire `post-sync` hooks | yes |
| `dotfiles doctor [--dry-run]` | fix broken symlinks, `~/.ssh` permissions, missing mise runtimes | `--dry-run` yes; fixing: ask |
| `dotfiles theme <name>` | switch theme (see `theming.md`) | yes, when asked to change the theme |
| `dotfiles theme install <git-url>` / `dotfiles theme remove <name>` | clone a palette-first theme into `~/.config/dotfiles/themes/<name>/` and apply it; only its colour data is staged (see `theming.md`) | ask (it applies the theme) |
| `dotfiles theme update [name] [--no-apply]` | fast-forward every cloned theme under `~/.config/dotfiles/themes/` (or one) and re-apply the active one if it moved | yes |
| `dotfiles theme preview [name\|colors.toml] [--no-color]` | palette swatches in the terminal, also the fzf preview in `dotfiles menu theme` | yes |
| `dotfiles theme bg next\|set <img>\|list\|current` | desktop picture for the active theme: cycles `themes/<name>/backgrounds/`, `~/.config/dotfiles/backgrounds/<name>/`, then the gradient generated from the palette | yes, when asked |
| `dotfiles menu [route] [--list\|--run <label>]` | fzf tree over every verb (theme, toggles, launchers, reminder, update, all commands); `--list` prints `label<TAB>command` rows, Ctrl+Shift+Space opens it in Ghostty | `--list` yes; running rows: as the row's command |
| `dotfiles reminder <min> [msg]\|show\|clear` | macOS notification in N minutes via a self-removing launchd agent | yes |
| `dotfiles keys [--update]` | keybinding cheatsheet; `--update` regenerates the doc | yes |
| `dotfiles toggle <flag> [on\|off]` | flip `startup-apps`, `borders`, `auto-commit`, `appearance`, `background`, `update-notice` (or any name) | yes, when asked |
| `dotfiles migrate [--pending]` | run one-off repairs shipped with the repo | yes |
| `dotfiles backup [--list\|--restore <n>]` | snapshot every managed file to `~/.dotfiles-backups` | creating: yes; restoring: ask |
| `dotfiles update` | upgrade Homebrew, mise, relink, **commit and push** Brewfile changes to GitHub; `--yes` never prompts; transcript in `~/.local/state/dotfiles/update.log` | **ask first** |
| `dotfiles update available [--cached\|--short]` | what is waiting: commits behind origin, outdated brew packages, pending migrations, restart markers; `--cached` reads the last result without a fetch; exit 1 means nothing is waiting | yes |
| `dotfiles webapp install <name> <url> [--workspace N] [--float]` | Chrome `--app` launcher in `~/Applications` plus an AeroSpace rule between the `DOTFILES_LAUNCHERS` markers in `aerospace.toml`; `dotfiles webapp remove <name>` undoes it | safe |
| `dotfiles tui install <name> <cmd> [--workspace N] [--tile]` | Ghostty launcher for a terminal program, floats by default; `dotfiles tui remove <name>` undoes it | safe |
| `dotfiles restart <aerospace\|sketchybar\|borders>` | reload/relaunch one component now; `--later <c>` marks it for the end of the next update or sync; `--pending` consumes markers | safe |
| `dotfiles export [--json]` | portable summary of this machine's setup (tools, runtimes, theme) for reproducing it elsewhere | yes |
| `dotfiles default agent [name] [--command]` | show or set which CLI the `a` shell function launches | showing: yes; setting: when asked |
| `dotfiles hook <event> [args]` / `--list` / `--seed` | run the user's hooks for an event by hand; list what is installed; copy the repo's sample hooks into place (see Hooks below) | yes |
| `dotfiles hook install <event> <file>` | copy a script into `~/.config/dotfiles/hooks/<event>.d/` and make it executable | when asked |
| `dotfiles cleanup [--force]` | remove Homebrew packages that are not in the Brewfile | **ask first** |
| `dotfiles install` | full installer (idempotent, but slow and sudo) | **ask first** |
| `dotfiles uninstall` | remove every managed symlink | **ask first** |
| `dotfiles work setup\|status\|nuke\|switch` | work git identity, SSH hosts, repos | `status` yes; others ask |
| `dotfiles repos clone` | clone repos from GitHub/GitLab/Bitbucket/Codeberg | ask |

`dotfiles` alone lists everything with a summary; `dotfiles <cmd> --help` shows usage; `dotfiles commands --json` is machine-readable. `dotfiles a b c` runs `bin/dotfiles-a-b-c` (or the longest matching prefix), so `dotfiles add theme x` and `dotfiles add-theme x` are the same.

## Toggles

Flag files under `~/.local/state/dotfiles/toggles/<flag>.off`; everything is on by default and survives updates.

- `startup-apps` — the login session restore (`startup-apps.sh`)
- `borders` — launching JankyBorders from AeroSpace
- `auto-commit` — `dotfiles update` committing and pushing `snapshot: system state`
- `appearance` — `dotfiles theme` switching macOS light/dark to match the theme
- `background` — `dotfiles theme` setting the desktop picture
- `update-notice` — the one-line "updates waiting" notice at shell login

`dotfiles toggle --list` shows state; scripts check `dotfiles-toggle --enabled <flag>`.

## Hooks

User scripts that run on events, outside the repo so updates never touch them:

```
~/.config/dotfiles/hooks/theme-set.d/*      after `dotfiles theme` ($1 = theme name)
~/.config/dotfiles/hooks/post-sync.d/*      after `dotfiles sync`
~/.config/dotfiles/hooks/post-update.d/*    after `dotfiles update`
~/.config/dotfiles/hooks/post-install.d/*   once, at the end of install.sh
```

`dotfiles hook --list` shows what is installed per event; `dotfiles hook install <event> <file>` copies a script in and makes it executable. Each event directory holds a `*.sample` from the repo's `hooks/` (seeded by install and doctor, inert until renamed without `.sample`).

A single file `~/.config/dotfiles/hooks/<event>` also works. Failing hooks are reported and do not stop the caller. Use hooks for wallpaper changes, pushing the Slack colour string to the clipboard, restarting an app, anything the repo does not automate.

## Migrations

`migrations/<unix-ts>-<slug>.sh` in the repo are one-off repairs (a symlink that moved, a generated file that changed location). `dotfiles sync` and `dotfiles update` run pending ones; `dotfiles health` warns if any are pending; `dotfiles migrate --pending` lists them. Do not write migrations for end-user changes; they are for repo changes that every machine must apply.

## Diagnosing problems

0. `dotfiles debug --print` — everything below in one report; read it before poking at files.
1. `dotfiles health` — read the ✗ lines.
2. `dotfiles doctor --dry-run` — see what it would fix, then run it without the flag if that is what the user wants.
3. `dotfiles update available` — commits behind origin, outdated packages, pending migrations and restarts in one place; a pending migration means the repo moved ahead of this machine.
4. Theme looks wrong: `dotfiles theme "$(cat ~/.dotfiles-theme)"` re-renders; `theming.md` explains what reads what.
5. A symlink points somewhere odd: check `scripts/symlink-map.sh` in the repo; `dotfiles sync` relinks.
6. Shell slow: `dotfiles profile --detailed`.

Stale-state cleanup that is always safe: `rm -rf ~/.local/state/dotfiles/current/next-theme`.
