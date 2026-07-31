# Package Catalog

> Every package `install.sh` installs, grouped exactly as in the [Brewfile](../Brewfile).

**Descriptions and links are machine-generated from authoritative sources, not written by hand:**

| Type | Source |
|---|---|
| Formulae / casks | `brew info --json=v2` (Homebrew's own `desc` + `homepage`) |
| VS Code extensions | each extension's local `package.json` manifest |
| App Store apps | Apple iTunes Lookup API (`trackName`, `sellerName`, `trackViewUrl`) |
| Taps | Which packages in *this* Brewfile each tap supplies, resolved from install receipts |
| Fonts | Whether the font is referenced by a config here, with the file:line that names it |

Homebrew ships no description for taps or font casks, so those two columns state something
more useful instead: what the tap actually gives you, and whether a font is really in use.
Taps flagged **REDUNDANT** supply nothing you use — their formulae moved into homebrew/core.

Regenerate after editing the Brewfile: `python3 scripts/catalog/build-catalog.py` · last built 2026-08-01

## Contents

- [Taps](#taps) — 5
- [Core CLI](#core-cli) — 20
- [Editors & Terminals](#editors--terminals) — 6
- [Window Management](#window-management) — 3
- [Terminal Tools](#terminal-tools) — 15
- [AI Tooling](#ai-tooling) — 7
- [Databases](#databases) — 11
- [Cloud & Deploy](#cloud--deploy) — 4
- [Media](#media) — 8
- [Communication](#communication) — 4
- [Productivity](#productivity) — 15
- [Work](#work) — 2
- [Languages](#languages) — 5
- [Browsers](#browsers) — 4
- [Utilities](#utilities) — 20
- [Extras](#extras) — 3
- [Fonts](#fonts) — 8
- [VS Code Extensions](#vs-code-extensions) — 27

## Taps

`@group taps` · 5 entries

> Always installed — cannot be deselected.

| Package | What it is | Learn more |
|---|---|---|
| `antoniorodr/memo` | Supplies `memo` (Apple Notes/Reminders CLI) | [docs](https://github.com/antoniorodr/homebrew-memo) |
| `nikitabobko/tap` | Supplies the `aerospace` cask (tiling window manager) | [docs](https://github.com/nikitabobko/homebrew-tap) |
| `steipete/tap` | Peter Steinberger's macOS CLIs — supplies `bird`, `gifgrep`, `imsg`, `peekaboo`, `remindctl`, `sag`, `songsee` | [docs](https://github.com/steipete/homebrew-tap) |
| `yakitrak/yakitrak` | Supplies `obsidian-cli` (drive Obsidian from the shell) | [docs](https://github.com/yakitrak/homebrew-yakitrak) |
| `felixkratz/formulae` | Supplies `sketchybar` (menu bar) and `borders` (window highlights) | [docs](https://github.com/felixkratz/homebrew-formulae) |

## Core CLI

`@group core` · 20 entries

> Always installed — cannot be deselected.

| Package | What it is | Learn more |
|---|---|---|
| `atuin` | Improved shell history for zsh, bash, fish and nushell | [docs](https://atuin.sh/) |
| `bat` | Clone of cat(1) with syntax highlighting and Git integration | [docs](https://github.com/sharkdp/bat) |
| `direnv` | Load/unload environment variables based on $PWD | [docs](https://direnv.net/) |
| `eza` | Modern, maintained replacement for ls | [docs](https://eza.rocks) |
| `fd` | Simple, fast and user-friendly alternative to find | [docs](https://github.com/sharkdp/fd) |
| `fzf` | Command-line fuzzy finder written in Go | [docs](https://junegunn.github.io/fzf/) |
| `fzf-tab` | Replace zsh completion selection menu with fzf | [docs](https://github.com/Aloxaf/fzf-tab) |
| `gh` | GitHub command-line tool | [docs](https://cli.github.com/) |
| `git` | Distributed revision control system | [docs](https://git-scm.com) |
| `jq` | Lightweight and flexible command-line JSON processor | [docs](https://jqlang.github.io/jq/) |
| `mas` | Mac App Store command-line interface | [docs](https://github.com/mas-cli/mas) |
| `mise` | Polyglot runtime manager (asdf rust clone) | [docs](https://mise.jdx.dev/) |
| `ripgrep` | Search tool like grep and The Silver Searcher | [docs](https://github.com/BurntSushi/ripgrep) |
| `shellcheck` | Static analysis and lint tool, for (ba)sh scripts | [docs](https://www.shellcheck.net/) |
| `starship` | Cross-shell prompt for astronauts | [docs](https://starship.rs/) |
| `tree` | Display directories as trees (with optional color/HTML output) | [docs](https://oldmanprogrammer.net/source.php?dir=projects/tree) |
| `wget` | Internet file retriever | [docs](https://www.gnu.org/software/wget/) |
| `zoxide` | Shell extension to navigate your filesystem faster | [docs](https://github.com/ajeetdsouza/zoxide) |
| `zsh-autosuggestions` | Fish-like fast/unobtrusive autosuggestions for zsh | [docs](https://github.com/zsh-users/zsh-autosuggestions) |
| `zsh-syntax-highlighting` | Fish shell like syntax highlighting for zsh | [docs](https://github.com/zsh-users/zsh-syntax-highlighting) |

## Editors & Terminals

`@group editors` · 6 entries

| Package | What it is | Learn more |
|---|---|---|
| `neovim` | Ambitious Vim-fork focused on extensibility and agility | [docs](https://neovim.io/) |
| `ghostty` | Terminal emulator that uses platform-native UI and GPU acceleration | [docs](https://ghostty.org/) |
| `visual-studio-code` | Open-source code editor | [docs](https://code.visualstudio.com/) |
| `wezterm` | GPU-accelerated cross-platform terminal emulator and multiplexer | [docs](https://wezterm.org/) |
| `zed` | Multiplayer code editor | [docs](https://zed.dev/) |
| `warp` | Rust-based terminal | [docs](https://www.warp.dev/) |

## Window Management

`@group window-mgmt` · 3 entries

| Package | What it is | Learn more |
|---|---|---|
| `aerospace` | AeroSpace is an i3-like tiling window manager for macOS | [docs](https://github.com/nikitabobko/AeroSpace) |
| `sketchybar` |  |  |
| `borders` |  |  |

## Terminal Tools

`@group terminal-tools` · 15 entries

| Package | What it is | Learn more |
|---|---|---|
| `cliclick` | Tool for emulating mouse and keyboard events | [docs](https://www.bluem.net/jump/cliclick/) |
| `git-delta` | Syntax-highlighting pager for git and diff output | [docs](https://dandavison.github.io/delta/) |
| `grip` | GitHub Markdown previewer | [docs](https://github.com/joeyespo/grip) |
| `httpie` | User-friendly cURL replacement (command-line HTTP client) | [docs](https://httpie.io/) |
| `lazydocker` | Lazier way to manage everything docker | [docs](https://github.com/jesseduffield/lazydocker) |
| `lazygit` | Simple terminal UI for git commands | [docs](https://github.com/jesseduffield/lazygit/) |
| `lnav` | Curses-based tool for viewing and analyzing log files | [docs](https://lnav.org/) |
| `lsd` | Clone of ls with colorful output, file type icons, and more | [docs](https://github.com/lsd-rs/lsd) |
| `mole` | Deep clean and optimize your Mac | [docs](https://mole.fit) |
| `pandoc` | Swiss-army knife of markup format conversion | [docs](https://pandoc.org/) |
| `tailspin` | Log file highlighter | [docs](https://github.com/bensadeh/tailspin) |
| `tlrc` | Official tldr client written in Rust | [docs](https://tldr.sh/tlrc/) |
| `unar` | Command-line unarchiving tools supporting multiple formats | [docs](https://theunarchiver.com/command-line) |
| `weasyprint` | Convert HTML to PDF | [docs](https://www.courtbouillon.org/weasyprint) |
| `zellij` | Pluggable terminal workspace, with terminal multiplexer as the base feature | [docs](https://zellij.dev) |

## AI Tooling

`@group ai` · 7 entries

| Package | What it is | Learn more |
|---|---|---|
| `gemini-cli` | Interact with Google Gemini AI models from the command-line | [docs](https://geminicli.com) |
| `llm` | Access large language models from the command-line | [docs](https://llm.datasette.io/) |
| `summarize` | Multi-modal AI tool to extract and summarize content | [docs](https://summarize.sh) |
| `chatgpt` | OpenAI's official ChatGPT desktop app | [docs](https://chatgpt.com/) |
| `claude` | Anthropic's official Claude AI desktop app | [docs](https://claude.com/download) |
| `claude-code@latest` | Terminal-based AI coding assistant | [docs](https://claude.com/product/claude-code) |
| `ollama-app` | Get up and running with large language models locally | [docs](https://ollama.com/) |

## Databases

`@group databases` · 11 entries

| Package | What it is | Learn more |
|---|---|---|
| `lazysql` | Cross-platform TUI database management tool | [docs](https://github.com/jorgerojas26/lazysql) |
| `litecli` | CLI for SQLite Databases with auto-completion and syntax highlighting | [docs](https://litecli.com) |
| `mycli` | CLI for MySQL with auto-completion and syntax highlighting | [docs](https://www.mycli.net/) |
| `mysql` | Open source relational database management system | [docs](https://github.com/mysql/mysql-server) |
| `pgcli` | CLI for Postgres with auto-completion and syntax highlighting | [docs](https://pgcli.com/) |
| `pgvector` | Open-source vector similarity search for Postgres | [docs](https://github.com/pgvector/pgvector) |
| `postgresql@16` | Object-relational database system | [docs](https://www.postgresql.org/) |
| `redis` | Persistent key-value database, with built-in net interface | [docs](https://redis.io/) |
| `beekeeper-studio` | Cross platform SQL editor and database management app | [docs](https://www.beekeeperstudio.io/) |
| `postico` | GUI client for PostgreSQL databases | [docs](https://eggerapps.at/postico2/) |
| `redis-insight` | GUI for streamlined Redis application development | [docs](https://redis.io/insight/) |

## Cloud & Deploy

`@group cloud-deploy` · 4 entries

| Package | What it is | Learn more |
|---|---|---|
| `docker` | Pack, ship and run any application as a lightweight container | [docs](https://www.docker.com/) |
| `render` | Command-line interface for Render | [docs](https://render.com/docs/cli) |
| `supabase` | Postgres development platform | [docs](https://supabase.com/docs/reference/cli/about) |
| `docker-desktop` | App to build and share containerised applications and microservices | [docs](https://www.docker.com/products/docker-desktop) |

## Media

`@group media` · 8 entries

| Package | What it is | Learn more |
|---|---|---|
| `ffmpeg-full` | Play, record, convert, and stream many audio and video codecs | [docs](https://ffmpeg.org/) |
| `imagemagick-full` | Tools and libraries to manipulate images in many formats | [docs](https://imagemagick.org) |
| `librsvg` | Library to render SVG files using Cairo | [docs](https://wiki.gnome.org/Projects/LibRsvg) |
| `poppler` | PDF rendering library (based on the xpdf-3.0 code base) | [docs](https://poppler.freedesktop.org/) |
| `yt-dlp` | Feature-rich command-line audio/video downloader | [docs](https://github.com/yt-dlp/yt-dlp) |
| `vlc` | Multimedia player | [docs](https://www.videolan.org/vlc/) |
| `Gifski` | Gifski — by Sindre Sorhus | [docs](https://apps.apple.com/in/app/gifski/id1351639930?mt=12&uo=4) |
| `GIPHY CAPTURE` | GIPHY Capture. The GIF Maker — by Giphy, Inc. | [docs](https://apps.apple.com/in/app/giphy-capture-the-gif-maker/id668208984?mt=12&uo=4) |

## Communication

`@group communication` · 4 entries

| Package | What it is | Learn more |
|---|---|---|
| `discord` | Voice and text chat software | [docs](https://discord.com/) |
| `signal` | Instant messaging application focusing on security | [docs](https://signal.org/) |
| `telegram` | Messaging app with a focus on speed and security | [docs](https://macos.telegram.org/) |
| `WhatsApp` | WhatsApp Messenger — by WhatsApp Inc. | [docs](https://apps.apple.com/in/app/whatsapp-messenger/id310633997?uo=4) |

## Productivity

`@group productivity` · 15 entries

| Package | What it is | Learn more |
|---|---|---|
| `antoniorodr/memo/memo` | CLI app to manage your Apple Notes and Apple reminders | [docs](https://github.com/antoniorodr/memo) |
| `yakitrak/yakitrak/obsidian-cli` | CLI to open, search, move, create, delete and update Obsidian notes | [docs](https://github.com/Yakitrak/obsidian-cli) |
| `steipete/tap/remindctl` | Fast CLI for Apple Reminders | [docs](https://github.com/steipete/remindctl) |
| `1password` | Password manager that keeps all passwords secure behind one password | [docs](https://1password.com/) |
| `1password-cli` | Command-line interface for 1Password | [docs](https://developer.1password.com/docs/cli) |
| `notion` | App to write, plan, collaborate, and get organised | [docs](https://www.notion.com/) |
| `obsidian` | Knowledge base that works on top of a local folder of plain text Markdown files | [docs](https://obsidian.md/) |
| `proton-mail` | Client for Proton Mail and Proton Calendar | [docs](https://proton.me/mail) |
| `protonvpn` | VPN client focusing on security | [docs](https://protonvpn.com/) |
| `proton-pass` | Desktop client for Proton Pass | [docs](https://proton.me/pass) |
| `Dashlane` | Dashlane Password Manager — by Dashlane | [docs](https://apps.apple.com/in/app/dashlane-password-manager/id517914548?uo=4) |
| `1Password for Safari` | 1Password for Safari — by AgileBits Inc. | [docs](https://apps.apple.com/in/app/1password-for-safari/id1569813296?mt=12&uo=4) |
| `2FAS - Two Factor Authentication` | 2FAS Auth Browser Extension — by Two Factor Authentication Service, Inc. | [docs](https://apps.apple.com/in/app/2fas-auth-browser-extension/id6443941139?mt=12&uo=4) |
| `Tailscale` | Tailscale — by Tailscale Inc. | [docs](https://apps.apple.com/in/app/tailscale/id1475387142?mt=12&uo=4) |
| `TextSniper` | TextSniper — by Valerijs Boguckis | [docs](https://apps.apple.com/in/app/textsniper/id1528890965?mt=12&uo=4) |

## Work

`@group work` · 2 entries

| Package | What it is | Learn more |
|---|---|---|
| `slack` | Team communication and collaboration software | [docs](https://slack.com/) |
| `zoom` | Video communication and virtual meeting platform | [docs](https://www.zoom.us/) |

## Languages

`@group languages` · 5 entries

| Package | What it is | Learn more |
|---|---|---|
| `cargo-nextest` | Next-generation test runner for Rust | [docs](https://nexte.st) |
| `uv` | Extremely fast Python package installer and resolver, written in Rust | [docs](https://docs.astral.sh/uv/) |
| `zig` | Programming language designed for robustness, optimality, and clarity | [docs](https://ziglang.org/) |
| `android-commandlinetools` | Command-line tools for building and debugging Android apps | [docs](https://developer.android.com/studio) |
| `flutter` | UI toolkit for building applications for mobile, web and desktop | [docs](https://flutter.dev/) |

## Browsers

`@group browsers` · 4 entries

| Package | What it is | Learn more |
|---|---|---|
| `firefox` | Web browser | [docs](https://www.mozilla.org/firefox/) |
| `google-chrome` | Web browser | [docs](https://www.google.com/chrome/) |
| `zen` | Gecko based web browser | [docs](https://zen-browser.app/) |
| `DuckDuckGo` | DuckDuckGo, optional Duck.ai — by Duck Duck Go, Inc. | [docs](https://apps.apple.com/in/app/duckduckgo-optional-duck-ai/id663592361?uo=4) |

## Utilities

`@group utilities` · 20 entries

| Package | What it is | Learn more |
|---|---|---|
| `balenaetcher` | Tool to flash OS images to SD cards & USB drives | [docs](https://balena.io/etcher) |
| `calibre` | E-books management software | [docs](https://calibre-ebook.com/) |
| `libreoffice` | Free cross-platform office suite, fresh version | [docs](https://www.libreoffice.org/) |
| `raspberry-pi-imager` | Imaging utility to install operating systems to a microSD card | [docs](https://www.raspberrypi.com/software/) |
| `stremio` | Open-source media center | [docs](https://www.strem.io/) |
| `thorium` | Epub reader | [docs](https://www.edrlab.org/software/thorium-reader/) |
| `tuta-mail` | Email client | [docs](https://tuta.com/) |
| `Bandwidth+` | Bandwidth+ — by Harold Chu | [docs](https://apps.apple.com/in/app/bandwidth/id490461369?mt=12&uo=4) |
| `Developer` | Apple Developer — by Apple Distribution International | [docs](https://apps.apple.com/in/app/apple-developer/id640199958?uo=4) |
| `Hidden Bar` | Hidden Bar — by Dwarves Foundation Company Limited | [docs](https://apps.apple.com/in/app/hidden-bar/id1452453066?mt=12&uo=4) |
| `iStat Menus 7` | iStat Menus 7 — by Bjango Pty Ltd | [docs](https://apps.apple.com/app/id6499559693) |
| `Kindle` | Amazon Kindle: Reading App — by AMAZON SELLER SERVICES PRIVATE LIMITED | [docs](https://apps.apple.com/in/app/amazon-kindle-reading-app/id302584613?uo=4) |
| `LanguageTool` | LanguageTool - Grammar Checker — by LanguageTooler GmbH | [docs](https://apps.apple.com/in/app/languagetool-grammar-checker/id1534275760?uo=4) |
| `LocalSend` | LocalSend — by Tien Do Nam | [docs](https://apps.apple.com/in/app/localsend/id1661733229?uo=4) |
| `Menu Bar Calendar` | Menu Bar Calendar — by Sindre Sorhus | [docs](https://apps.apple.com/in/app/menu-bar-calendar/id1558360383?mt=12&uo=4) |
| `Noir` | Noir – Dark Mode for Safari — by Jeffrey Kuiken | [docs](https://apps.apple.com/in/app/noir-dark-mode-for-safari/id1592917505?mt=12&uo=4) |
| `Numbers` | Numbers — by Apple | [docs](https://apps.apple.com/app/id361304891) |
| `Save to Raindrop.io` | Save to Raindrop.io — by Rustem Mussabekov | [docs](https://apps.apple.com/in/app/save-to-raindrop-io/id1549370672?mt=12&uo=4) |
| `Tot` | Tot — by The Iconfactory | [docs](https://apps.apple.com/in/app/tot/id1491071483?mt=12&uo=4) |
| `Xcode` | Xcode — by Apple Distribution International | [docs](https://apps.apple.com/in/app/xcode/id497799835?mt=12&uo=4) |

## Extras

`@group extras` · 3 entries

| Package | What it is | Learn more |
|---|---|---|
| `steipete/tap/gifgrep` | Grep the GIF. Stick the landing | [docs](https://github.com/steipete/gifgrep) |
| `steipete/tap/peekaboo` | Lightning-fast macOS screenshots & AI vision analysis | [docs](https://github.com/openclaw/Peekaboo) |
| `libyaml` | YAML Parser | [docs](https://github.com/yaml/libyaml) |

## Fonts

`@group fonts` · 8 entries

| Package | What it is | Learn more |
|---|---|---|
| `font-fira-code` | **IN USE** — Ghostty (`.config/ghostty/config`) and Zed buffer font | [docs](https://github.com/tonsky/FiraCode) |
| `font-fira-code-nerd-font` | **IN USE** — Nerd-patched Fira Code (ligatures + icons) | [docs](https://github.com/ryanoasis/nerd-fonts) |
| `font-jetbrains-mono` | **IN USE** — Zed terminal font (`.config/zed/settings.json:66`) | [docs](https://www.jetbrains.com/lp/mono) |
| `font-jetbrains-mono-nerd-font` | **IN USE** — wezterm's primary font (`.config/wezterm/wezterm.lua:17`) | [docs](https://github.com/ryanoasis/nerd-fonts) |
| `font-symbols-only-nerd-font` | **IN USE** — wezterm icon fallback (`.config/wezterm/wezterm.lua:21`); required for glyphs | [docs](https://github.com/ryanoasis/nerd-fonts) |
| `font-ibm-plex-mono` | Nerd Font — patched with icon glyphs. Not referenced by any config here | [docs](https://github.com/IBM/plex) |
| `font-bitter` | Nerd Font — patched with icon glyphs. Not referenced by any config here |  |
| `font-literata` | Nerd Font — patched with icon glyphs. Not referenced by any config here |  |

## VS Code Extensions

`@group vscode-ext` · 27 entries

| Package | What it is | Learn more |
|---|---|---|
| `anthropic.claude-code` | Claude Code for VS Code: Harness the power of Claude Code without leaving your IDE | [docs](https://marketplace.visualstudio.com/items?itemName=anthropic.claude-code) |
| `shopify.ruby-extensions-pack` | An opinionated and auto-configured set of extensions for Ruby development | [docs](https://marketplace.visualstudio.com/items?itemName=shopify.ruby-extensions-pack) |
| `jakebecker.elixir-ls` | Elixir support with debugger, autocomplete, and more - Powered by ElixirLS. | [docs](https://marketplace.visualstudio.com/items?itemName=jakebecker.elixir-ls) |
| `phoenixframework.phoenix` | Syntax highlighting support for HEEx | [docs](https://marketplace.visualstudio.com/items?itemName=phoenixframework.phoenix) |
| `rust-lang.rust-analyzer` | Rust language support for Visual Studio Code | [docs](https://marketplace.visualstudio.com/items?itemName=rust-lang.rust-analyzer) |
| `dart-code.dart-code` | Dart language support and debugger for Visual Studio Code. | [docs](https://marketplace.visualstudio.com/items?itemName=dart-code.dart-code) |
| `dart-code.flutter` | Flutter support and debugger for Visual Studio Code. | [docs](https://marketplace.visualstudio.com/items?itemName=dart-code.flutter) |
| `ms-python.python` | Python language support with extension access points for IntelliSense (Pylance), Debugging (Python Debugger), linting, formatting, refactoring, unit tests, and more. | [docs](https://marketplace.visualstudio.com/items?itemName=ms-python.python) |
| `ms-python.vscode-pylance` | A performant, feature-rich language server for Python in VS Code | [docs](https://marketplace.visualstudio.com/items?itemName=ms-python.vscode-pylance) |
| `ms-vscode.vscode-typescript-next` | Enables typescript@next to power VS Code's built-in JavaScript and TypeScript support | [docs](https://marketplace.visualstudio.com/items?itemName=ms-vscode.vscode-typescript-next) |
| `koichisasada.vscode-rdbg` | Ruby's rdbg debugger support for VSCode | [docs](https://marketplace.visualstudio.com/items?itemName=koichisasada.vscode-rdbg) |
| `usernamehw.errorlens` | Improve highlighting of errors, warnings and other language diagnostics. | [docs](https://marketplace.visualstudio.com/items?itemName=usernamehw.errorlens) |
| `eamodio.gitlens` | Supercharge Git within VS Code — Visualize code authorship at a glance via Git blame annotations and CodeLens, seamlessly navigate and explore Git repositories, gain valuable insights via rich visualizations and powerful comparison commands, and so much more | [docs](https://marketplace.visualstudio.com/items?itemName=eamodio.gitlens) |
| `github.vscode-pull-request-github` | Pull Request and Issue Provider for GitHub | [docs](https://marketplace.visualstudio.com/items?itemName=github.vscode-pull-request-github) |
| `github.vscode-github-actions` | GitHub Actions workflows and runs for github.com hosted repositories in VS Code | [docs](https://marketplace.visualstudio.com/items?itemName=github.vscode-github-actions) |
| `streetsidesoftware.code-spell-checker` | Spelling checker for source code | [docs](https://marketplace.visualstudio.com/items?itemName=streetsidesoftware.code-spell-checker) |
| `esbenp.prettier-vscode` | Code formatter using prettier | [docs](https://marketplace.visualstudio.com/items?itemName=esbenp.prettier-vscode) |
| `dbaeumer.vscode-eslint` | Integrates ESLint JavaScript into VS Code. | [docs](https://marketplace.visualstudio.com/items?itemName=dbaeumer.vscode-eslint) |
| `bradlc.vscode-tailwindcss` | Intelligent Tailwind CSS tooling for VS Code | [docs](https://marketplace.visualstudio.com/items?itemName=bradlc.vscode-tailwindcss) |
| `editorconfig.editorconfig` | EditorConfig Support for Visual Studio Code | [docs](https://marketplace.visualstudio.com/items?itemName=editorconfig.editorconfig) |
| `mikestead.dotenv` | Support for dotenv file syntax | [docs](https://marketplace.visualstudio.com/items?itemName=mikestead.dotenv) |
| `redhat.vscode-yaml` | YAML Language Support by Red Hat, with built-in Kubernetes syntax support | [docs](https://marketplace.visualstudio.com/items?itemName=redhat.vscode-yaml) |
| `tamasfe.even-better-toml` | Fully-featured TOML support | [docs](https://marketplace.visualstudio.com/items?itemName=tamasfe.even-better-toml) |
| `mechatroner.rainbow-csv` | Highlight CSV and TSV files, Run SQL-like queries | [docs](https://marketplace.visualstudio.com/items?itemName=mechatroner.rainbow-csv) |
| `daltonmenezes.aura-theme` | A beautiful dark theme for Visual Studio Code | [docs](https://marketplace.visualstudio.com/items?itemName=daltonmenezes.aura-theme) |
| `enkia.tokyo-night` | A clean Visual Studio Code theme that celebrates the lights of Downtown Tokyo at night. | [docs](https://marketplace.visualstudio.com/items?itemName=enkia.tokyo-night) |
| `pkief.material-icon-theme` | Material Design Icons for Visual Studio Code | [docs](https://marketplace.visualstudio.com/items?itemName=pkief.material-icon-theme) |

