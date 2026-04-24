---
name: Dotfiles Repo Complete Architecture Overview
description: Comprehensive guide to all tools managed, installation flow, directory structure, automation, CI/CD, and what makes this repo unique
type: project
---

# AJ's Dotfiles Repository — Complete Architecture

**Date Analyzed**: 2026-03-23  
**Repo**: https://github.com/AnjanJ/dotfiles  
**Philosophy**: DHH's Omakub ("Everything in one place, everything just works") adapted for macOS

## What This Repo Is

Not just a dotfiles repository — a **complete macOS development environment in code form** optimized for Rails/Elixir developers. One-command installation, multi-theme support (Tokyo Night, Aura, Catppuccin), work identity separation, comprehensive testing (300+ assertions).

## Tools Managed (Summary)

### Core Environment
- **Shell**: zsh with 5 modular config files (~1,090 lines total)
- **Prompt**: Starship (16x faster than Spaceship)
- **Terminals**: Ghostty (GPU-accelerated, primary), Warp, WezTerm, zsh
- **Window Manager**: Aerospace (i3-style tiling) + JankyBorders + sketchybar

### Multiplexing & Editors
- **Multiplexers**: tmux (346 lines, 8 plugins) + Zellij (with rails/phoenix/work layouts)
- **Editors**: Neovim (AstroNvim), Zed (LSP, tasks, snippets), VS Code (installed only)
- **Git**: lazygit, gitui, git-delta, GitHub CLI

### Version & Environment
- **Version Manager**: mise (Ruby, Node, Elixir, Python, Go, Rust all "latest")
- **Environment**: direnv for .envrc files
- **Databases**: PostgreSQL 14, MySQL, Redis (auto-start), SQLite

### Homebrew
- **~325 packages** across: 75 brew formulas, 30 cask apps, 77 fonts, VS Code extensions, App Store apps
- **Auto-managed**: Brewfile snapshots on every update, one backup for rollback
- **Taps**: 10 custom taps (Aerospace, Cloudflare, sketchybar, etc.)

### Custom Scripts (20 commands)
- **Dotfiles CLI**: update, sync, health, theme, add-theme, cleanup, doctor, backup, profile, export, install, uninstall, edit, dir
- **Work Management**: work-setup, work-nuke, work-switch, work-status
- **Development**: repos-clone, erb-lint-formatter

## Installation Flow (12 Steps)

1. **Bootstrap** — Clones repo if running via curl-pipe, re-execs locally
2. **Theme Selection** — Auto-discovers themes, prompts user (default: tokyo-night)
3. **Homebrew** — Installs if missing, configures PATH for Apple Silicon
4. **Brewfile** — `brew bundle install` (~325 packages)
5. **mise Setup** — Links config, trusts it, installs language runtimes
6. **Symlinks** — Creates idempotent symlinks for all configs (backs up only real files)
7. **Theme Apply** — Updates 17 apps automatically, prints manual instructions for 5 more
8. **tmux Plugins** — Installs TPM, pre-configured plugins
9. **Git & SSH** — Personal identity, optional work email, SSH key setup (1Password/existing/generate/skip)
10. **macOS Defaults** — Keyboard, appearance, Finder, Dock, trackpad, hot corners (24 settings)
11. **Health Check** — Verifies installation
12. **Done** — Prints next steps

**Key Features**:
- **Truly idempotent** — run 10 times, same result
- **Non-interactive default** — sensible defaults, no prompts
- **Customizable via flags** — `--name`, `--email`, `--theme`, `--work-email`, `--ssh`, `--force`, `--no-macos-defaults`
- **Env vars accepted** — DOTFILES_GIT_NAME, DOTFILES_GIT_EMAIL, DOTFILES_WORK_EMAIL, etc.

## Update Mechanism

**Purpose**: Keep system and dotfiles repo in sync  
**Trigger**: `dotfiles update` or `bash update.sh`

**Flow**:
1. Git pull (with auto-stash of local changes)
2. Brew update/upgrade/cleanup
3. **Brewfile snapshot** — captures any new manual installs, shows diff
4. Refresh all symlinks
5. Upgrade mise tools
6. Update tmux plugins
7. Reload configs (tmux, aerospace)
8. Auto-commit & push (only on main branch)

## Directory Structure (46 directories)

**Root**: install.sh, update.sh, Brewfile, Brewfile.backup, README (706 lines), QUICK_REFERENCE.md, TOOL_GUIDE.md, WHAT_GETS_INSTALLED.md

**Shell Configs**:
- `.zshrc` (199 lines) — loader
- `.zshrc-dhh-additions` (340 lines) — Rails workflows
- `.zshrc-elixir-additions` (340 lines) — Elixir/Phoenix
- `.zshrc-terminal-enhancements` (212 lines) — fzf, zoxide, bat, eza, etc.
- `.zshrc-work-completions` (181 lines) — work completions
- `.tmux.conf` (346 lines)

**Configs** (`.config/`):
- `aerospace/` — tiling layouts, keybindings
- `ghostty/`, `mise/`, `nvim/`, `zed/`, `zellij/`, `starship.toml`, `lazygit/`, `borders/`, `sketchybar/`, `yazi/`

**Themes** (auto-discovered):
- `themes/tokyo-night/`, `themes/aura/`, `themes/catppuccin/`
- Each has: `theme.conf` (registry), then per-app subdirs (ghostty, nvim, tmux, zellij, starship, lazygit, lsd, yazi, sketchybar, gitui, manual-instructions.txt)

**Bin Scripts** (20 commands): dotfiles, dotfiles-*, work-*, repos-clone, erb-lint-formatter, _work-helpers

**Scripts**: _helpers.sh, setup-git.sh, setup-ssh.sh, health-check.sh, theme-utils.sh, apply-theme.sh

**Tests** (11 suites, 300+ assertions): test-idempotency, test-work-nuke, test-repos-clone, test-ssh-adversarial, test-update, test-theme, test-doctor, test-setup-git, test-work-status, test-backup, test-sync

**CI/CD**: .github/workflows/test.yml (runs all tests on push/PR)

**Docs**: screenshots/, DAILY_WORKFLOWS.md

## Theme System (Unique Architecture)

**3 themes** × **17 auto-configured apps** + **5 manual apps** = comprehensive visual consistency

**How it works**:
1. `themes/*/theme.conf` — Registry: variable name → filename mapping
2. Each theme directory has subdirectories for every app
3. `apply-theme.sh` reads the registry, copies app-specific configs
4. **Atomic apply + auto-rollback** — if apply fails halfway, all restored
5. Theme state persisted in `~/.dotfiles-theme` (not in repo)

**Apps covered**:
- Auto-configured: nvim, ghostty, tmux, zellij, starship, zed, vs code, bat, git-delta, fzf, lazygit, borders, sketchybar, yazi, gitui, lsd, warp (17)
- Manual: Slack, Chrome, Firefox, Telegram, Raycast (5)

## What Makes This Unique

1. **Multi-theme system** — Auto-discovered, atomic apply, rollback on failure
2. **True idempotency** — No setup quirks, run 100 times safely
3. **Modular shell config** — 5 files, easy to enable/disable features
4. **Work identity separation** — Personal + work git configs, separate SSH keys
5. **Brewfile automation** — Auto-snapshots new packages, shows diffs, rollback support
6. **SSH flexibility** — 1Password agent (Touch ID), existing keys, generate, or skip
7. **Rich helper commands** — doctor, backup, profile, export, repos-clone
8. **Comprehensive testing** — 300+ assertions, 11 test suites, CI/CD every push
9. **Language support** — mise manages Ruby, Node, Elixir, Python, Go, Rust (all latest)
10. **DHH philosophy** — "Everything in one place, everything just works"

## CI/CD (11 Test Suites)

**Triggered**: Every push to main and pull requests

| Test | Coverage | Duration |
|------|----------|----------|
| shellcheck | All shell scripts linting | ~30s |
| idempotency | Install/update safe 2+ runs (84 assertions) | ~5min |
| work-nuke | Work config removal | ~2min |
| repos-clone | SSH alias detection, URL rewriting | ~1min |
| ssh-adversarial | Edge cases & malicious input | ~1min |
| theme | Apply, rollback, discover (39 assertions) | ~2min |
| update | Symlink creation & refresh | ~3min |
| doctor | Auto-fix symlinks, permissions | ~1min |
| setup-git | Git identity setup | ~1min |
| work-status | Diagnostic output | ~1min |
| backup | Snapshot/restore cycle | ~2min |
| sync | Symlink refresh, dry-run | ~2min |

**Total**: ~20+ minutes automated verification per commit

## Target User

**Senior developer** who wants:
- Beautiful, opinionated, keyboard-first environment
- Rails/Elixir focus with polyglot support
- Minimal setup friction ("just works")
- Work identity separation
- Easy customization without breaking updates

## Key Statistics

| Metric | Value |
|--------|-------|
| Shell config lines | ~1,090 (5 files) |
| Git commits | 130+ |
| Test assertions | 300+ |
| Homebrew packages | ~325 |
| Theme configs | 51 (3 themes × 17 apps) |
| Custom commands | 20 |
| Directories | 46 |
| README lines | 706 |

## Key Files at a Glance

| File | Purpose |
|------|---------|
| install.sh | Main entry point (490 lines) |
| update.sh | System/repo sync (330 lines) |
| .zshrc | Shell loader (199 lines) |
| .tmux.conf | tmux config + 8 plugins (346 lines) |
| .config/mise/config.toml | Version manager registry (12 lines, all "latest") |
| scripts/_helpers.sh | Shared functions (68 lines) |
| scripts/apply-theme.sh | Theme apply logic (24k) |
| bin/dotfiles | CLI dispatcher (49 lines) |
| .github/workflows/test.yml | CI/CD pipeline |
| themes/*/theme.conf | Theme registry (variable → file mapping) |

## Recent Activity

- Active development (commits every few days)
- Latest: snapshot system state (2026-03-23)
- Focus areas: bug fixes, feature additions, test coverage
