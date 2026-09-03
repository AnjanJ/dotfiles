# The `dotfiles` CLI, toggles, hooks, migrations

## Everyday

| Command | Does | Safe to run unasked |
|---------|------|---------------------|
| `dotfiles health` | 130+ read-only checks: tools, symlinks, runtimes, services, theme assets, pending migrations | yes |
| `dotfiles sync` | `git pull`, relink from the symlink map, run pending migrations, re-render the theme, fire `post-sync` hooks | yes |
| `dotfiles doctor [--dry-run]` | fix broken symlinks, `~/.ssh` permissions, missing mise runtimes | `--dry-run` yes; fixing: ask |
| `dotfiles theme <name>` | switch theme (see `theming.md`) | yes, when asked to change the theme |
| `dotfiles keys [--update]` | keybinding cheatsheet; `--update` regenerates the doc | yes |
| `dotfiles toggle <flag> [on\|off]` | flip `startup-apps`, `borders`, `auto-commit` (or any name) | yes, when asked |
| `dotfiles migrate [--pending]` | run one-off repairs shipped with the repo | yes |
| `dotfiles backup [--list\|--restore <n>]` | snapshot every managed file to `~/.dotfiles-backups` | creating: yes; restoring: ask |
| `dotfiles update` | upgrade Homebrew, mise, relink, **commit and push** Brewfile changes to GitHub; `--yes` never prompts; transcript in `~/.local/state/dotfiles/update.log` | **ask first** |
| `dotfiles webapp install <name> <url> [--workspace N] [--float]` | Chrome `--app` launcher in `~/Applications` plus an AeroSpace rule between the `DOTFILES_LAUNCHERS` markers in `aerospace.toml`; `dotfiles webapp remove <name>` undoes it | safe |
| `dotfiles tui install <name> <cmd> [--workspace N] [--tile]` | Ghostty launcher for a terminal program, floats by default; `dotfiles tui remove <name>` undoes it | safe |
| `dotfiles restart <aerospace\|sketchybar\|borders>` | reload/relaunch one component now; `--later <c>` marks it for the end of the next update or sync; `--pending` consumes markers | safe |
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

`dotfiles toggle --list` shows state; scripts check `dotfiles-toggle --enabled <flag>`.

## Hooks

User scripts that run on events, outside the repo so updates never touch them:

```
~/.config/dotfiles/hooks/theme-set.d/*      after `dotfiles theme` ($1 = theme name)
~/.config/dotfiles/hooks/post-sync.d/*      after `dotfiles sync`
~/.config/dotfiles/hooks/post-update.d/*    after `dotfiles update`
```

A single file `~/.config/dotfiles/hooks/<event>` also works. Failing hooks are reported and do not stop the caller. Use hooks for wallpaper changes, pushing the Slack colour string to the clipboard, restarting an app, anything the repo does not automate.

## Migrations

`migrations/<unix-ts>-<slug>.sh` in the repo are one-off repairs (a symlink that moved, a generated file that changed location). `dotfiles sync` and `dotfiles update` run pending ones; `dotfiles health` warns if any are pending; `dotfiles migrate --pending` lists them. Do not write migrations for end-user changes; they are for repo changes that every machine must apply.

## Diagnosing problems

1. `dotfiles health` — read the ✗ lines.
2. `dotfiles doctor --dry-run` — see what it would fix, then run it without the flag if that is what the user wants.
3. `dotfiles migrate --pending` — a pending migration means the repo moved ahead of this machine.
4. Theme looks wrong: `dotfiles theme "$(cat ~/.dotfiles-theme)"` re-renders; `theming.md` explains what reads what.
5. A symlink points somewhere odd: check `scripts/symlink-map.sh` in the repo; `dotfiles sync` relinks.
6. Shell slow: `dotfiles profile --detailed`.

Stale-state cleanup that is always safe: `rm -rf ~/.local/state/dotfiles/current/next-theme`.
