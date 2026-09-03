# AJ's Dotfiles vs Omarchy Quattro

A side-by-side analysis of this repo against the `quattro` branch of Omarchy (the v4 line), with a concrete plan for what to borrow.

| | This repo | Omarchy `quattro` |
|---|---|---|
| Snapshot | `main`, 162 commits, last 2025-11-24 | `d3d23fd`, 2026-09-02, `version` = `4.0.0.alpha` |
| Target | macOS, Apple Silicon | Arch Linux + Hyprland (Intel Macs only) |
| Shape | Personal dotfiles, symlinked into `$HOME` | A distribution shipped as two pacman packages |
| Size | 183 files, ~8k lines of shell, 5k lines of tests | 1,766 files, 443 `omarchy-*` commands, 103 migrations, ~230 test files |
| Shell | zsh + starship + fzf-tab + atuin | bash + starship |
| Themes | 3, hand-written per-app files | 22, one `colors.toml` rendered through 17 templates |
| Tests | 12 macOS suites + shellcheck in GitHub Actions | `test/cli`, `test/shell` (~228 files), VM acceptance suite; no CI in repo |

The two projects solve different problems. Omarchy owns the whole machine from ISO to desktop shell. This repo layers a curated environment onto macOS. So the useful question is not "which is better" but "which *patterns* from Quattro would make this repo more robust, more extensible, and easier to hand to an AI agent". The answer is: theming architecture, CLI routing, migrations, hooks, and the test/docs discipline. Almost everything else is either not applicable to macOS or already done well here.

---

## 1. Where this repo is stronger

These are real advantages, not consolation prizes. Keep them.

1. **It runs on the hardware you own.** Quattro has no Apple Silicon story at all (`manual/44-mac-support.md` covers Intel T2 Macs only). Nothing in this report suggests switching platforms.
2. **One-command curl bootstrap with flags and env vars.** Quattro v4 has no `install.sh`; installation is ISO plus `omarchy-apply-system` in a chroot. Your `install.sh:146-166` flag surface (`--name`, `--email`, `--theme`, `--ssh`, `--groups`, `--interactive`) is closer to Omarchy's *unattended install* answers file than Omarchy's own default path.
3. **Explicit symlink map as single source of truth.** `scripts/symlink-map.sh` is read by install, update, sync, doctor and health. Omarchy has no equivalent; it copies `config/**` into `/etc/skel` and then into `$HOME`, and drift is repaired by migrations and `omarchy-refresh-config`. Symlinks are the right call for a personal repo where you edit configs live.
4. **Health check and doctor.** `scripts/health-check.sh` (12 sections, including project toolchain drift across `~/code` via `mise ls --missing`) and `bin/dotfiles-doctor` (symlink repair, SSH permissions, missing runtimes) have no Omarchy counterpart. Omarchy has `omarchy debug` for bug reports, not a self-healing pass.
5. **Work/personal identity tooling.** `work-setup`, `work-nuke`, `work-status`, `work-switch`, `repos-clone` across GitHub, GitLab, Bitbucket and Codeberg, gitconfig `includeIf`, marker-delimited SSH blocks. Omarchy ships a single `config/git` and nothing for multi-identity.
6. **SSH via 1Password agent, adversarially tested.** `scripts/setup-ssh.sh` plus `tests/test-ssh-adversarial.sh`. Omarchy sets up sshd and FIDO2 but does not manage client keys.
7. **Rails and Phoenix depth.** ~1,000 lines of aliases and functions in `.zshrc-dhh-additions` and `.zshrc-elixir-additions`, Zellij layouts per stack, 24 Zed tasks, nvim rails/elixir plugin sets. Omarchy's dev story is `omarchy install dev-env ruby` (mise + the `rails` gem) and an `r` alias.
8. **CI that actually runs.** GitHub Actions with shellcheck and 12 suites on `macos-latest`. Omarchy's tests are richer but the clone has no `.github/workflows`; they run locally and in a VM.
9. **Package catalog generation** (`scripts/catalog/build-catalog.py` → `docs/PACKAGE_CATALOG.md`) and Brewfile groups with an interactive picker. Omarchy's package lists are two flat files consumed by the ISO builder.
10. **A modern interactive shell.** zsh with fzf-tab, autosuggestions, syntax highlighting, atuin, zoxide, and `dotfiles profile` for startup timing. Omarchy is deliberately plain bash.

## 2. Where Quattro is stronger

### 2.1 Theming: palette-first, template-rendered, atomically staged

This is the biggest gap and the most valuable thing to copy.

**Omarchy.** A theme is a `colors.toml` with 31 semantic keys (`accent`, `selection`, `muted`, four background stops, four foreground stops, 8 named + 6 bright colours; see `themes/tokyo-night/colors.toml`). `omarchy-theme-set` (`bin/omarchy-theme-set`, 346 lines) takes a `flock`, builds a staging dir at `~/.local/state/omarchy/current/next-theme`, overlays `~/.config/omarchy/themes/<name>/`, renders `default/themed/*.tpl` (17 templates: alacritty, btop, chromium, **claude.json**, foot, ghostty, gum, helix, hyprland, keyboard RGB, kitty, neovim, obsidian, pi, shell, vscode) with `{{ key }}`, `{{ key_rgb }}` and `{{ mix a b 15% }}` substitutions, then `mv`s the staged dir into place and fans out a *parallel* retint of running apps. Hand-written files in the theme dir win over templates. Users can add their own templates in `~/.config/omarchy/themed/`. Themes install from a git URL with a code denylist (`*.lua`, terminal configs that can name a `command`, `vscode.json`, symlinks) because those can execute code (`docs/theming.md`, "What an installed theme may not ship"). The renderer is 404 lines of bash + awk (`bin/omarchy-theme-set-templates`) with no exotic dependencies.

**This repo.** A theme is a `theme.conf` of ~17 variables plus a hand-made file per app (Aura ships 15). `scripts/apply-theme.sh` does pre-flight checks and a `trap ERR` rollback for four mandatory sections, then drops the trap and best-efforts the other twelve. It edits tracked files in place with `sed` between sentinel markers (ghostty, starship, lazygit, sketchybarrc, bordersrc, astroui.lua, zed settings, `.gitconfig` via delta), so every theme switch dirties the repo and `update.sh` later commits it as `snapshot: system state` (25 of 162 commits). `dotfiles-add-theme` scaffolds a directory but `apply-theme.sh:238` and `:180-182` hard-code the three known nvim theme filenames, so a fourth theme is not fully wired. WezTerm's palette is hard-coded in `wezterm.lua:28-59` and not themed at all.

**Why it matters.** Omarchy's `colors.toml` schema is small and stable, and the 22 bundled palettes are MIT licensed. Adopting the same schema means you can vendor those files and get 22 themes for free, then let templates produce every macOS-side config from them.

### 2.2 CLI: filename is the route, metadata is the help

`bin/omarchy` (1,092 lines) turns `omarchy theme set foo` into `exec omarchy-theme-set foo` by probing filenames longest-prefix first; there is no registry to maintain (`docs/cli-router.md`). Each command declares itself in a comment header (`# omarchy:summary=`, `# omarchy:args=`, `# omarchy:hidden=true`, `# omarchy:requires-sudo=true`). The router intercepts `--help` anywhere, refuses to run a command with required args when none are given, offers `omarchy commands --json` for agents, and `omarchy commands --check` lints every binary for a summary header. Prefixes encode intent: `refresh-` copies defaults back, `restart-` bounces a component, `toggle-` flips a flag file, `hw-` is a predicate, `install-`/`remove-` are pairs, `setup-` are wizards.

This repo has a 14-entry `case` in `bin/dotfiles`, separate `work-*` and `repos-clone` scripts outside that namespace, and a hand-maintained zsh completion (`.zshrc-work-completions`) that already omits `add-theme` and `cleanup`.

### 2.3 Config layering, refresh, and migrations

Omarchy separates the package tree (`/usr/share/omarchy`, read-only) from the user's `~/.config`. `omarchy-refresh-config <path>` copies a default back over the user file with a timestamped `.bak` and a diff. Changes that need to touch every existing machine ship as `migrations/<unix-ts>.sh`, run per-user by `omarchy-migrate` with markers in `~/.local/state/omarchy/migrations/`, idempotent, and surfaced at login when pending. There are 103 of them on the branch. `omarchy update` wraps everything in a lock, a `script` transcript, a snapper snapshot, and restart markers.

This repo has no migration concept. When the symlink map changes, a theme file is renamed, or a mise tool is added, a second machine only picks it up if `sync`/`doctor` happen to cover that case. It also has no "reset this config to default" verb because the symlink *is* the default.

### 2.4 Hooks and toggles

`bin/omarchy-hook` is 28 lines: run `~/.config/omarchy/hooks/<name>` then every file in `<name>.d/`. Events: `theme-set`, `post-update`, `post-boot`, `font-set`, `battery-low`, `pre-refresh-pacman`. `bin/omarchy-toggle` is a flag file under `~/.local/state/omarchy/toggles/`. Both are trivially portable and give users (and agents) an extension point without editing the repo.

### 2.5 Tests and docs discipline

Omarchy's `docs/testing.md` defines a contract: every `test/shell.d/<area>-test.sh` sources `base-test.sh`, emits TAP `ok`/`not ok`, exits on first failure per file, and the runner keeps going across files. Compositor-dependent tests skip cleanly. A CLI suite lints metadata on every binary. Documentation is split by audience: `manual/` (51 end-user pages), `docs/` (9 internals pages), `agents/skills/` (7 task guides for contributors) plus `AGENTS.md` with an explicit bash style guide (`[[ ]]`, `(( ))`, `#!/bin/bash`).

This repo's tests are solid (12 suites, temp `HOME`, hand-rolled asserts) but nothing exercises `install.sh` end to end, `health-check.sh`, `export`, `profile`, `cleanup`, `uninstall`, or the optional theme sections. More importantly the docs have drifted from the code:

- `docs/KEYBINDINGS.md:26-41` and `QUICK_REFERENCE.md:47-50` describe a Ctrl+Shift+C/W/F/G/O/P scheme that no longer matches `aerospace.toml` (W is Warp, X is Zen, C is Chrome, Z is Zed, O is Obsidian; F and G are unbound).
- `docs/THEMES.md:9` lists yazi and gitui as auto-themed; they were dropped. Xcode, Sublime and lsd are themed but unlisted.
- README and STRUCTURE say Ruby is pinned; `.config/mise/config.toml:7` says `latest`.
- README says 11 test suites; CI runs 12.

### 2.6 AI integration

Omarchy treats agents as first-class users of the system. A skill (`default/agents/skills/omarchy/SKILL.md` plus `hyprland.md`, `plugins.md`, `theming.md`, `hooks.md`, `capture.md`) is symlinked into `~/.claude/skills`, `~/.codex/skills`, `~/.pi/agent/skills`, `~/.gemini/config/skills` and `~/.hermes/skills` by `omarchy-provision-user`, telling every agent what is safe to edit, which commands exist, and to run `omarchy debug --no-sudo --print`. `omarchy default agent <name>` abstracts which CLI `a` launches; `omarchy agent prompt` runs it; a bar widget tracks Claude/Codex/Fireworks usage; a coredump watcher hands crashes to the agent with a `diagnose-crash` skill; and a `claude.json.tpl` renders the active palette into `~/.claude/themes/omarchy.json` which Claude Code hot-reloads. Agent CLIs are lazy mise stubs. Shell aliases use scoped permission modes (`cx` = `claude --permission-mode auto`).

This repo symlinks `~/.claude/settings.json`, has `oclaude` and `oq` helpers, `explain-last`, and an `llm`/Ollama default model. There is no repo skill for agents, `oclaude` always passes `--dangerously-skip-permissions`, and the referenced `~/.claude/statusline-command.sh` is not in the repo.

### 2.7 Desktop UX conventions

Omarchy's `Super`-based scheme is consistent and discoverable: `Super+K` opens a generated keybinding cheatsheet, `Super+Space` a menu where every row is a shell command and the menu itself is scriptable (`omarchy menu summon style.theme`). Every toggle exists as hotkey, menu row, and CLI verb. Web apps become `.desktop` launchers via `chromium --app=`; any TUI becomes a launcher entry. Reminders are `systemd-run --on-active` timers.

Your AeroSpace config is well organised (12 workspaces, app-to-workspace rules with rationale, service mode, monitor moves) but discovery relies on docs that are out of date.

### 2.8 Security defaults

Not directly transferable, but the posture is worth noting: user not in the docker group, sshd off until explicitly set up, timed passwordless sudo, installed themes and plugins treated as untrusted, notification exec uses argv rather than a shell string. The one transferable point is the last: any future "install theme from URL" feature here should adopt the same denylist since nvim Lua and ghostty `command` lines execute.

---

## 3. What to borrow, in priority order

### Tier 1: fix and polish (days, no architecture change)

> **Status: done (2026-09-03).** All nine items below are applied; a 13th CI suite (`tests/test-uninstall.sh`) covers the map-driven uninstall.

1. **Regenerate the drifted docs.** Fix `docs/KEYBINDINGS.md`, `QUICK_REFERENCE.md`, `docs/THEMES.md`, the "Ruby pinned" claim, and the suite count. Better: generate `KEYBINDINGS.md` from `aerospace.toml` (see Tier 2, item 7) so it cannot drift again.
2. **Make every consumer read the symlink map.** `bin/dotfiles-uninstall:66-72,119-146` and `bin/dotfiles-backup:136-157` carry hard-coded lists that miss `.gitconfig`, `.rubocop.yml`, `~/.wezterm.lua`, lazygit, borders, sketchybar, VS Code, Claude and llm links. Replace with `dotfiles_for_each_link`.
3. **Fix the bash 3.2 bootstrap hazard.** `scripts/package-utils.sh` and `bin/work-setup:175` use `declare -A`. `bash <(curl …)` runs `/bin/bash` 3.2 on a fresh Mac. Either install Homebrew bash before the package phase and re-exec, or drop associative arrays from the install path.
4. **Remove `brew bundle install --no-lock`** in `update.sh:182-188`; the flag no longer exists.
5. **Finish `add-theme` wiring.** In `apply-theme.sh` glob `~/.config/nvim/lua/plugins/*-theme.lua` instead of listing three names; build the rollback list from the map plus the glob.
6. **Extend shellcheck** to `.config/aerospace/scripts/*.sh`, `.config/sketchybar/**/*.sh`, `sketchybarrc`, `bordersrc`, `bin/rubocop-auto`. `cycle-app-windows.sh:43` has an unquoted array expansion.
7. **Honour "fully non-interactive".** `install.sh:295-298` still prompts for a theme when none is saved. Default to `tokyo-night` unless `--interactive`. Warn on unknown flags at `install.sh:164` instead of silently shifting.
8. **Reconcile defaults.** `EDITOR` (`zed --wait`) vs `.gitconfig` `editor = vim` vs lazygit `nvim`; `WORK_DIR` `~/work/code` vs setup-git `~/work`; five different Ollama model names across `.zshrc`, `llm`, Zed, install next-steps and docs. Add `~/.claude/statusline-command.sh` to the repo and map, or drop the setting.
9. **Health check blind spots.** Add erlang/yarn/java (they are in mise config), sketchybar/borders/atuin, and a check that the active theme's installed assets exist (`~/.config/bat/themes`, `~/.config/zed/themes`).

### Tier 2: adopt the Quattro architecture (weeks, the real payoff)

> **Status (2026-09-03):** items 1, 2, 3 and 4 are done — `colors.toml` + `themes/_templates/*.tpl` rendered by `scripts/theme-render.sh` into `~/.local/state/dotfiles/current/theme/` with an atomic swap; every app reads from there or gets a gitignored generated copy; `bin/dotfiles-hook` fires `theme-set`/`post-sync`/`post-update`; `bin/dotfiles-migrate` runs `migrations/*.sh` once per machine. Items 5, 6 and 7 followed: `bin/dotfiles` routes by filename with `# dotfiles:summary=` headers and `commands --check`; `bin/dotfiles-toggle` flag files gate startup-apps, borders and auto-commit; `bin/dotfiles-keys` generates `docs/KEYBINDINGS.md` from `aerospace.toml` with a CI drift check. Items 9 and 10 followed: `AGENTS.md` (+ `CLAUDE.md`) for contributors, `agents/skills/dotfiles/` shipped into `~/.claude/skills` via the symlink map, `dotfiles default-agent` behind an `a` shell function, and `oclaude` moved from `--dangerously-skip-permissions` to `--permission-mode auto`. Item 8 followed: `tests/base-test.sh` (fresh `HOME`, TAP `pass`/`fail`, exit on first failure) is sourced by every `tests/<area>-test.sh`, `tests/run` discovers them and continues past a failing file, CI builds its matrix from the same glob, and `tests/e2e/install-e2e.sh` runs the real `install.sh` under `/bin/bash` 3.2 into a fresh `HOME` with `--groups core` (behind a new `--no-runtimes` flag) as its own job. Item 11 followed: `update.sh` takes a `mkdir` lock with stale-pid detection, keeps a transcript in `~/.local/state/dotfiles/update.log` (via `script` on a tty, `tee` otherwise), accepts `--yes` and `--no-snapshot`, runs `tmutil localsnapshot` before `brew upgrade`, and ends with `dotfiles restart --pending` consuming `restart-<component>-required` markers set by the pull diff, refreshed symlinks or migrations, replacing the unconditional `aerospace reload-config` (whose `pgrep -x Aerospace` guard never matched the `AeroSpace` process). Item 12 followed: `dotfiles webapp install <name> <url>` builds a `~/Applications/<name>.app` that runs `open -na "Google Chrome" --args --app=<url>` with a fetched icon converted by `sips`/`iconutil`, and `dotfiles tui install <name> <cmd>` does the same around `open -na Ghostty --args -e /bin/zsh -lic '<cmd>'`; both write an `[[on-window-detected]]` rule between `DOTFILES_LAUNCHERS` markers placed ahead of the app-wide rules (AeroSpace applies the first match only), and their `remove` counterparts undo exactly what was made. Verified live afterwards: AeroSpace evaluates the title rule before Chrome or Ghostty has set the window title, so the rule alone left a `--float` launcher tiled; the launch script now waits for the new window and places it by id with `aerospace layout floating --window-id` / `move-node-to-workspace --window-id`, keeping the rule as a fallback. Tier 2 is complete.

**1. Palette-first theming with templates.**

- Add `themes/<name>/colors.toml` using Omarchy's exact key names. Vendor the 22 Omarchy palettes as a starting library (MIT). Keep `theme.conf` only for things that are not colours (which Zed/VS Code theme name to select, bat theme name).
- Add `themes/_templates/*.tpl` for every app you theme: `ghostty.tpl`, `starship-palette.tpl`, `zellij.kdl.tpl`, `lazygit.yml.tpl`, `sketchybar-colors.sh.tpl`, `bordersrc-colors.tpl`, `fzf.env.tpl`, `lsd.yaml.tpl`, `wezterm-palette.lua.tpl` (this finally themes WezTerm), `bat.tmTheme.tpl`, `nvim-theme.lua.tpl` (Omarchy feeds the palette to `bjarneo/aether.nvim`; you can do the same as the fallback when a theme has no hand-written plugin spec), and **`claude.json.tpl`** copied from Omarchy.
- Port `bin/omarchy-theme-set-templates` to `scripts/theme-render.sh`. It is bash + awk, needs bash 4+ for `declare -A` (Homebrew bash, which you already require in CI), and supports `{{ key }}`, `{{ key_rgb }}`, `{{ key_strip }}`, `{{ mix a b N% }}`.
- Keep the rule "a hand-written file in the theme dir beats the template" so Aura's bespoke files keep working.
- Result: adding a theme becomes "write one `colors.toml`", and `dotfiles-add-theme` shrinks to copying a sample.

**2. Stop mutating tracked files; render into state and include from there.**

Render the active theme into `~/.local/state/dotfiles/current/theme/` via a staging dir and an atomic `mv`, exactly like Omarchy. Then point each app at the generated file instead of `sed`-ing the tracked config:

| App | Include mechanism |
|---|---|
| Ghostty | `config-file = ~/.local/state/dotfiles/current/theme/ghostty` |
| Starship | keep `starship.toml` itself as a template, or set `STARSHIP_CONFIG` to the rendered file |
| Zellij | `theme_dir "~/.local/state/dotfiles/current/theme/zellij"` |
| lazygit | `LG_CONFIG_FILE="$HOME/.config/lazygit/config.yml,$STATE/lazygit.yml"` |
| sketchybar / borders | both are shell scripts; `source` the rendered colours file (sketchybar already does this for `colors.sh`) |
| fzf | already `~/.zshrc-theme-env`; just move it under state |
| bat | `--theme` in `~/.config/bat/config`, themes dir already external |
| WezTerm | `dofile(os.getenv("HOME") .. "/.local/state/dotfiles/current/theme/wezterm-palette.lua")` |
| Neovim | a rendered `lua/plugins/_theme.lua` in the state dir added to `rtp` |
| Claude Code | `~/.claude/themes/dotfiles.json` and `"theme": "custom:dotfiles"` in settings, as `bin/omarchy-theme-set-claude` does |
| git-delta | `[include] path = ~/.local/state/dotfiles/current/theme/delta.gitconfig` |

Effects: theme switches no longer dirty the repo, `snapshot: system state` noise disappears, two machines with different themes stop fighting over `main`, and the four-section `trap ERR` rollback is replaced by staging plus atomic rename for the generated part. Apps that need a config edit rather than an include (Zed, VS Code, Warp, Xcode, Sublime) stay as best-effort "retint" steps run in parallel after the swap, mirroring Omarchy's `post_theme_commands`.

**3. Hooks.** Add `bin/dotfiles-hook` (port `bin/omarchy-hook` verbatim, ~28 lines) and fire `theme-set`, `post-install`, `post-update`, `post-sync` from the existing scripts. Users drop scripts into `~/.config/dotfiles/hooks/<event>.d/`. This is where Slack/Telegram/Raycast "manual instructions" can become user scripts instead of a printed list.

**4. Migrations.** Add `migrations/<unix-ts>.sh`, markers in `~/.local/state/dotfiles/migrations/`, and run pending ones from `dotfiles update` and `dotfiles sync` (`bash -euo pipefail`, idempotent, per-machine). First candidates: moving theme state out of tracked files (item 2), relocating `~/.zshrc-theme-env`, and any future symlink-map rename. Add `dotfiles migrate --pending` for the health check.

**5. CLI router with metadata headers.** Replace the `case` in `bin/dotfiles` with filename routing (`dotfiles theme set aura` → `dotfiles-theme-set aura`, longest-prefix, `exec`). Give every script a `# dotfiles:summary=` and `# dotfiles:args=` header. Generate `dotfiles commands`, `dotfiles commands --json`, and the zsh completion from those headers so `.zshrc-work-completions` stops drifting. Fold `work-*` and `repos-clone` into the namespace (`dotfiles work setup`, `dotfiles repos clone`) while keeping the old names as aliases. Adopt the prefix vocabulary: `refresh-`, `restart-` (aerospace, sketchybar, borders), `toggle-`, `install-`, `setup-`, `show-`. Add a `--check` lint to CI so a script without a summary fails the build.

**6. Toggles.** `dotfiles toggle <flag> [on|off]` as flag files under `~/.local/state/dotfiles/toggles/`, with `aerospace`, `sketchybar`, `borders`, and `startup-apps` as the first consumers (`startup-apps.sh` should check `startup-apps-off`).

**7. Generated keybinding cheatsheet.** Omarchy's `o.bind(key, description, target)` carries a description for `Super+K`. Add a `# desc:` comment convention above each AeroSpace binding, and a `dotfiles keys` command that parses `aerospace.toml` into an fzf list and regenerates `docs/KEYBINDINGS.md`. Bind it in AeroSpace so discovery no longer depends on prose. Add a CI check that the generated doc matches the committed one.

**8. Test contract and coverage.** Adopt a `tests/base-test.sh` with TAP output and exit-on-first-failure per file, auto-discover `tests/*-test.sh`, and make the runner continue past a failing file. Add: an `install.sh` end-to-end run on `macos-latest` with a fresh `HOME` and `--groups core`; a `health-check` suite; golden-file tests for the template renderer (feed a `colors.toml`, diff the rendered ghostty/zellij/claude output); a docs-drift test for keybindings and the theme app list.

**9. Agent-facing documentation.** Add `AGENTS.md` at the root (style rules, command naming, which files are generated, "never edit under `~/.local/state`") with `CLAUDE.md` as `@AGENTS.md`, mirroring Omarchy. Ship a `dotfiles` skill (`agents/skills/dotfiles/SKILL.md` plus `theming.md`, `aerospace.md`, `shell.md`) and symlink it into `~/.claude/skills` from the map. Your existing `.claude/agent-memory/` notes are a head start.

**10. AI hygiene.** Add `dotfiles default agent <claude|codex|opencode|…>` and an `a` alias that dispatches to it. Change `oclaude` and the `cx`-style aliases to `--permission-mode auto` rather than `--dangerously-skip-permissions`, and review `skipDangerousModePermissionPrompt` in `settings.json`. Add the Claude theme template from item 1. Consider a sketchybar `agents` item that shows Claude usage the way Omarchy's bar plugin does (`bin/omarchy-agent-usage-claude` is the reference for the data source).

**11. Update pipeline hardening.** In `update.sh`: a lock file, a `script` transcript to `~/.local/state/dotfiles/update.log`, a `--yes` flag for unattended runs, `tmutil localsnapshot` before `brew upgrade` as the snapper analogue, and restart markers (`restart-aerospace-required`, `restart-sketchybar-required`) consumed at the end instead of unconditional `aerospace reload-config`.

**12. Web apps and TUI launchers.** `dotfiles webapp install <name> <url>` that builds a minimal `.app` bundle wrapping `open -na "Google Chrome" --args --app=<url>` with a fetched icon, plus an AeroSpace float/workspace rule; `dotfiles tui install <name> <cmd>` that wraps a command in a Ghostty launch. Both are small ports of `bin/omarchy-webapp-install` and `bin/omarchy-tui-install`.

### Tier 3: ambitious extras

> **Status (2026-09-03):** light themes and mode switching are done — `themes/catppuccin-latte/` and `themes/flexoki-light/` (Omarchy palettes with Ghostty's ANSI black/white slots), `apply-theme.sh` renders `{{ mode }}` once, records it in `theme.mode`, pins Zed's `theme.mode` and fills the matching slot, and flips macOS appearance through the `dark-mode` CLI (Brewfile) or a watchdogged `osascript` fallback, behind `dotfiles toggle appearance` and `DOTFILES_NO_APPEARANCE`. Editor themes come from `catppuccin.catppuccin-vsc`, `shadesofbuntu.flexoki-light` and Zed's `catppuccin` / `flexoki-themes` extensions. Per-theme backgrounds followed: `scripts/theme-background.sh` renders a 2560x1600 gradient from the palette (a 32x20 TGA written with `printf`/`awk`, upscaled by `sips`) into the rendered theme dir; `dotfiles theme bg next|set|current|list|generate|dir` cycles `themes/<name>/backgrounds/`, `~/.config/dotfiles/backgrounds/<name>/` and that gradient behind a `current/background` symlink; the desktop is set with `desktoppr` (Brewfile cask) or a watchdogged System Events call; `apply-theme.sh` picks a background only when the theme changes, behind `dotfiles toggle background`. `dotfiles reminder <minutes> [message] | show | clear` followed: each reminder is a launchd agent (`com.dotfiles.reminder.<set-at>-<minutes>m`, `StartInterval`, so it survives sleep and a closed terminal) whose `--fire` run removes its plist, posts the notification through `terminal-notifier` or `osascript display notification` with the message passed in the environment, and unloads itself. `dotfiles menu [route]` followed: an fzf tree (Theme with the active one starred and each theme's mode, Toggles with state, Launchers with install prompts and remove rows for existing bundles, Reminder presets, Update/Sync/Health/Doctor/Backup/Keys, and All commands from `dotfiles commands --plain`) where every row is a shell command; `--list` prints `label<TAB>command` rows and `--run <label>` executes one, so the tree is scriptable and testable without fzf, and Ctrl+Shift+Space opens it in a Ghostty window. Theme install from a git URL followed: `dotfiles theme install <url>` clones into `~/.config/dotfiles/themes/<name>/` (discovered alongside `themes/`, repo names win), and `apply-theme.sh` tells a cloned theme by its `.git` and stages only colour data from a sanitised copy, dropping `nvim/*.lua`, every override except `claude.json`/`lsd.yaml`/`zellij.kdl`, unknown files and symlinks at any depth, and parsing `theme.conf` for known `key="value"` lines instead of sourcing it; Neovim then uses `themes/_shared/nvim/dotfiles-theme.lua`, a base16 colorscheme built from the rendered palette, which also covers scaffolds without a spec. `dotfiles theme remove` undoes an install. The unattended answers file followed: `install.sh --answers <file>` (or `DOTFILES_ANSWERS`, or `~/.dotfiles-answers.json` when present) reads a JSON file mirroring the flags (`name`, `email`, `work_email`, `work_dir`, `theme`, `ssh`, `groups` as an array or comma string, `macos_defaults`, `runtimes`) through `plutil` with a python3 fallback, below flags and environment and above defaults; a named file that is missing or invalid stops the run, unknown keys are warned about, and the e2e install's second run is driven by one. Tier 3 is complete.

- **Light themes and mode switching.** Import `catppuccin-latte` and `flexoki-light`; use the `mode` key to flip macOS appearance with `osascript -e 'tell app "System Events" to tell appearance preferences to set dark mode to false'`.
- **Per-theme backgrounds.** `themes/<name>/backgrounds/` plus `dotfiles theme bg next`, setting the desktop via `osascript` or `desktoppr`. Omarchy's `choose_theme_background` and the `current/background` symlink are the model.
- **Theme install from git URL** with Omarchy's denylist (`*.lua`, terminal configs, symlinks) applied at staging, not at clone time.
- **Reminders.** `dotfiles reminder 15 "Tea"` via `launchctl`/`sleep` and `osascript display notification`. Twenty lines, surprisingly useful.
- **A `dotfiles menu`** built on `gum` or fzf mirroring Omarchy's Style / Setup / Install / Update tree, so every CLI verb has a discoverable entry point. Raycast script commands are the macOS-native alternative.
- **Unattended answers file.** You are close already via `DOTFILES_*` env vars; a `~/.dotfiles.json` read by `install.sh` would mirror `user_configuration.json`.

### Tier 4: proposed after the 2026-09-03 re-audit

> **Status: proposed, not started.** Section 2 was re-read against Omarchy `quattro` at `f99d33a` (2026-09-02) once Tiers 1 to 3 were closed. The table lists what each subsection still lacks; the items below are the ones worth doing, ranked by value against cost. Nothing here changes architecture: every item slots into the pipeline, router, hook, toggle and test contract that Tier 2 built.

| Section | Covered by Tiers 1 to 3 | Still open |
|---|---|---|
| 2.1 Theming | palette, templates, atomic swap, light modes, backgrounds, git install with denylist | Zed and VS Code are still retinted in place (loose end 4); no `theme update` for git-installed themes; no terminal palette preview; no lock around `apply-theme.sh`; fonts are hard-coded in four configs |
| 2.2 CLI | filename routing, headers, `commands --check/--json/--plain`, generated completions | no `# dotfiles:examples=` header; no style lint over `bin/` (`test/shell.d/bin-style-test.sh` is the model) |
| 2.3 Layering and migrations | migrations, `migrate --pending`, update lock and transcript, restart markers | nothing surfaces pending migrations or a repo that is behind `origin/main`; `update.sh` does not hold the Mac awake |
| 2.4 Hooks and toggles | `dotfiles hook`, `theme-set`/`post-sync`/`post-update`, five toggles | no shipped `.sample` hooks, no `hook install`, `post-install` was proposed but never fired |
| 2.5 Tests and docs | contract, 26 suites, e2e install, `keys --check`, `commands --check` | suite counts in three docs and the MAINTENANCE list are maintained by hand; no keybinding conflict test; THEMES.md app list can drift again |
| 2.6 AI | `AGENTS.md`, skill, `default-agent`, `--permission-mode auto`, Claude theme | no `debug` bundle for agents (Omarchy's skill leads with `omarchy debug --print`); skill only linked into `~/.claude`; no usage widget; no crash-to-agent hand-off |
| 2.7 Desktop UX | menu, generated cheatsheet, launchers, reminders | menu has no user extension point; none of Omarchy's shell functions (worktrees, port forwards, compress) were ported |
| 2.8 Security | theme denylist | nothing transferable remains |

> **Item 1 done (2026-09-03):** `tests/docs-test.sh` derives the suite count from the `tests/*-test.sh` glob and checks README, STRUCTURE and MAINTENANCE, requires a `- **Name** (`<area>`) —` bullet per suite in MAINTENANCE, checks the THEMES.md table against its own counts, every template and bundled theme, and checks the skill's command table, toggles and fired hook events against `dotfiles commands --plain`, `bin/dotfiles-toggle` and the hook call sites. `tests/style-test.sh` checks shebangs, strict mode in commands and its absence in libraries, `((VAR++))`, bash 4 builtins and `/bin/bash -n` on the install path, targeted `osascript` outside the theme helpers, and the summary header on line 2. Both run under `/bin/bash` 3.2. The `((VAR++))` cleanup shipped as its own commit.

**1. Drift tests for docs and style.** Two suites. `tests/docs-test.sh` asserts that the suite count in `README.md` and `docs/STRUCTURE.md` equals the `tests/*-test.sh` glob, that `docs/MAINTENANCE.md` names every suite, that the auto-configured app count in `docs/THEMES.md` equals the template count plus the retint list, and that `agents/skills/dotfiles/commands.md` mentions every non-hidden route from `dotfiles commands --plain`. `tests/style-test.sh` encodes `AGENTS.md` and the gotcha list: every `bin/dotfiles-*` starts with `set -euo pipefail`, no `((VAR++))`, no `declare -A` or `mapfile` in files on the install path, and no `osascript` that targets an application outside the watchdogged helper in `scripts/apply-theme.sh`. Both run in CI through the existing glob. Removes three manual edits per new suite. Small.

> **Item 2 done (2026-09-03):** `.config/zed/settings.base.json` and `.config/vscode/settings.base.json` are tracked; `apply-theme.sh` renders `settings.json` next to each (gitignored) with Zed's `theme.mode`/slot set through jq and VS Code's `"workbench.colorTheme": "{{ vscode_theme }}"` placeholder replaced by sed (the file is JSONC), creates the app-side link when nothing is there, and before every render copies anything changed in the editor's own settings UI back into the base, so in-app edits still reach git while theme switches never dirty it. Not a template in `themes/_templates/` because both editors rewrite the file themselves; the adopt step is what makes the generated copy safe. A migration seeds the generated files on machines that pull the rename; the e2e install now asserts a clean tree apart from `.gitconfig`.

**2. Render Zed and VS Code settings instead of retinting them.** Closes loose end 4. Move the tracked files to `.config/zed/settings.base.json` and `.config/vscode/settings.base.json`, add `zed.settings.json.tpl` and `vscode.settings.json.tpl` that splice `{{ zed_theme }}`, `{{ mode }}` and the VS Code theme name into the base, install the output as gitignored `settings.json` through `_install_rendered`, and delete the in-place `sed` steps. A migration removes the old tracked copies from working trees. After this no theme switch touches a tracked file, which was the whole point of Tier 2 item 2. Medium.

> **Item 3 done (2026-09-03):** `dotfiles update available [--cached|--short|--quiet]` fetches origin under a perl `alarm` (macOS has no `timeout`), counts commits behind, `brew outdated`, pending migrations and restart markers, writes `~/.local/state/dotfiles/update-available`, and exits 1 when nothing is waiting. `.zshrc` prints one line from the cache at login, refreshing it at most once a day through a detached job, behind `dotfiles toggle update-notice`; `update.sh` refreshes the cache at the end, runs under `caffeinate -i -w $$`, and its exit trap now names the transcript and the next step on failure. `dotfiles health` reads the cache in a new Updates check. Suite: `tests/update-available-test.sh`; the update suite covers caffeinate and the failure hint.

**3. Update awareness.** Port `omarchy-update-available` and `omarchy-migrate-notify` as `dotfiles update --available`: a `timeout 10 git fetch` against `origin/main`, the commit count behind, `brew outdated --quiet | wc -l`, and `dotfiles migrate --pending`, written to `~/.local/state/dotfiles/update-available` with a timestamp. `.zshrc` prints one line from that file when it is older than a day and non-empty, never fetching in the shell. `scripts/health-check.sh` gains a section for the same three facts. Wrap `update.sh` in `caffeinate -i` (Omarchy's `omarchy-update-stay-awake`) and, on failure, print "run `dotfiles debug` and hand the output to `a`". Small.

**4. `dotfiles debug [--print]`.** The agent-facing bundle Omarchy's skill opens with. Contents: `git describe --always --dirty` and the last commit date, macOS and chip, Homebrew and bash versions, `dotfiles health` output, pending migrations and restart markers, active theme and mode from the rendered state dir, symlink map status, and the last 50 lines of `update.log`. `--print` writes to stdout; the default writes `~/.local/state/dotfiles/debug.log` and copies it with `pbcopy`. Add it to the skill's first paragraph and to `AGENTS.md`. Also link `agents/skills/dotfiles` into `~/.codex/skills` and `~/.gemini/config/skills` from the map (only when those directories exist), mirroring `omarchy-provision-user`. Small.

**5. Fonts as a setting.** `dotfiles font list|current|set <name>`. The chosen family lives in `~/.local/state/dotfiles/font`; `apply-theme.sh` exposes it as a `{{ font }}` token with `Fira Code` as the default; `ghostty.tpl` and `wezterm.lua.tpl` use it, and the Zed and VS Code templates from item 2 use it too. `set` verifies the family with `fc-list` when fontconfig is installed and fires a `font-set` hook. Medium.

**6. Hooks polish.** Ship `config/dotfiles/hooks/<event>.d/*.sample` for `theme-set` (retint an app the pipeline does not know), `post-update` (notification) and `post-sync`, copied, not symlinked, into `~/.config/dotfiles/hooks/` by install and doctor since the directory is user-owned. Add `dotfiles hook install <event> <file>` (port of `omarchy-hook-install`, 25 lines). Fire `post-install` at the end of `install.sh` as Tier 2 item 3 intended, and `font-set` from item 5. Small.

**7. Theme polish.** `dotfiles theme update` fast-forwards every theme under `~/.config/dotfiles/themes/` (port of `omarchy-theme-update`, then re-applies if the active theme changed). `dotfiles theme preview [name]` prints the palette as swatches in the terminal (port of `omarchy-dev-theme-preview` without the OSC step), and the menu's Theme rows preview on hover through fzf's `--preview`. Give `apply-theme.sh` the same `mkdir` lock `update.sh` uses so `dotfiles menu`, `sync` and `update` cannot render concurrently. Small.

**8. Keybinding conflict test.** Extend `tests/keys-test.sh` with the check `test/shell.d/hyprland-binding-conflicts-test.sh` does for Hyprland: no key bound twice within a mode of `aerospace.toml`, every launcher rule references a bundle that the map or `dotfiles webapp`/`tui install` can produce, and every binding whose command is not self-explanatory carries a `# desc:` line. Small.

**9. Menu extensions.** `~/.config/dotfiles/menu.d/*.tsv` with `label<TAB>command` rows, a slash in the label nesting under a submenu, merged into `dotfiles menu --list` after the built-in tree; reusing a built-in label overrides that row, as `omarchy-menu.jsonc` does. Small.

**10. Shell functions worth porting.** From `default/bash/fns/`: `ga <branch>` and `gd` for git worktrees next to the repo with `mise trust` (this repo's Rails and Phoenix work is where worktrees pay off), `compress`/`decompress`, and `fip`/`dip`/`lip` SSH port forwards. Into `.zshrc-terminal-enhancements` with a mention in `docs/DAILY_WORKFLOWS.md`. Skip the tmux dev layouts (Zellij layouts exist) and the rsync watchers. Small.

**11. Ambitious, only with appetite.** An `agents` sketchybar item fed by a port of `bin/omarchy-agent-usage-claude` (python3, reads `~/.claude/projects/*.jsonl` and the OAuth usage endpoint, caches JSON under `~/.cache/dotfiles`). A crash watcher as a launchd agent with `WatchPaths` on `~/Library/Logs/DiagnosticReports`, posting a notification whose click runs `a` with a diagnose prompt, behind `dotfiles toggle crash-capture`. Each is medium to large.

Suggested order: 1, 3, 2, 7, 4, 6, 8, 5, 9, 10, then 11 if wanted. Items 1 and 3 first because they remove recurring manual work and make every later item cheaper to verify.

## 4. What not to copy

- **Package-backed distribution.** Homebrew and `brew bundle` are your pacman; there is nothing to gain from building packages.
- **Copy-into-home instead of symlinks.** Omarchy needs copies because it is multi-user and package-owned. For a personal repo symlinks are better, provided tooling stops writing into tracked files (Tier 2, item 2).
- **Bash as the interactive shell.** Keep zsh; the Omarchy style guide's bash 5 rules still apply to your scripts.
- **Quickshell, Hyprland Lua config, uwsm, snapper, SDDM, Plymouth.** Linux desktop plumbing with no macOS analogue. AeroSpace + sketchybar + borders is the right stack.
- **The `dots` and `backup` plans (`plans/dots.md`, `plans/backup.md`).** A bare git repo over `$HOME` and a restic pipeline solve problems this repo does not have: the configs already live in git, and off-site file backup is Time Machine's job, not the dotfiles'.
- **Shell plugins, notices, capture, clipboard history, update channels.** Quickshell plugins have no sketchybar analogue worth building; date, weather and battery notices are sketchybar items; screenshots, recording and OCR are Cmd+Shift+5 and Live Text; clipboard history is Raycast; a single `main` branch has no need for stable/RC/edge/dev channels.
- **Docker-hosted databases by default.** Your native PostgreSQL 16 / MySQL / Redis via Homebrew plus `pg_isready` health checks is a better developer experience on macOS.

## 5. Suggested sequencing

1. Tier 1 items 1 to 5 in one PR: they are bug fixes and unblock everything else.
2. Palette-first theming (Tier 2, items 1 and 2) as the first structural change, because it removes the repo-mutation problem, themes WezTerm and Claude Code, and unlocks 22 palettes.
3. Hooks, toggles and migrations together (items 3, 4, 6); they are each under 60 lines and the theming change is the first migration.
4. The CLI router and generated completions (item 5), then the generated keybinding doc (item 7).
5. Test contract and the install end-to-end suite (item 8), then `AGENTS.md` and the skill (items 9 and 10).
6. Everything else as appetite allows.

The end state is a repo that keeps its macOS-native strengths (symlink map, health/doctor, work identity, 1Password SSH, Rails/Phoenix depth, CI) while gaining Quattro's extensibility: one palette file per theme, generated configs that never dirty git, hook and toggle extension points, migrations for cross-machine changes, a self-documenting CLI, and documentation that agents and humans can both trust.

---

*Sources: this repo at `main`; Omarchy `quattro` at `d3d23fd` (2026-09-02), in particular `docs/theming.md`, `docs/cli-router.md`, `docs/update-process.md`, `docs/testing.md`, `docs/file-layout.md`, `AGENTS.md`, `bin/omarchy-theme-set`, `bin/omarchy-theme-set-templates`, `bin/omarchy-theme-set-claude`, `bin/omarchy-hook`, `bin/omarchy-toggle`, `default/themed/*.tpl`, and `default/agents/skills/omarchy/`.*
