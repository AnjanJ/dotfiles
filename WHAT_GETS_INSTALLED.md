# What Gets Installed

A complete breakdown of every tool, language, config, and system change that `bash install.sh` makes. No surprises.

---

## Step 1: Homebrew

Installs [Homebrew](https://brew.sh/) (macOS package manager) if not already present. On Apple Silicon Macs, it also configures the PATH in `~/.zprofile`.

---

## Step 2: Brewfile (322 packages)

Runs `brew bundle install` which installs everything declared in the `Brewfile`. This includes Homebrew packages, cask apps, VS Code extensions, and Mac App Store apps (via `mas`):

### Taps (10 third-party repos)

Aerospace, Cloudflare, Sketchybar/Borders, Heroku, LazySql, Render, steipete's CLI tools, Supabase, Obsidian CLI

### Brew Packages (72 CLI tools)

**Shell & Prompt**
- `starship` — Rust-based prompt (16x faster than Spaceship)
- `zoxide` — Smarter `cd` that learns your habits
- `fzf` — Fuzzy finder for files, history, everything

**Editors**
- `neovim` — Vim-fork with Lua plugin system

**Terminals & Multiplexers**
- `tmux` — Terminal multiplexer with session persistence
- `zellij` — Modern Rust-based multiplexer alternative

**Window Management**
- `borders` — Visual window borders (used by Aerospace)
- `sketchybar` — Custom macOS status bar

**Git**
- `git` — Version control
- `gh` — GitHub CLI
- `git-delta` — Beautiful diff viewer
- `gitui` — Terminal UI for git
- `lazygit` — Terminal UI for git (alternative)

**Search, Files & Navigation**
- `ripgrep` — Fast grep replacement
- `fd` — Fast find replacement
- `bat` — `cat` with syntax highlighting
- `eza` — Modern `ls` replacement
- `lsd` — Another `ls` replacement with icons
- `tree` — Directory tree viewer
- `yazi` — Terminal file manager

**Version Manager**
- `mise` — Polyglot runtime manager (manages Ruby, Node, Elixir, Python, Go, Rust)

**Languages**
- `zig` — Systems programming language (installed via Homebrew, not mise)

**Databases**
- `postgresql@14` — Relational database (starts as service)
- `mysql` — Relational database (starts as service)
- `redis` — Key-value store (starts as service)
- `litecli` — SQLite CLI with autocomplete
- `pgcli` — Postgres CLI with autocomplete
- `mycli` — MySQL CLI with autocomplete
- `lazysql` — Terminal UI for databases

**Containers**
- `docker` — Container runtime
- `lazydocker` — Terminal UI for Docker

**Cloud & Deploy**
- `flyctl` — Fly.io CLI
- `heroku` — Heroku CLI
- `render` — Render CLI
- `cloudflared` — Cloudflare Tunnel
- `supabase` — Supabase CLI

**Media**
- `ffmpeg` / `ffmpeg-full` — Audio/video processing
- `yt-dlp` — Video downloader

**Documents & Text**
- `pandoc` — Universal document converter
- `unar` — Multi-format archive tool
- `poppler` — PDF rendering library

**Networking**
- `wget` — File downloader
- `putty` — SSH/Telnet client

**Log Viewers**
- `lnav` — Log file navigator
- `tailspin` — Log file highlighter

**Other CLI Tools**
- `tldr` / `tlrc` — Simplified man pages
- `uv` — Fast Python package installer
- `gemini-cli` — Google Gemini AI from terminal
- `memo` — Apple Notes CLI
- `obsidian-cli` — Obsidian vault CLI

**steipete's macOS CLI Tools**
- `bird` — X/Twitter CLI
- `imsg` — iMessage/SMS from terminal
- `peekaboo` — Screenshots + AI vision
- `summarize` — URL-to-summary
- `wacli` — WhatsApp CLI
- `gifgrep` — Search through GIFs
- `goplaces` — Google Places API
- `remindctl` — Apple Reminders CLI
- `sag` — ElevenLabs TTS
- `songsee` — Audio visualization

**Libraries** (dependencies for other tools)
- `glib`, `pango`, `librsvg`, `libyaml`, `libxmlsec1`, `libidn`, `libre`, `openssl@1.1`, `shared-mime-info`, `criterion`, `poppler`

### Cask Apps (41 GUI apps + 73 fonts)

**Browsers**
- Google Chrome, Firefox, Zen

**Terminals**
- Ghostty (GPU-accelerated, default), WezTerm, Warp

**Code Editors**
- Zed, Visual Studio Code

**Communication**
- Discord, Slack, Signal, Telegram, Zoom

**Productivity**
- Notion, Obsidian, Raycast, LibreOffice

**Dev Tools**
- Docker Desktop, Bruno (API client), Requestly (HTTP interceptor)

**Database GUIs**
- Beekeeper Studio (SQL), Postico (Postgres), Redis Insight

**Security & Privacy**
- 1Password, 1Password CLI, ProtonVPN, Proton Mail, Proton Pass

**Window Management**
- Aerospace (i3-like tiling)

**AI**
- Claude (desktop app), Claude Code (terminal-based), Wispr Flow (voice dictation)

**Utilities**
- balenaEtcher (USB flasher), Raspberry Pi Imager

**Email**
- Tuta Mail (encrypted)

**Media**
- VLC

**Other**
- Android Platform Tools

### Mac App Store Apps (18 via `mas`)

Installed automatically via `brew bundle` using the [mas](https://github.com/mas-cli/mas) CLI. Requires being signed into the App Store.

**Productivity & Utilities**
- Hidden Bar (menu bar icon management)
- iStat Menus (system monitoring)
- TextSniper (OCR screen capture)
- Menu Bar Calendar
- Numbers
- Bandwidth+

**Browsers & Privacy**
- DuckDuckGo
- Noir (Dark Mode for Safari)
- Perplexity

**Communication**
- WhatsApp

**Security & Networking**
- 2FAS (two-factor authentication)
- Tailscale (mesh VPN)

**Media & Creative**
- Gifski (GIF converter)
- GIPHY CAPTURE (screen-to-GIF)

**Reading & Bookmarks**
- Kindle
- Save to Raindrop.io

**Writing**
- LanguageTool (grammar checker)

**File Sharing**
- LocalSend (AirDrop alternative, cross-platform)

**Fonts (73 Nerd Fonts)**

Every major monospace font with Nerd Font glyphs patched in: Fira Code, JetBrains Mono, Hack, Iosevka, Cascadia Code, IBM Plex Mono, Inconsolata, Meslo, Victor Mono, and 60+ more.

### VS Code Extensions (110)

Extensions across these categories:
- **Ruby/Rails:** ruby-lsp, Solargraph, RuboCop, ERB formatting, Rails navigation, RSpec runner
- **Elixir/Phoenix:** elixir-ls, Credo, Phoenix framework support
- **JavaScript/TypeScript:** ESLint, Prettier, React snippets, auto-imports, Tailwind CSS
- **Python:** Python, Pylance, debugpy
- **Rust:** rust-analyzer, Rust extension pack
- **Dart/Flutter:** Dart, Flutter
- **AI Assistants:** GitHub Copilot, Copilot Chat, Claude Code, ChatGPT
- **Git:** GitLens, Git Graph, Git History, GitHub Actions, Pull Request manager
- **Themes:** Tokyo Night, Aura Dark, Kanagawa Black, Material Theme, GitHub Theme
- **Database:** MongoDB, SQLTools (MySQL, Postgres, SQLite)
- **Productivity:** Bookmarks, Project Manager, Todo Tree, Better Comments, Error Lens
- **Other:** Docker, YAML, TOML, Markdown, i18n, Import Cost, Code Metrics

### Go Packages (3)
- `blogwatcher`, `eightctl`, `things3-cli`

### UV Packages (2)
- `nano-pdf`, `specify-cli`

---

## Step 3: Create Directories

Creates these directories if they don't exist:

```
~/.config/aerospace/
~/.config/ghostty/
~/.config/nvim/
~/.config/zellij/
~/.config/zed/snippets/
~/.tmux/plugins/
~/bin/
```

---

## Step 4: Backup Existing Configs

Before touching anything, copies your current configs to a timestamped directory:

```
~/.dotfiles_backup_20260308_143022/
├── .zshrc
├── .tmux.conf
├── nvim/
├── aerospace/
├── ghostty/
├── zellij/
├── zed/
└── starship.toml
```

Only backs up files/directories that actually exist. Your originals are always safe.

---

## Step 5: mise (Version Manager)

Symlinks the mise config, trusts it, then runs `mise install` which downloads and installs:

| Language | Version | Notes |
|----------|---------|-------|
| **Ruby** | 3.4.5 | Pinned to specific version |
| **Elixir** | latest | |
| **Erlang** | latest | Required by Elixir |
| **Node.js** | latest | |
| **Python** | 3 | Latest Python 3.x |
| **Go** | latest | |
| **Rust** | latest | |

**Note:** Zig is installed via Homebrew (Step 2), not mise.

This replaces the need for rbenv, nvm, pyenv, or asdf. One tool manages all language versions.

---

## Step 6: Symlinks (17+ links)

Creates symbolic links from the repo to your home directory. This is the core design — all configs live in git, symlinks point to them.

### Shell Config
| Source (in repo) | Links to |
|---|---|
| `.zshrc` | `~/.zshrc` |
| `.zshrc-dhh-additions` | `~/.zshrc-dhh-additions` |
| `.zshrc-elixir-additions` | `~/.zshrc-elixir-additions` |
| `.zshrc-terminal-enhancements` | `~/.zshrc-terminal-enhancements` |
| `.zshrc-aliases` | `~/.zshrc-aliases` |
| `.tmux.conf` | `~/.tmux.conf` |

### App Configs (entire directories)
| Source (in repo) | Links to |
|---|---|
| `.config/aerospace/` | `~/.config/aerospace` |
| `.config/ghostty/` | `~/.config/ghostty` |
| `.config/nvim/` | `~/.config/nvim` |
| `.config/zellij/` | `~/.config/zellij` |
| `.config/starship.toml` | `~/.config/starship.toml` |

### Zed Editor (individual files)
| Source (in repo) | Links to |
|---|---|
| `.config/zed/settings.json` | `~/.config/zed/settings.json` |
| `.config/zed/tasks.json` | `~/.config/zed/tasks.json` |
| `.config/zed/snippets/ruby.json` | `~/.config/zed/snippets/ruby.json` |
| `.config/zed/snippets/erb.json` | `~/.config/zed/snippets/erb.json` |
| `.config/zed/snippets/zig.json` | `~/.config/zed/snippets/zig.json` |

### Custom Scripts
| Source (in repo) | Links to |
|---|---|
| `bin/*` | `~/bin/*` (e.g., `erb-lint-formatter`) |

**Why symlinks?** Edit a config in `~/dotfiles/`, and the change is immediately active *and* tracked by git. No copying, no syncing.

---

## Step 6b: Apply Theme

You chose either **Tokyo Night** or **Aura Dark** at the start of install. This step applies your choice across 8 apps automatically:

| App | What changes |
|-----|-------------|
| Ghostty | `theme = ` line in config (+ custom theme file for Aura) |
| Neovim | Plugin file + colorscheme in `astroui.lua` |
| Zellij | Theme KDL file + `theme` line in `config.kdl` |
| Starship | `palette` reference + palette section in `starship.toml` |
| tmux | Theme block in `.tmux.conf` (TPM plugin for Tokyo Night, hand-ported for Aura) |
| VS Code | `workbench.colorTheme` in settings.json |
| Warp | Copies theme YAML to `~/.warp/themes/` (Aura only; Tokyo Night is built-in) |
| Zed | `theme.dark` in `settings.json` |

Manual instructions are printed for: Slack, Chrome, Firefox, Telegram, Raycast.

Switch anytime later with: `dotfiles theme`

---

## Step 7: TPM (Tmux Plugin Manager)

Clones [TPM](https://github.com/tmux-plugins/tpm) to `~/.tmux/plugins/tpm`.

Plugins are **not** installed yet — you do that manually after install by opening tmux and pressing `Ctrl+A, Shift+I`. This installs 8 plugins including theme, vim navigation, session persistence, etc.

---

## Step 8: Neovim

Config was already symlinked in Step 6. This step just confirms it.

On first `nvim` launch, [lazy.nvim](https://github.com/folke/lazy.nvim) automatically installs all plugins defined in the 17 plugin config files under `.config/nvim/lua/plugins/`. This includes AstroNvim, Treesitter, Telescope, Harpoon, LSP configs for Ruby, Elixir, TypeScript, Zig, and more.

---

## Step 9: Default Shell

Sets zsh as your default shell via `chsh -s $(which zsh)`. Skipped if zsh is already the default (which it is on modern macOS).

---

## Step 9b: Git Configuration

Configures sensible Git defaults globally:

| Setting | Value | What it does |
|---------|-------|-------------|
| `core.editor` | `zed --wait` | Use Zed as the default editor for commits, rebases, etc. |
| `pull.rebase` | `false` | Merge on pull (no auto-rebase) |
| `core.excludesfile` | `~/.gitignore_global` | Global gitignore (.DS_Store, .env, etc.) |
| `diff.algorithm` | `histogram` | Better diffs, especially for moved code blocks |
| `rerere.enabled` | `true` | "Reuse Recorded Resolution" — auto-resolves repeated merge conflicts |
| `push.autoSetupRemote` | `true` | No more `git push -u origin branch-name` on first push |
| `branch.sort` | `-committerdate` | `git branch` shows most recent branches first |
| `commit.verbose` | `true` | Shows the full diff in your commit message editor |

Also symlinks `.gitignore_global` to `~/.gitignore_global`.

### Git Identity Setup

The script asks for your personal name and email, then optionally sets up a separate work identity:

- **Personal identity** → set as the global default (used everywhere)
- **Work identity** → applied only inside your work directory (default: `~/work/`)

This uses Git's `includeIf` with `gitdir:` — any repo cloned or initialized under your work directory automatically uses your work email. Everything else uses your personal email. Zero friction, works from the very first commit.

**Files created:**
- `~/.gitconfig` — global config with personal identity + smart defaults
- `~/.gitconfig-work` — work email override (only if work identity was configured)

**Verify it works:**
```bash
cd ~/code/my-personal-project && git config user.email  # → personal email
cd ~/work/company-project && git config user.email       # → work email
```

---

## Step 9c: SSH Configuration

Backs up your existing `~/.ssh/` directory, then offers five options:

| Option | Use when... |
|--------|-------------|
| **1Password SSH Agent** | You use 1Password — keys stay in the vault, synced across machines, Touch ID for every operation. Works offline. |
| **Import keys** | You have old keys saved elsewhere (USB drive, iCloud, backup folder). Copies them into `~/.ssh/`, fixes permissions, and configures SSH. |
| **Use existing keys** | You already have keys in `~/.ssh/` — just generates a clean `~/.ssh/config` and fixes permissions. |
| **Generate new keys** | Fresh machine, no old keys. Creates Ed25519 keys for personal (+ work if configured), adds to macOS Keychain. |
| **Skip** | You manage SSH yourself. |

**After choosing an option, you select which Git services you use:**
- GitHub, GitLab, Bitbucket, Codeberg, Gerrit, or self-hosted Git
- Select multiple (e.g., `1 2 5` for GitHub + GitLab + Gerrit)
- Each service gets its own `Host` block in `~/.ssh/config`
- You can create aliases for the same service (e.g., `github.com-work` for a work account)

**What gets configured (all options except skip):**
- `~/.ssh/config` with proper `Host` blocks for each selected service
- `IdentitiesOnly yes` to prevent key leaking to unknown servers
- Correct file permissions (`700` dir, `600` private keys, `644` public keys)
- macOS Keychain integration (`AddKeysToAgent`, `UseKeychain`) or 1Password `IdentityAgent`

**Using aliases for multiple accounts on the same service:**
```bash
# If you set up github.com-work as an alias:
git clone git@github.com-work:company/repo.git

# Change an existing repo to use the work alias:
git remote set-url origin git@github.com-work:company/repo.git
```

**Troubleshooting:** The script prints a full troubleshooting guide after setup, covering how to test connections, debug issues, check permissions, and restore your old config.

**Backup & restore:**
```bash
# Your old ~/.ssh/ is saved to:
~/.dotfiles_backup_YYYYMMDD_HHMMSS/ssh/

# Restore if needed:
cp -r ~/.dotfiles_backup_YYYYMMDD_HHMMSS/ssh/ ~/.ssh/
```

---

## Work Management Commands

Five commands in `~/bin/` for managing work identities. These are standalone scripts — they're not part of `install.sh` and can be run anytime.

| Command | What it does |
|---------|-------------|
| `work-setup` | Interactive setup: work email, directory, git identity (`includeIf`), SSH key + host blocks, shell config (`~/.zshrc-work`), clone repos |
| `work-status` | Read-only diagnostic: shows git identity, work directory, SSH hosts, shell config, gh auth, dirty repos |
| `work-nuke` | Remove all work config. Shows what will be removed, warns about dirty repos, double-confirms, backs up to `~/.work-nuke-backup-*` before deleting. Flags: `--dry-run`, `--yes` |
| `work-switch` | Change employer — runs `work-nuke --yes` then `work-setup` |
| `repos-clone` | Interactive repo cloner for GitHub (`gh`) and GitLab (`glab` or API). Lists repos, supports range selection (`1-5 7 9-11`), detects SSH aliases, skips existing repos. Flags: `--dir`, `--org`, `--all` |

**Files involved:**
- `bin/_work-helpers` — Shared utilities (colors, print helpers, config readers, `confirm_destructive`)
- `bin/work-setup`, `bin/work-nuke`, `bin/work-switch`, `bin/work-status`, `bin/repos-clone`

**What `work-setup` creates:**
- `~/.gitconfig-work` — work email override
- `includeIf.gitdir:` entry in `~/.gitconfig` — scopes work email to your work directory
- SSH `Host` blocks between `# === WORK:` / `# === END WORK ===` markers in `~/.ssh/config`
- `~/.zshrc-work` — optional shell config for work aliases and env vars

**What `work-nuke` removes:**
- All of the above, with timestamped backup first
- Optionally deletes the work directory (with second confirmation if it contains repos)

---

## Step 10: macOS Defaults (Optional)

**Asks for confirmation before applying.** These are system preference changes:

**Keyboard:**
- Key repeat speed: 2 (very fast)
- Initial key repeat delay: 15 (short)

**Finder:**
- Show path bar
- Show status bar
- Show full POSIX path in title bar

**Dock:**
- Auto-hide the Dock
- Hide recent applications

Some settings require logout/restart to take effect.

---

## Step 11: Health Check (Optional)

**Asks for confirmation before running.** Runs `scripts/health-check.sh` which validates 11 categories:

1. **Core tools** — Homebrew, git, zsh, mise, starship
2. **Terminals & multiplexers** — tmux, Zellij, Ghostty, TPM
3. **Window management** — Aerospace config, running status
4. **Editors** — Neovim, Zed, lazy.nvim
5. **Shell config** — All symlinks exist, environment variables set
6. **Language runtimes** — Ruby, Node, Elixir, Python, Go, Rust, Zig
7. **CLI utilities** — ripgrep, fd, fzf, bat, eza, tree, lazygit, gh
8. **Databases** — PostgreSQL, Redis (installed and running)
9. **Framework tools** — Bundler, Rails, Mix, Phoenix
10. **Custom scripts** — `~/bin/erb-lint-formatter`
11. **Shell integration** — mise activation, starship, default shell

Color-coded output with pass/fail/warning counts at the end.

---

## After the Script Finishes

The script prints these manual steps:

1. **Restart terminal** or `source ~/.zshrc`
2. **Install tmux plugins:** open tmux → press `Ctrl+A` then `Shift+I`
3. **Launch Neovim:** `nvim` (plugins auto-install on first launch)
4. **Start Aerospace:** `aerospace reload` (or logout/login)
5. **Configure Git:** `git config --global user.name "Your Name"`
6. **Verify mise:** `mise list` to see all installed language versions

---

## What Does NOT Get Installed

- No cloud service credentials or tokens
- No private/work configs (`.zshrc-work` is optional and not in the repo)
- No browser extensions
- No App Store apps

---

## Safe to Re-Run

The install script is **idempotent**. Running it again:
- Skips already-installed Homebrew
- `brew bundle` only installs missing packages
- Skips symlinks that already point to the right place
- Creates a new timestamped backup each time
- Use `--force` to override existing symlinks
