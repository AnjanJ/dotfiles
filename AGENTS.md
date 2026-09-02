# Working on this repo

Guidance for anyone changing the dotfiles source, human or agent. End-user help for *using* the setup lives in `agents/skills/dotfiles/` (installed to `~/.claude/skills/dotfiles`); reference docs live in `docs/`.

## Layout

| Path | What it is |
|------|------------|
| `install.sh`, `update.sh` | Bootstrap and upgrade. Both run under stock macOS bash 3.2 (curl bootstrap), so no `declare -A`, `mapfile`, `${var,,}`. |
| `scripts/symlink-map.sh` | The single list of managed symlinks. Install, update, sync, doctor, health, backup and uninstall all read it. Add a file here, nowhere else. |
| `scripts/apply-theme.sh`, `scripts/theme-render.sh` | Theme pipeline: `themes/<name>/colors.toml` rendered through `themes/_templates/*.tpl` into `~/.local/state/dotfiles/current/theme/`. |
| `bin/dotfiles` | CLI router. `dotfiles a b c` runs `bin/dotfiles-a-b-c`, else `bin/dotfiles-a-b`, else `bin/dotfiles-a`; `work-*` and `repos-clone` route under their own names. |
| `bin/dotfiles-*` | One command per file. |
| `migrations/<unix-ts>-<slug>.sh` | One-off, idempotent per-machine repairs run by sync/update. |
| `themes/` | `_templates/` plus one directory per theme. |
| `tests/test-*.sh` | One suite per area, run by GitHub Actions on macOS. |
| `docs/` | Reference for users. `docs/KEYBINDINGS.md` has a generated block. |

## Commands

- Every `bin/dotfiles-*` starts with `# dotfiles:summary=…` and, when it takes arguments, `# dotfiles:args=…` (bracket optional parts: `[--yes]`). `# dotfiles:hidden=true` keeps plumbing out of listings. `dotfiles commands --check` runs in CI and fails on a missing summary.
- Name commands `dotfiles-<group>-<verb>` so they route as `dotfiles <group> <verb>`. Existing groups: `add`, `work`, `repos`. Verbs in use: `sync`, `update`, `health`, `doctor`, `backup`, `theme`, `toggle`, `keys`, `hook`, `migrate`.
- `--help` is handled by the router from the header; a script's own `--help` is a bonus, not a requirement.
- Completions come from `dotfiles commands --plain`; do not add commands to `.zshrc-work-completions` by hand.

## Generated files: never edit these

- `~/.local/state/dotfiles/current/theme/*` — rendered by `dotfiles theme`.
- `.config/ghostty/theme.generated`, `.config/zellij/themes/dotfiles.kdl`, `.config/sketchybar/colors.sh`, `.config/borders/colors.sh` — gitignored copies of the above.
- The block between `<!-- AEROSPACE_KEYS_START -->` and `<!-- AEROSPACE_KEYS_END -->` in `docs/KEYBINDINGS.md` — run `dotfiles keys --update` after changing `aerospace.toml`.
- `docs/PACKAGE_CATALOG.md` — built by `scripts/catalog/build-catalog.py` from the Brewfile.

Colours belong in `themes/<name>/colors.toml`; app configs reference the rendered files. If an app needs a colour, add a token to its template in `themes/_templates/`, never a hex value in the tracked config.

## Changing things safely

- **New managed file:** add one line to `scripts/symlink-map.sh`.
- **New theme:** `dotfiles add-theme <name>`, fill `colors.toml` and `theme.conf`, add the nvim plugin spec. See `docs/THEMES.md`.
- **New app to theme:** add `themes/_templates/<output>.tpl`, then make the app read `~/.local/state/dotfiles/current/theme/<output>` (or add an `_install_rendered` line in `apply-theme.sh` for apps that need a copy). Add the file to the Theme Assets section of `scripts/health-check.sh`.
- **Change that other machines must apply** (moved symlink, removed generated file, renamed state): `dotfiles migrate --new <slug>`, write an idempotent script. Never rely on a human running a one-off command.
- **Keybinding:** edit `.config/aerospace/aerospace.toml`, put a `# desc:` comment on the line above when the command alone does not explain it, run `dotfiles keys --update`.
- **Feature that should be switchable:** consult `dotfiles-toggle --enabled <flag>` in the script; document the flag in `bin/dotfiles-toggle`'s header.
- Configs are symlinked into `$HOME`, so an edit takes effect on the live machine immediately. Validate before moving on: `ghostty +validate-config`, `zellij setup --check`, `aerospace reload-config`, `sketchybar --reload`, `nvim --headless +qa`.

## Style

- `#!/usr/bin/env bash`, `set -euo pipefail` in commands (not in sourced libraries).
- `[[ ]]` for tests, `$(( ))` for arithmetic, `local` in functions, quote every expansion.
- Increment with `VAR=$((VAR + 1))`, not `((VAR++))` (returns 1 at zero under `set -e`).
- Prefer explaining *why* in a comment over restating *what* the code does.
- shellcheck must pass with the CI flags: `-x -e SC2162,SC1091,SC2088,SC2317`. Disable a rule inline only with a reason.
- Markdown docs: full lines, no hard wrap.

## Tests

- Suites live in `tests/test-<area>.sh`, use a temporary `HOME` and a mock `DOTFILES_DIR`, and never touch real configs. Run one with `/opt/homebrew/bin/bash tests/test-<area>.sh`; run them all as CI does in `.github/workflows/test.yml`.
- Scripts on the install path must also pass `/bin/bash -n` and, where a suite covers them, run under `/bin/bash` 3.2 (`test-packages`, `test-theme-render`, `test-cli`, `test-toggle`, `test-keys` do this).
- A new suite goes into the CI matrix and the counts in `README.md`, `docs/STRUCTURE.md`, `docs/MAINTENANCE.md`.

## Commits

Atomic commits, imperative subject with a type prefix (`feat`, `fix`, `docs`, `test`, `chore`), body with what/why/how and an honest test plan. `update.sh` commits `snapshot: system state` on main when Brewfile or mise config change; `dotfiles toggle auto-commit off` stops that.
