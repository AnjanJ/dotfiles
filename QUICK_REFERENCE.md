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
dotfiles update       # Upgrade system & sync repo
dotfiles sync         # Quick refresh: pull, relink, reapply theme
dotfiles health       # Verify all tools are installed
dotfiles theme aura   # Switch theme (tokyo-night | aura | catppuccin)
dotfiles add-theme x  # Scaffold a new theme directory
dotfiles cleanup      # Find/remove unlisted Homebrew packages (--force)
dotfiles doctor       # Auto-fix common issues
dotfiles backup       # Snapshot dotfiles state (--list, --restore)
dotfiles profile      # Measure shell startup time (--detailed)
dotfiles export       # Export setup snapshot (--json)
dotfiles toggle <f>   # Flip startup-apps / borders / auto-commit
dotfiles keys         # AeroSpace keybinding cheatsheet (fzf)
dotfiles commands     # List every command
dotfiles install      # Re-run full installer
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
| `Ctrl+O` | Enter mode |
| `Ctrl+G` | Lock (pass-through) |
| `Alt+H/J/K/L` | Navigate panes |
| `Ctrl+Q` | Quit |

**Layouts**: `zr` (Rails), `zp` (Phoenix), `zw` (Work)

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
| `cd projects` | `z projects` (zoxide) | Frecency-based — jumps to most visited match |
| `cdi` | `zi` (zoxide interactive) | Pick directory with fzf |
| `cdd` | `builtin cd` | Original cd when you need exact paths |
| `ls` | `eza --icons` | Icons + git status + grouped dirs |
| `ll` | `eza --long --git` | Long listing with git info |
| `la` | `eza --long --all --git` | Long listing including hidden files |
| `cat` | `bat --style=auto` | Syntax highlighting + line numbers |
| `grep` | `rg` (ripgrep) | Much faster, respects .gitignore |
| `find` | `fd` | Faster, simpler syntax |
| `vim` / `vi` / `v` | `nvim` | Neovim with AstroNvim |
| `lg` | `lazygit` | Full Git TUI |
| `tree` | `eza --tree` | Tree view with icons |

**Original commands**: `cdd`, `lss`, `catt`, `grepp`, `findd`

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

## 🛠️ Common Tasks

### Git Workflow
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
```

## 🔧 Environment

| Setting | What it does |
|---------|-------------|
| `RUBY_YJIT_ENABLE=1` | Enables YJIT JIT compiler for Ruby 3.1+ (significant performance boost) |
| `~/.zshrc.local` | Machine-specific overrides — sourced last, never committed to git |

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

## 🎨 Theme Colors (Tokyo Night)

| Element | Hex |
|---------|-----|
| Background | `#1a1b26` |
| Foreground | `#c0caf5` |
| Blue | `#7aa2f7` |
| Cyan | `#7dcfff` |
| Purple | `#bb9af7` |
| Green | `#9ece6a` |
| Red | `#f7768e` |
| Yellow | `#e0af68` |

---

**Print this out or keep it handy!** 📎
