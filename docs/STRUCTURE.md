# Repository Structure

## Layout

```
dotfiles/
├── install.sh                  # Main installation script (idempotent)
├── update.sh                   # Update script for syncing changes
├── Brewfile                    # Homebrew packages, organized into @group sections
├── README.md                   # Front page
├── QUICK_REFERENCE.md          # Printable cheat sheet
├── .zshrc                      # Main shell config
├── .zshrc-dhh-additions        # Rails workflows
├── .zshrc-elixir-additions     # Elixir/Phoenix
├── .zshrc-terminal-enhancements # Terminal tools, shell UX, AI tooling
├── .zshrc-work-completions     # Work command tab-completion
├── .gitignore_global           # Global git ignores
├── .rubocop.yml                # Global RuboCop config (fallback for standalone Ruby files)
├── .config/
│   ├── aerospace/              # Window manager: layouts, keybindings
│   ├── ghostty/                # Terminal: theme, fonts
│   ├── alacritty/              # Alternate terminal
│   ├── wezterm/                # Alternate terminal (linked as ~/.wezterm.lua)
│   ├── mise/                   # Version manager (Ruby pinned; Node/Elixir/Go/etc. latest)
│   ├── nvim/                   # Neovim config (AstroNvim)
│   ├── zed/                    # Zed: settings.json, tasks.json, snippets/
│   ├── zellij/                 # Multiplexer: config, theme, layouts (rails, phoenix, work)
│   ├── lazygit/                # Git UI: config + theme
│   ├── borders/                # JankyBorders: active window highlighting
│   ├── sketchybar/             # Menu bar: config + plugins
│   └── starship.toml           # Prompt: git, languages, colors
├── themes/                     # Theme assets — see docs/THEMES.md
│   ├── tokyo-night/
│   ├── aura/
│   └── catppuccin/
├── bin/                        # CLI commands, linked file-by-file into ~/bin
│   ├── dotfiles                # Main CLI dispatcher (update, sync, health, theme, ...)
│   ├── dotfiles-*              # Subcommand implementations
│   ├── work-setup / work-nuke / work-switch / work-status
│   ├── repos-clone             # Clone from GitHub/GitLab/Bitbucket/Codeberg
│   ├── erb-lint-formatter      # ERB lint wrapper for Zed
│   ├── rubocop-auto            # RuboCop wrapper: bundle exec inside apps, global gem otherwise
│   └── _work-helpers           # Shared utilities for work scripts
├── scripts/
│   ├── _helpers.sh             # Shared colors & print functions
│   ├── symlink-map.sh          # SINGLE SOURCE OF TRUTH for every managed symlink
│   ├── setup-git.sh            # Git identity & defaults setup
│   ├── setup-ssh.sh            # SSH key & config setup
│   ├── health-check.sh         # Verify installation (sweeps the symlink map)
│   ├── theme-utils.sh          # Theme utility functions
│   └── apply-theme.sh          # Apply theme across all apps
├── tests/                      # 11 suites, run via GitHub Actions CI
├── .github/workflows/test.yml  # CI: shellcheck + all test suites
└── docs/                       # This documentation
```

## The symlink map

Every symlink this repo manages is declared once, in `scripts/symlink-map.sh`. Install, update, sync, doctor, and health all iterate the same map — so adding a managed file is one entry, and a file that exists in the repo but was never linked on the machine fails `dotfiles health` loudly instead of passing silently.

## Modular shell setup

The `.zshrc` is organized into focused, modular files:

```
~/.zshrc                         # Core: prompt, PATH, tool initialization
~/.zshrc-dhh-additions           # DHH-inspired Rails workflows
~/.zshrc-elixir-additions        # Elixir/Phoenix tools
~/.zshrc-terminal-enhancements   # Zellij + Neovim aliases, fzf-tab, autosuggestions, AI tooling
~/.zshrc-work                    # Work-specific settings (created by work-setup, not in repo)
```

**Why modular?** Each file has a single responsibility. Want to change your Rails workflow? Edit `.zshrc-dhh-additions`. Need different terminal aliases? Modify `.zshrc-terminal-enhancements`. Enable/disable a whole area by commenting one line in `.zshrc`.

## Language versions (mise)

`mise` replaces rbenv/nvm/asdf. The global tool list lives in `.config/mise/config.toml` — Ruby is pinned to a specific version, the rest track `latest`. Idiomatic version files (`.ruby-version`, `.nvmrc`) are honored for **node and ruby** via `idiomatic_version_file_enable_tools`; projects can also pin any tool with their own `mise.toml`, which always takes precedence.

## Ruby formatting everywhere

Zed's Ruby formatter runs `bin/rubocop-auto`: inside an app whose Gemfile carries RuboCop it uses `bundle exec rubocop` (respecting the project's pinned version and config); for standalone `.rb` files it falls back to the global RuboCop from mise's Ruby, with `~/.rubocop.yml` (tracked here) as the fallback config. Format-on-save works in any Ruby file, Gemfile or not.

## Customizing

- **Zed**: `.config/zed/settings.json` (languages, LSP, formatters), `tasks.json` (RSpec, Rails, Elixir, Zig, npm tasks), `snippets/`
- **Keybindings**: see [KEYBINDINGS.md](KEYBINDINGS.md)
- **Packages**: edit `Brewfile`, then `brew bundle install`
- **Themes**: see [THEMES.md](THEMES.md)
