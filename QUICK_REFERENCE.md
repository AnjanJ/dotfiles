# ⚡ Quick Reference Card

## 🎯 One-Liners

```bash
# Install everything (fresh Mac)
bash <(curl -fsSL https://raw.githubusercontent.com/AnjanJ/dotfiles/main/install.sh)

# Or clone first
git clone https://github.com/AnjanJ/dotfiles.git ~/dotfiles && bash ~/dotfiles/install.sh
```

## 🔧 Dotfiles CLI (works from anywhere, tab-completable)

```bash
dotfiles update       # Upgrade system & sync repo (--yes never asks)
dotfiles update available   # What is waiting: repo commits, brew upgrades, migrations, restarts
dotfiles sync         # Quick refresh: pull, relink, migrate, reapply theme
dotfiles health       # Verify all tools are installed
dotfiles doctor       # Auto-fix common issues
dotfiles debug --print   # One report of this machine's state on stdout (no flag: write file + copy to clipboard)
dotfiles theme aura   # Switch theme (tokyo-night | aura | catppuccin | catppuccin-latte | flexoki-light)
dotfiles theme preview [name]   # Palette swatches in the terminal (no name: the active theme)
dotfiles theme install <git-url>   # Add a theme from a repo; `theme update [name]` pulls it, `theme remove <name>` drops it
dotfiles theme bg next   # Desktop background for the theme: next | set <image> | list | current | generate | dir
dotfiles font set <family>   # Monospace font for every terminal and editor: current | list | set | reset
dotfiles menu         # fzf menu over every verb (Ctrl+Shift+Space opens it in Ghostty)
dotfiles reminder 15 "Tea"   # macOS notification in 15 minutes; `show` lists pending, `clear` cancels all
dotfiles restart <aerospace|sketchybar|borders>   # Restart a component now (--later defers it to the next update)
dotfiles add-theme x  # Scaffold a new theme directory
dotfiles cleanup      # Find/remove unlisted Homebrew packages (--force)
dotfiles backup       # Snapshot dotfiles state (--list, --restore)
dotfiles profile      # Measure shell startup time (--detailed)
dotfiles export       # Export setup snapshot (--json)
dotfiles toggle <f>   # Flip startup-apps / borders / auto-commit / appearance / background / update-notice / agent-usage
dotfiles keys         # AeroSpace keybinding cheatsheet (fzf); --update after editing aerospace.toml, --lint to check it
dotfiles hook --list  # User hooks in ~/.config/dotfiles/hooks/; --seed copies the samples there
dotfiles migrate --pending   # One-off per-machine repairs not yet run (sync and update run them)
dotfiles default agent <name>   # Which agent `a` launches: claude | oclaude | gemini | copilot | llm
dotfiles agent usage  # Claude plan usage: the 5-hour session and 7-day windows
dotfiles webapp install <name> <url>   # Chrome --app launcher + AeroSpace rule (`webapp remove <name>`)
dotfiles tui install <name> <cmd>      # Ghostty launcher for a terminal command + AeroSpace rule (`tui remove <name>`)
dotfiles commands     # List every command
dotfiles install      # Re-run full installer
dotfiles uninstall    # Remove every managed symlink (keeps repo and packages; --yes skips the prompt)
dotfiles edit         # Open dotfiles in your editor
dotfiles dir          # Print dotfiles directory path
```

## ⌨️ Essential Keybindings

### Aerospace (Window Manager)
**Note**: Uses `Ctrl+Shift` for international keyboards (DHH-inspired)

| Key | Action |
|-----|--------|
| `Ctrl+Shift+H/J/K/L` | Navigate windows (vim-style) |
| `Ctrl+Alt+H/J/K/L` | Move windows |
| `Ctrl+Shift+1-9` | Switch workspace |
| `Ctrl+Alt+1-9` | Move to workspace |
| `Ctrl+Shift+/` | Toggle layout |
| `Ctrl+Shift+-/=` | Resize window |
| `Ctrl+Shift+Tab` | Toggle last workspaces |

**App Launchers** (full list in [docs/KEYBINDINGS.md](docs/KEYBINDINGS.md)):
| `Ctrl+Shift+W` | Warp (workspace 1) |
| `Ctrl+Shift+X` | Zen (workspace 2) |
| `Ctrl+Shift+C` | Chrome (workspace 3) |
| `Ctrl+Shift+Z` | Zed (workspace 4) |
| `Ctrl+Shift+O` | Obsidian (workspace 6) |
| `Ctrl+Shift+;` | Service mode (reload, float, join) |

### Ghostty
| Key | Action |
|-----|--------|
| `` Cmd+` `` | Toggle the quick terminal (global: works from any app, drops down from the top) |
| `Cmd+D` / `Cmd+Shift+D` | New split right / down |
| `Cmd+Shift+H/J/K/L` | Focus split left / bottom / top / right |
| `Cmd+Up` / `Cmd+Down` | Jump to previous / next prompt |
| `Cmd+Shift+E` | Write the scrollback to a file and open it in `$EDITOR` |

### Neovim (Leader: `Space`)
| Key | Action |
|-----|--------|
| `<Leader>ff` | Find files |
| `<Leader>fw` | Find word (grep) |
| `<Leader>fb` | Find buffers |
| `<Leader>ha` | Harpoon: add file |
| `Ctrl+H/J/K/L` | Harpoon: jump 1-4 |
| `gd` | Go to definition |
| `gr` | Find references |
| `<Leader>la` | Code actions |
| `K` | Hover docs |

### Zellij
| Key | Action |
|-----|--------|
| `Ctrl+O` | Session mode (rebound from the default pane mode) |
| `Ctrl+G` | Lock (pass-through) |
| `Alt+H/L` | Focus pane left / right, moving to the previous / next tab at the edge |
| `Alt+J/K` | Focus pane down / up |
| `Ctrl+Q` | Quit |

Other modes keep the Zellij defaults (`Ctrl+P` pane, `Ctrl+T` tab, `Ctrl+N` resize, `Ctrl+S` scroll); the status bar shows them.

**Layouts**: `zr` (Rails), `zp` (Phoenix), `zw` (Work) | **Sessions**: `zn <name>` new, `za <name>` attach, `zl` list, `zk <name>` kill | **Tabs**: `zt` new, `zc` close

### Zed Tasks (`Cmd+Shift+P` > "task: spawn")
| Task | Command |
|------|---------|
| `RSpec: Run current file` | `bundle exec rspec $ZED_FILE` |
| `RSpec: Run current line` | `bundle exec rspec $ZED_FILE:$ZED_ROW` |
| `Rails: Server` | `bin/rails server` |
| `Rails: Console` | `bin/rails console` |
| `Rails: Migrate` | `bin/rails db:migrate` |
| `Zig: Build` | `zig build` |
| `Zig: Test current file` | `zig test $ZED_FILE` |
| `Zig: Run current file` | `zig run $ZED_FILE` |

### Zed Snippets (type prefix + Tab)
| Prefix | Expands to | Language |
|--------|-----------|----------|
| `desc` | RSpec describe block | Ruby |
| `ctx` | RSpec context block | Ruby |
| `it` | RSpec it block | Ruby |
| `exp` | RSpec expect | Ruby |
| `let` | RSpec let | Ruby |
| `service` | Service object class | Ruby |
| `pry` | binding.pry | Ruby |
| `memo` | @var \|\|= value | Ruby |
| `er` | `<%= %>` | ERB |
| `eif` | ERB if block | ERB |
| `erp` | ERB render partial | ERB |
| `etf` | turbo_frame_tag | ERB |
| `main` | main() with std import | Zig |
| `test` | test block | Zig |
| `struct` | struct with init | Zig |
| `print` | std.debug.print | Zig |

## 🚀 CLI Aliases (Smart Defaults)

Your shell replaces standard commands with modern alternatives:

| You type | Actually runs | Why |
|----------|--------------|-----|
| `z projects` | zoxide jump | Frecency-based — jumps to the most visited match; `cd` itself stays plain (with `AUTO_CD`, a bare directory name also works) |
| `cdi` | `zi` (zoxide interactive) | Pick directory with fzf |
| `cdd` | `builtin cd` | Original cd, bypassing any alias |
| `ls` | `eza --icons` | Icons + git status + grouped dirs |
| `ll` | `eza --long --git` | Long listing with git info |
| `la` | `eza --long --all --git` | Long listing including hidden files |
| `cat` | `bat --style=auto` | Syntax highlighting + line numbers |
| `grep` | `rg` (ripgrep) | Much faster, respects .gitignore |
| `find` | `fd` | Faster, simpler syntax |
| `vim` / `vi` / `v` | `nvim` | Neovim with AstroNvim |
| `vv` | `nvim .` | Open the current directory in Neovim |
| `lg` | `lazygit` | Full Git TUI |
| `tree` | `eza --tree` | Tree view with icons |
| `Ctrl+R` | atuin | History search backed by atuin's database (fzf keeps `Ctrl+T` files and `Alt+C` cd) |
| `Tab` | fzf-tab | Every completion menu is an fzf picker |

**Original commands**: `cdd`, `lss`, `catt`, `grepp`, `findd`

### System & Python

| Command | What it does |
|---------|-------------|
| `updatebrew` | `brew update && brew upgrade && brew cleanup` |
| `killspring` | Kill every Rails Spring process (`pkill -9 -f spring`) |
| `docker-nuke` | `docker system prune -a --volumes` — removes all unused images, containers and volumes |
| `venv` | Activate `./venv` (`source venv/bin/activate`) |
| `pyserve` | Serve the current directory over HTTP (`python3 -m http.server`) |
| `rails_tree` | `lsd --tree` ignoring `tmp`, `vendors`, `node_modules` |
| `delgems <ruby-version>` | **Destructive**: deletes every gem installed under mise's Ruby `<version>` after a typed `yes` |

### AeroSpace helpers

| Command | What it does |
|---------|-------------|
| `restore-session` | Re-launch the standard workspace layout (`Ctrl+Shift+R` does the same); running apps are focused, not duplicated |
| `ws` | List open windows as `workspace  app-name` |
| `ws-ids` | Same list with bundle ids, to paste into `aerospace.toml` |

### Development Services & Logging

| Command | What it does |
|---------|-------------|
| `devstart` | Start Redis, PostgreSQL, Mailcatcher |
| `devstop` | Stop all development services |
| `sq` | Sidekiq queue status (default, mailers, scheduled, retries, dead) |
| `logtail` | `tail -f` on Rails development log |
| `logclear` | Truncate all log files |
| `logview` | Open Rails log in lnav (SQL-queryable log viewer) |
| `logspin` | Tail Rails log with tailspin (auto-highlights dates, UUIDs, IPs, JSON) |

### Git Smart Defaults

These are configured automatically by `install.sh`:

| Feature | What it does |
|---------|-------------|
| `push.autoSetupRemote` | No more `git push -u origin branch` — just `git push` |
| `rerere.enabled` | Auto-resolves repeated merge conflicts |
| `diff.algorithm histogram` | Better diffs for moved code blocks |
| `branch.sort -committerdate` | `git branch` shows most recent first |
| `commit.verbose` | See the full diff while writing commit messages |
| `merge.tool nvimdiff` | Use Neovim for 3-way merge conflict resolution |
| `merge.conflictstyle diff3` | Show base, ours, and theirs in merge conflicts |

**Git shortcuts** (`ga`, `gc`, `gco`, `gb`, `gp`, `gl`, `gd`, `gdc`, `gclean` from `.zshrc-dhh-additions`, plus these from `.zshrc`):

| Alias | Runs |
|-------|------|
| `gst` | `git status` |
| `gcm` | `git commit -m` |
| `gcane` | `git commit --amend --no-edit` |
| `gstash` / `gpop` | `git stash` / `git stash pop` |
| `glog` | `git log --graph` in fzf with a `git show` preview; `Ctrl+Y` copies the hash |

### SSH Setup

Configured during install — supports GitHub, GitLab, Bitbucket, Codeberg, Gerrit, and self-hosted Git:

| Command | What it does |
|---------|-------------|
| `ssh -T git@github.com` | Test personal GitHub connection |
| `ssh -T git@github.com-work` | Test work GitHub (if aliased) |
| `ssh -T git@gitlab.com` | Test GitLab connection |
| `ssh -vT git@github.com` | Debug connection (verbose) |
| `ssh -G github.com \| grep identityfile` | Check which key SSH will use |
| `ssh-add -l` | List keys loaded in agent |
| `ssh-add --apple-use-keychain ~/.ssh/key` | Add key to macOS Keychain |

**Using aliases** (e.g., `github.com-work`):
```bash
git clone git@github.com-work:company/repo.git
git remote set-url origin git@github.com-work:company/repo.git
```

**Restore old SSH keys:** `cp -r ~/.dotfiles_backup_*/ssh/ ~/.ssh/`

### 1Password SSH Agent — Touch ID for Git

If you chose 1Password during install, every new terminal session requires Touch ID before SSH operations (push, pull, clone).

**Recommended settings** (1Password → Settings → Developer → SSH Agent → Advanced):

| Setting | Recommended | Effect |
|---------|------------|--------|
| Ask approval for each new | `application and terminal session` | Per-tab, not global |
| Remember key approval | `until 1Password locks` | Expires on lock |

**Recommended** (1Password → Settings → Security):

| Setting | Recommended | Effect |
|---------|------------|--------|
| Lock when device locks or sleeps | ✅ enabled | Locks with your Mac |
| Lock after device is idle for | `1 minute` | Short timeout = frequent re-auth |

**Important:** approval is per-session, not per-push. Once approved in a terminal tab, subsequent pushes go through until 1Password locks. A shorter auto-lock timeout means more frequent biometric prompts.

**Manual setup** (if you didn't choose 1Password during install):
```bash
# 1. Enable SSH Agent in 1Password → Settings → Developer
# 2. Create the socket symlink:
mkdir -p ~/.1password
ln -sf ~/Library/Group\ Containers/2BUA8C4S2C.com.1password/t/agent.sock ~/.1password/agent.sock

# 3. Add to ~/.ssh/config:
# Host *
#     IdentityAgent ~/.1password/agent.sock

# 4. Test:
ssh -T git@github.com
```

## 💼 Work Identity Management

| Command | What it does |
|---------|-------------|
| `work-setup` | Configure work email, directory, SSH, shell config, clone repos |
| `work-status` | Show current work identity, SSH hosts, dirty repos |
| `work-nuke` | Remove all work config (with backup + confirmation) |
| `work-nuke --dry-run` | Preview what would be removed |
| `work-switch` | Change employer (nuke old + setup new) |
| `repos-clone` | Interactive repo cloner (GitHub/GitLab/Bitbucket/Codeberg) |
| `repos-clone --dir ~/work --org mycompany` | Clone with presets |
| `repos-clone --all` | Clone all repos without selection prompt |

The same scripts route through the CLI as `dotfiles work setup`, `dotfiles work status`, `dotfiles work nuke`, `dotfiles work switch` and `dotfiles repos clone`.

## 🛠️ Common Tasks

### Git Workflow

```bash
gwa feature-x          # worktree + branch beside the repo (<repo>--feature-x), mise-trusted, cd into it
gwr                    # remove the worktree you are in and its branch (asks first)
compress dir           # dir.tar.gz          decompress dir.tar.gz
fip nyc-dev 3000       # localhost:3000 -> nyc-dev:3000 over SSH; dip 3000 stops it; lip lists forwards
```
```bash
# Stage and commit
lazygit  # or 'lg' alias

# Create PR
gh pr create

# View PR
gh pr view --web
```

### Rails Development
```bash
# In Neovim
<Leader>rc  # Go to controller
<Leader>rm  # Go to model
<Leader>rv  # Go to view
<Leader>rs  # Go to spec
<Leader>ra  # Alternate file

# In Zellij (Rails layout)
zr          # Spawn rails layout: editor + server + console + tests
```

### Elixir/Phoenix Development
```bash
# In Zellij (Phoenix layout)
zp          # Spawn phoenix layout: editor + server + iex + tests

# In Neovim
<Leader>ff  # Find files
<Leader>fw  # Find in files
```

### Package Management
```bash
# Homebrew
brew update && brew upgrade
brew bundle install  # Install from Brewfile

# Neovim plugins
nvim
:Lazy sync

# llm plugins (one-time, after fresh install)
llm install llm-ollama       # Already wired by install.sh step 7b
llm install llm-anthropic    # Optional
```

### AI Shell Tooling
```bash
# Pipe text through an LLM (defaults to local qwen2.5-coder:7b via ollama)
cat error.log | llm "explain this"
git diff --staged | llm -s "write a conventional-commit message"
llm -m gpt-4o "switch model per call"      # needs OPENAI_API_KEY or `llm keys set openai`
llm -c "continue last conversation"
llm logs                                    # browse history

# GitHub Copilot CLI (built into gh ≥ 2.49)
ghcs "find files larger than 100MB"        # suggest a command
ghce "git rebase -i HEAD~5"                # explain a command

# Local LLM management
ollama list                                 # what's downloaded
ollama pull qwen3:14b                       # add a heavier model
ollama run qwen2.5-coder:7b "..."           # direct invoke (rare; prefer `llm`)

# Custom helper
explain-last                                # explain the last shell command via llm

# Coding agents
a                                           # launch the default agent (claude unless `dotfiles default agent <name>` says otherwise)
oclaude                                     # Claude Code through Ollama, default model glm-5.2:cloud, --permission-mode auto
oclaude -m kimi-k3:cloud                    # pick a model; bare `-m` lists cloud + local models and asks
oq "explain SIGPIPE"                        # local qwen3.8:27b via `ollama run`, thinking off for speed
```

## 🔧 Environment

| Setting | What it does |
|---------|-------------|
| `RUBY_YJIT_ENABLE=1` | Enables YJIT JIT compiler for Ruby 3.1+ (significant performance boost) |
| `~/.zshrc.local` | Machine-specific overrides — sourced last, never committed to git |
| `PROJECTS_DIR` / `WORK_DIR` | Where personal (`~/code`) and work (`~/work/code`) projects live; the `work-*` helpers use `WORK_DIR` |
| `DOTFILES_CODE_DIRS` | Space-separated directories `dotfiles health` scans for mise toolchain drift (default: `~/code ~/work/code`) |
| `DOTFILES_THEME_DIR` | Where `dotfiles theme` renders app configs (`~/.local/state/dotfiles/current/theme`); starship, lazygit and others read from it |
| `RAILS_TEMPLATES_DIR` | Your `.rubocop.yml` / `lefthook.yml` / `ci.yml` templates for `rails-setup-*` (not shipped; set it in `~/.zshrc.local`) |
| `OLLAMA_MAX_LOADED_MODELS=1` / `OLLAMA_KEEP_ALIVE=24h` | One model resident at a time (36 GB cannot hold two large ones), kept loaded for a day |
| `DOTFILES_UPDATE_UNATTENDED=1` | Exported by `dotfiles update --yes`; hooks and migrations read it to skip their own prompts |
| `DOTFILES_NO_APPEARANCE=1` | Stops `dotfiles theme` switching macOS light/dark mode (tests, CI); `dotfiles toggle appearance off` is the persistent form |

**Update notice**: once a day the shell runs a detached fetch and, when commits, brew upgrades, migrations or restarts are waiting, prints a yellow `dotfiles: ...` line at login. `dotfiles update available` shows the detail; `dotfiles toggle update-notice off` silences it.

## 🔧 Troubleshooting

### Reload Configurations
```bash
# Shell
source ~/.zshrc

# Zellij — kill + relaunch session (no live-reload yet)
zellij kill-all-sessions && zellij

# Aerospace
aerospace reload

# Neovim
:source ~/.config/nvim/init.lua
```

### Installing Legacy Ruby (< 2.4)

Old Ruby versions need OpenSSL 1.1 (modern Ruby uses OpenSSL 3.x automatically). Pass it as a one-off build flag — don't add it to your shell config:

```bash
# Install openssl@1.1 if you don't have it
brew install openssl@1.1

# Compile old Ruby with OpenSSL 1.1
RUBY_CONFIGURE_OPTS="--with-openssl-dir=$(brew --prefix openssl@1.1)" mise install ruby@2.x.x
```

If you work with legacy projects frequently, add it to `~/.zshrc.local`:
```bash
export RUBY_CONFIGURE_OPTS="--with-openssl-dir=$(brew --prefix openssl@1.1)"
```
Note: this adds ~0.9s to every shell startup due to the `brew --prefix` call.

### Reset Everything
```bash
# Neovim
rm -rf ~/.local/share/nvim ~/.cache/nvim

# Zellij sessions
zellij kill-all-sessions

# Shell
source ~/.zshrc
```

## 📊 System Info

```bash
# Check versions
nvim --version
zellij --version
starship --version
llm --version
ollama --version
aerospace --version

# Check Homebrew packages
brew list
```

## 🎨 Theme Colors

Run `dotfiles theme preview` for the active palette as swatches, or `dotfiles theme preview <name>` for any other theme; `--no-color` prints plain `key #hex` lines. The source of truth is `themes/<name>/colors.toml`.

---

**Print this out or keep it handy!** 📎
