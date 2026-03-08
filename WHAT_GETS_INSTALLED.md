# What Gets Installed

A complete breakdown of every tool, language, config, and system change that `bash install.sh` makes. No surprises.

---

## Step 1: Homebrew

Installs [Homebrew](https://brew.sh/) (macOS package manager) if not already present. On Apple Silicon Macs, it also configures the PATH in `~/.zprofile`.

---

## Step 2: Brewfile (305 packages)

Runs `brew bundle install` which installs everything declared in the `Brewfile`:

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

### Cask Apps (50 GUI apps + 73 fonts)

**Browsers**
- Google Chrome, Firefox, Zen, DuckDuckGo

**Terminals**
- Ghostty (GPU-accelerated), WezTerm, Warp

**Code Editors**
- Zed, Visual Studio Code

**Communication**
- Discord, Slack, Signal, Telegram, WhatsApp, Zoom

**Productivity**
- Notion, Obsidian, Raycast, Hidden Bar (menu bar manager), LibreOffice

**Dev Tools**
- Docker Desktop, Bruno (API client), Requestly (HTTP interceptor)

**Database GUIs**
- Beekeeper Studio (SQL), Postico (Postgres), Redis Insight

**Security & Privacy**
- 1Password, 1Password CLI, ProtonVPN, Proton Mail, Proton Pass, Okta Verify, Tailscale (mesh VPN)

**Window Management**
- Aerospace (i3-like tiling)

**AI**
- Claude (desktop app), Claude Code (terminal-based), Wispr Flow (voice dictation)

**Utilities**
- TextSniper (OCR), iStat Menus (system monitoring), LanguageTool (grammar checker), LocalSend (AirDrop alternative), balenaEtcher (USB flasher), Raspberry Pi Imager

**Email**
- Tuta Mail (encrypted)

**Media**
- VLC

**Other**
- Android Platform Tools

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

## Step 7: TPM (Tmux Plugin Manager)

Clones [TPM](https://github.com/tmux-plugins/tpm) to `~/.tmux/plugins/tpm`.

Plugins are **not** installed yet — you do that manually after install by opening tmux and pressing `Ctrl+A, Shift+I`. This installs 8 plugins including Tokyo Night theme, vim navigation, session persistence, etc.

---

## Step 8: Neovim

Config was already symlinked in Step 6. This step just confirms it.

On first `nvim` launch, [lazy.nvim](https://github.com/folke/lazy.nvim) automatically installs all plugins defined in the 17 plugin config files under `.config/nvim/lua/plugins/`. This includes AstroNvim, Treesitter, Telescope, Harpoon, LSP configs for Ruby, Elixir, TypeScript, Zig, and more.

---

## Step 9: Default Shell

Sets zsh as your default shell via `chsh -s $(which zsh)`. Skipped if zsh is already the default (which it is on modern macOS).

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

- No changes to your `~/.gitconfig` (you set that up yourself)
- No SSH keys generated
- No cloud service credentials
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
