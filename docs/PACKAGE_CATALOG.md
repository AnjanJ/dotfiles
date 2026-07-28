# Package Catalog

> Every package `install.sh` installs, grouped exactly as in the [Brewfile](../Brewfile).

**Descriptions and links are machine-generated from authoritative sources, not written by hand:**

| Type | Source |
|---|---|
| Formulae / casks | `brew info --json=v2` (Homebrew's own `desc` + `homepage`) |
| VS Code extensions | each extension's local `package.json` manifest |
| App Store apps | Apple iTunes Lookup API (`trackName`, `sellerName`, `trackViewUrl`) |

A blank description means upstream ships none — nothing has been invented to fill a gap.

Regenerate after editing the Brewfile: `python3 scripts/catalog/build-catalog.py` · last built 2026-07-29

## Contents

- [Taps](#taps) — 13
- [Core CLI](#core-cli) — 20
- [Editors & Terminals](#editors--terminals) — 9
- [Window Management](#window-management) — 1
- [Terminal Tools](#terminal-tools) — 18
- [AI Tooling](#ai-tooling) — 7
- [Databases](#databases) — 12
- [Cloud & Deploy](#cloud--deploy) — 7
- [Media](#media) — 9
- [Communication](#communication) — 4
- [Productivity](#productivity) — 17
- [Work](#work) — 3
- [Languages](#languages) — 9
- [Browsers](#browsers) — 6
- [Utilities](#utilities) — 23
- [Extras](#extras) — 18
- [Fonts](#fonts) — 78
- [VS Code Extensions](#vs-code-extensions) — 108

## Taps

`@group taps` · 13 entries

> Always installed — cannot be deselected.

| Package | What it is | Learn more |
|---|---|---|
| `antoniorodr/memo` | Third-party Homebrew formula repository | [docs](https://github.com/antoniorodr/homebrew-memo) |
| `charmbracelet/tap` | Third-party Homebrew formula repository | [docs](https://github.com/charmbracelet/homebrew-tap) |
| `cloudflare/cloudflare` | Third-party Homebrew formula repository | [docs](https://github.com/cloudflare/homebrew-cloudflare) |
| `felixkratz/formulae` | Third-party Homebrew formula repository | [docs](https://github.com/felixkratz/homebrew-formulae) |
| `heroku/brew` | Third-party Homebrew formula repository | [docs](https://github.com/heroku/homebrew-brew) |
| `hmbown/deepseek-tui` | Third-party Homebrew formula repository | [docs](https://github.com/hmbown/homebrew-deepseek-tui) |
| `jorgerojas26/lazysql` | Third-party Homebrew formula repository | [docs](https://github.com/jorgerojas26/homebrew-lazysql) |
| `nikitabobko/tap` | Third-party Homebrew formula repository | [docs](https://github.com/nikitabobko/homebrew-tap) |
| `openclaw/tap` | Third-party Homebrew formula repository | [docs](https://github.com/openclaw/homebrew-tap) |
| `render-oss/render` | Third-party Homebrew formula repository | [docs](https://github.com/render-oss/homebrew-render) |
| `steipete/tap` | Third-party Homebrew formula repository | [docs](https://github.com/steipete/homebrew-tap) |
| `supabase/tap` | Third-party Homebrew formula repository | [docs](https://github.com/supabase/homebrew-tap) |
| `yakitrak/yakitrak` | Third-party Homebrew formula repository | [docs](https://github.com/yakitrak/homebrew-yakitrak) |

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

`@group editors` · 9 entries

| Package | What it is | Learn more |
|---|---|---|
| `neovim` | Ambitious Vim-fork focused on extensibility and agility | [docs](https://neovim.io/) |
| `alacritty` | GPU-accelerated terminal emulator | [docs](https://github.com/alacritty/alacritty/) |
| `cursor` | Write, edit, and chat about your code with AI | [docs](https://www.cursor.com/) |
| `ghostty` | Terminal emulator that uses platform-native UI and GPU acceleration | [docs](https://ghostty.org/) |
| `rubymine` | Ruby on Rails IDE | [docs](https://www.jetbrains.com/ruby/) |
| `visual-studio-code` | Open-source code editor | [docs](https://code.visualstudio.com/) |
| `warp` | Rust-based terminal | [docs](https://www.warp.dev/) |
| `wezterm` | GPU-accelerated cross-platform terminal emulator and multiplexer | [docs](https://wezterm.org/) |
| `zed` | Multiplayer code editor | [docs](https://zed.dev/) |

## Window Management

`@group window-mgmt` · 1 entries

| Package | What it is | Learn more |
|---|---|---|
| `aerospace` | AeroSpace is an i3-like tiling window manager for macOS | [docs](https://github.com/nikitabobko/AeroSpace) |

## Terminal Tools

`@group terminal-tools` · 18 entries

| Package | What it is | Learn more |
|---|---|---|
| `cliclick` | Tool for emulating mouse and keyboard events | [docs](https://www.bluem.net/jump/cliclick/) |
| `git-delta` | Syntax-highlighting pager for git and diff output | [docs](https://dandavison.github.io/delta/) |
| `gitui` | Blazing fast terminal-ui for git written in rust | [docs](https://github.com/gitui-org/gitui) |
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
| `yazi` | Blazing fast terminal file manager written in Rust, based on async I/O | [docs](https://yazi-rs.github.io) |
| `zellij` | Pluggable terminal workspace, with terminal multiplexer as the base feature | [docs](https://zellij.dev) |
| `freeze` | Amazon Glacier file transfer client | [docs](https://www.freezeapp.net/) |

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

`@group databases` · 12 entries

| Package | What it is | Learn more |
|---|---|---|
| `lazysql` | Cross-platform TUI database management tool | [docs](https://github.com/jorgerojas26/lazysql) |
| `litecli` | CLI for SQLite Databases with auto-completion and syntax highlighting | [docs](https://litecli.com) |
| `mycli` | CLI for MySQL with auto-completion and syntax highlighting | [docs](https://www.mycli.net/) |
| `mysql` | Open source relational database management system | [docs](https://github.com/mysql/mysql-server) |
| `pgcli` | CLI for Postgres with auto-completion and syntax highlighting | [docs](https://pgcli.com/) |
| `pgvector` | Open-source vector similarity search for Postgres | [docs](https://github.com/pgvector/pgvector) |
| `postgresql@14` | Object-relational database system | [docs](https://www.postgresql.org/) |
| `postgresql@16` | Object-relational database system | [docs](https://www.postgresql.org/) |
| `redis` | Persistent key-value database, with built-in net interface | [docs](https://redis.io/) |
| `beekeeper-studio` | Cross platform SQL editor and database management app | [docs](https://www.beekeeperstudio.io/) |
| `postico` | GUI client for PostgreSQL databases | [docs](https://eggerapps.at/postico2/) |
| `redis-insight` | GUI for streamlined Redis application development | [docs](https://redis.io/insight/) |

## Cloud & Deploy

`@group cloud-deploy` · 7 entries

| Package | What it is | Learn more |
|---|---|---|
| `cloudflared` | Cloudflare Tunnel client (formerly Argo Tunnel) | [docs](https://developers.cloudflare.com/cloudflare-one/networks/connectors/cloudflare-tunnel/) |
| `docker` | Pack, ship and run any application as a lightweight container | [docs](https://www.docker.com/) |
| `flyctl` | Command-line tools for fly.io services | [docs](https://fly.io) |
| `heroku` | CLI for Heroku | [docs](https://www.npmjs.com/package/heroku/) |
| `render` | Command-line interface for Render | [docs](https://render.com/docs/cli) |
| `supabase` | Postgres development platform | [docs](https://supabase.com/docs/reference/cli/about) |
| `docker-desktop` | App to build and share containerised applications and microservices | [docs](https://www.docker.com/products/docker-desktop) |

## Media

`@group media` · 9 entries

| Package | What it is | Learn more |
|---|---|---|
| `ffmpeg-full` | Play, record, convert, and stream many audio and video codecs | [docs](https://ffmpeg.org/) |
| `imagemagick-full` | Tools and libraries to manipulate images in many formats | [docs](https://imagemagick.org) |
| `libre` | Toolkit library for asynchronous network I/O with protocol stacks | [docs](https://github.com/baresip/re) |
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

`@group productivity` · 17 entries

| Package | What it is | Learn more |
|---|---|---|
| `antoniorodr/memo/memo` | CLI app to manage your Apple Notes and Apple reminders | [docs](https://github.com/antoniorodr/memo) |
| `yakitrak/yakitrak/obsidian-cli` |  | [docs](https://github.com/Yakitrak/obsidian-cli) |
| `steipete/tap/remindctl` | Fast CLI for Apple Reminders | [docs](https://github.com/steipete/remindctl) |
| `1password` | Password manager that keeps all passwords secure behind one password | [docs](https://1password.com/) |
| `1password-cli` | Command-line interface for 1Password | [docs](https://developer.1password.com/docs/cli) |
| `notion` | App to write, plan, collaborate, and get organised | [docs](https://www.notion.com/) |
| `obsidian` | Knowledge base that works on top of a local folder of plain text Markdown files | [docs](https://obsidian.md/) |
| `proton-mail` | Client for Proton Mail and Proton Calendar | [docs](https://proton.me/mail) |
| `proton-pass` | Desktop client for Proton Pass | [docs](https://proton.me/pass) |
| `protonvpn` | VPN client focusing on security | [docs](https://protonvpn.com/) |
| `raycast` | Control your tools with a few keystrokes | [docs](https://raycast.com/) |
| `wispr-flow` | Voice-to-text dictation with AI-powered auto-editing | [docs](https://wisprflow.ai/) |
| `1Password for Safari` | 1Password for Safari — by AgileBits Inc. | [docs](https://apps.apple.com/in/app/1password-for-safari/id1569813296?mt=12&uo=4) |
| `2FAS - Two Factor Authentication` | 2FAS Auth Browser Extension — by Two Factor Authentication Service, Inc. | [docs](https://apps.apple.com/in/app/2fas-auth-browser-extension/id6443941139?mt=12&uo=4) |
| `Dashlane` | Dashlane Password Manager — by Dashlane | [docs](https://apps.apple.com/in/app/dashlane-password-manager/id517914548?uo=4) |
| `Tailscale` | Tailscale — by Tailscale Inc. | [docs](https://apps.apple.com/in/app/tailscale/id1475387142?mt=12&uo=4) |
| `TextSniper` | TextSniper — by Valerijs Boguckis | [docs](https://apps.apple.com/in/app/textsniper/id1528890965?mt=12&uo=4) |

## Work

`@group work` · 3 entries

| Package | What it is | Learn more |
|---|---|---|
| `slack` | Team communication and collaboration software | [docs](https://slack.com/) |
| `zoom` | Video communication and virtual meeting platform | [docs](https://www.zoom.us/) |
| `Okta Verify` | Okta Verify — by Okta, Inc. | [docs](https://apps.apple.com/in/app/okta-verify/id490179405?uo=4) |

## Languages

`@group languages` · 9 entries

| Package | What it is | Learn more |
|---|---|---|
| `cargo-nextest` | Next-generation test runner for Rust | [docs](https://nexte.st) |
| `criterion` | Cross-platform C and C++ unit testing framework for the 21st century | [docs](https://github.com/Snaipe/Criterion) |
| `openjdk` | Development kit for the Java programming language | [docs](https://openjdk.org/) |
| `openjdk@17` | Development kit for the Java programming language | [docs](https://openjdk.org/) |
| `uv` | Extremely fast Python package installer and resolver, written in Rust | [docs](https://docs.astral.sh/uv/) |
| `zig` | Programming language designed for robustness, optimality, and clarity | [docs](https://ziglang.org/) |
| `android-commandlinetools` | Command-line tools for building and debugging Android apps | [docs](https://developer.android.com/studio) |
| `android-platform-tools` | Android SDK component | [docs](https://developer.android.com/tools/releases/platform-tools) |
| `flutter` | UI toolkit for building applications for mobile, web and desktop | [docs](https://flutter.dev/) |

## Browsers

`@group browsers` · 6 entries

| Package | What it is | Learn more |
|---|---|---|
| `firefox` | Web browser | [docs](https://www.mozilla.org/firefox/) |
| `google-chrome` | Web browser | [docs](https://www.google.com/chrome/) |
| `helium-browser` | Chromium-based web browser | [docs](https://helium.computer/) |
| `thorium` | Epub reader | [docs](https://www.edrlab.org/software/thorium-reader/) |
| `zen` | Gecko based web browser | [docs](https://zen-browser.app/) |
| `DuckDuckGo` | DuckDuckGo, optional Duck.ai — by Duck Duck Go, Inc. | [docs](https://apps.apple.com/in/app/duckduckgo-optional-duck-ai/id663592361?uo=4) |

## Utilities

`@group utilities` · 23 entries

| Package | What it is | Learn more |
|---|---|---|
| `adobe-digital-editions` | E-book reader | [docs](https://www.adobe.com/solutions/ebook/digital-editions.html) |
| `balenaetcher` | Tool to flash OS images to SD cards & USB drives | [docs](https://balena.io/etcher) |
| `bruno` | Open source IDE for exploring and testing APIs | [docs](https://www.usebruno.com/) |
| `calibre` | E-books management software | [docs](https://calibre-ebook.com/) |
| `libreoffice` | Free cross-platform office suite, fresh version | [docs](https://www.libreoffice.org/) |
| `raspberry-pi-imager` | Imaging utility to install operating systems to a microSD card | [docs](https://www.raspberrypi.com/software/) |
| `requestly` | Intercept and modify HTTP requests | [docs](https://requestly.com/) |
| `stremio` | Open-source media center | [docs](https://www.strem.io/) |
| `tuta-mail` | Email client | [docs](https://tuta.com/) |
| `Bandwidth+` | Bandwidth+ — by Harold Chu | [docs](https://apps.apple.com/in/app/bandwidth/id490461369?mt=12&uo=4) |
| `Developer` | Apple Developer — by Apple Distribution International | [docs](https://apps.apple.com/in/app/apple-developer/id640199958?uo=4) |
| `Hidden Bar` | Hidden Bar — by Dwarves Foundation Company Limited | [docs](https://apps.apple.com/in/app/hidden-bar/id1452453066?mt=12&uo=4) |
| `iStat Menus` | iStat Menus — by Bjango | [docs](https://apps.apple.com/app/id1319778037) |
| `Kindle` | Amazon Kindle: Reading App — by AMAZON SELLER SERVICES PRIVATE LIMITED | [docs](https://apps.apple.com/in/app/amazon-kindle-reading-app/id302584613?uo=4) |
| `LanguageTool` | LanguageTool - Grammar Checker — by LanguageTooler GmbH | [docs](https://apps.apple.com/in/app/languagetool-grammar-checker/id1534275760?uo=4) |
| `LocalSend` | LocalSend — by Tien Do Nam | [docs](https://apps.apple.com/in/app/localsend/id1661733229?uo=4) |
| `Menu Bar Calendar` | Menu Bar Calendar — by Sindre Sorhus | [docs](https://apps.apple.com/in/app/menu-bar-calendar/id1558360383?mt=12&uo=4) |
| `Noir` | Noir – Dark Mode for Safari — by Jeffrey Kuiken | [docs](https://apps.apple.com/in/app/noir-dark-mode-for-safari/id1592917505?mt=12&uo=4) |
| `Numbers` | Numbers — by Apple | [docs](https://apps.apple.com/app/id409203825) |
| `Perplexity` | Perplexity — by Perplexity AI | [docs](https://apps.apple.com/app/id6714467650) |
| `Save to Raindrop.io` | Save to Raindrop.io — by Rustem Mussabekov | [docs](https://apps.apple.com/in/app/save-to-raindrop-io/id1549370672?mt=12&uo=4) |
| `Tot` | Tot — by The Iconfactory | [docs](https://apps.apple.com/in/app/tot/id1491071483?mt=12&uo=4) |
| `Xcode` | Xcode — by Apple Distribution International | [docs](https://apps.apple.com/in/app/xcode/id497799835?mt=12&uo=4) |

## Extras

`@group extras` · 18 entries

| Package | What it is | Learn more |
|---|---|---|
| `steipete/tap/bird` | Fast X CLI for tweeting, replying, and reading — ⚠️ upstream repo 404s (verified); may fail on a fresh install | [docs](https://github.com/steipete/bird) |
| `steipete/tap/gifgrep` | Grep the GIF. Stick the landing | [docs](https://github.com/steipete/gifgrep) |
| `steipete/tap/imsg` | Send and read iMessage / SMS from the terminal | [docs](https://github.com/openclaw/imsg) |
| `steipete/tap/peekaboo` | Lightning-fast macOS screenshots & AI vision analysis | [docs](https://github.com/openclaw/Peekaboo) |
| `steipete/tap/sag` | Command-line ElevenLabs TTS with mac-style flags | [docs](https://github.com/steipete/sag) |
| `steipete/tap/songsee` | Spectral visualization CLI for audio files | [docs](https://github.com/openclaw/songsee) |
| `openclaw/tap/wacli` | WhatsApp CLI built on whatsmeow | [docs](https://github.com/openclaw/wacli) |
| `openclaw/tap/goplaces` | Modern Go client + CLI for the Google Places API (New). | [docs](https://github.com/openclaw/goplaces) |
| `charmbracelet/tap/freeze` | Generate images of code and terminal output. | [docs](https://charm.sh/) |
| `libidn` | International domain name library | [docs](https://www.gnu.org/software/libidn/) |
| `libxmlsec1` | XML security library | [docs](https://www.aleksey.com/xmlsec/) |
| `libyaml` | YAML Parser | [docs](https://github.com/yaml/libyaml) |
| `openssl@1.1` | Cryptography and SSL/TLS Toolkit | [docs](https://openssl.org/) |
| `putty` | Implementation of Telnet and SSH | [docs](https://putty.software/) |
| `shared-mime-info` | Database of common MIME types | [docs](https://wiki.freedesktop.org/www/Software/shared-mime-info) |
| `glib` | Core application library for C | [docs](https://docs.gtk.org/glib/) |
| `pango` | Framework for layout and rendering of i18n text | [docs](https://www.gtk.org/docs/architecture/pango) |
| `openclaw/tap/goplaces` | Modern Go client + CLI for the Google Places API (New). | [docs](https://github.com/openclaw/goplaces) |

## Fonts

`@group fonts` · 78 entries

| Package | What it is | Learn more |
|---|---|---|
| `font-0xproto-nerd-font` |  | [docs](https://github.com/ryanoasis/nerd-fonts) |
| `font-3270-nerd-font` |  | [docs](https://github.com/ryanoasis/nerd-fonts) |
| `font-adwaita-mono-nerd-font` |  | [docs](https://github.com/ryanoasis/nerd-fonts) |
| `font-agave-nerd-font` |  | [docs](https://github.com/ryanoasis/nerd-fonts) |
| `font-anka-coder` |  | [docs](https://code.google.com/p/anka-coder-fonts/) |
| `font-anonymice-nerd-font` |  | [docs](https://github.com/ryanoasis/nerd-fonts) |
| `font-arimo-nerd-font` |  | [docs](https://github.com/ryanoasis/nerd-fonts) |
| `font-atkynson-mono-nerd-font` |  | [docs](https://github.com/ryanoasis/nerd-fonts) |
| `font-aurulent-sans-mono-nerd-font` |  | [docs](https://github.com/ryanoasis/nerd-fonts) |
| `font-bigblue-terminal-nerd-font` |  | [docs](https://github.com/ryanoasis/nerd-fonts) |
| `font-bitstream-vera-sans-mono-nerd-font` |  | [docs](https://github.com/ryanoasis/nerd-fonts) |
| `font-blex-mono-nerd-font` |  | [docs](https://github.com/ryanoasis/nerd-fonts) |
| `font-cascadia-code` |  | [docs](https://github.com/microsoft/cascadia-code) |
| `font-caskaydia-cove-nerd-font` |  | [docs](https://github.com/ryanoasis/nerd-fonts) |
| `font-caskaydia-mono-nerd-font` |  | [docs](https://github.com/ryanoasis/nerd-fonts) |
| `font-code-new-roman-nerd-font` |  | [docs](https://github.com/ryanoasis/nerd-fonts) |
| `font-comic-shanns-mono-nerd-font` |  | [docs](https://github.com/ryanoasis/nerd-fonts) |
| `font-commit-mono-nerd-font` |  | [docs](https://github.com/ryanoasis/nerd-fonts) |
| `font-cousine-nerd-font` |  | [docs](https://github.com/ryanoasis/nerd-fonts) |
| `font-d2coding-nerd-font` |  | [docs](https://github.com/ryanoasis/nerd-fonts) |
| `font-daddy-time-mono-nerd-font` |  | [docs](https://github.com/ryanoasis/nerd-fonts) |
| `font-dejavu-sans-mono-nerd-font` |  | [docs](https://github.com/ryanoasis/nerd-fonts) |
| `font-departure-mono-nerd-font` |  | [docs](https://github.com/ryanoasis/nerd-fonts) |
| `font-droid-sans-mono-nerd-font` |  | [docs](https://github.com/ryanoasis/nerd-fonts) |
| `font-envy-code-r-nerd-font` |  | [docs](https://github.com/ryanoasis/nerd-fonts) |
| `font-fantasque-sans-mono-nerd-font` |  | [docs](https://github.com/ryanoasis/nerd-fonts) |
| `font-fira-code` |  | [docs](https://github.com/tonsky/FiraCode) |
| `font-fira-code-nerd-font` |  | [docs](https://github.com/ryanoasis/nerd-fonts) |
| `font-fira-mono-nerd-font` |  | [docs](https://github.com/ryanoasis/nerd-fonts) |
| `font-geist-mono-nerd-font` |  | [docs](https://github.com/ryanoasis/nerd-fonts) |
| `font-go-mono-nerd-font` |  | [docs](https://github.com/ryanoasis/nerd-fonts) |
| `font-gohufont-nerd-font` |  | [docs](https://github.com/ryanoasis/nerd-fonts) |
| `font-hack` |  | [docs](https://sourcefoundry.org/hack/) |
| `font-hack-nerd-font` |  | [docs](https://github.com/ryanoasis/nerd-fonts) |
| `font-hasklug-nerd-font` |  | [docs](https://github.com/ryanoasis/nerd-fonts) |
| `font-heavy-data-nerd-font` |  | [docs](https://github.com/ryanoasis/nerd-fonts) |
| `font-hurmit-nerd-font` |  | [docs](https://github.com/ryanoasis/nerd-fonts) |
| `font-ibm-plex-mono` |  | [docs](https://github.com/IBM/plex) |
| `font-im-writing-nerd-font` |  | [docs](https://github.com/ryanoasis/nerd-fonts) |
| `font-inconsolata` |  | [docs](https://fonts.google.com/specimen/Inconsolata) |
| `font-inconsolata-go-nerd-font` |  | [docs](https://github.com/ryanoasis/nerd-fonts) |
| `font-inconsolata-lgc-nerd-font` |  | [docs](https://github.com/ryanoasis/nerd-fonts) |
| `font-inconsolata-nerd-font` |  | [docs](https://github.com/ryanoasis/nerd-fonts) |
| `font-intone-mono-nerd-font` |  | [docs](https://github.com/ryanoasis/nerd-fonts) |
| `font-iosevka-nerd-font` |  | [docs](https://github.com/ryanoasis/nerd-fonts) |
| `font-iosevka-term-nerd-font` |  | [docs](https://github.com/ryanoasis/nerd-fonts) |
| `font-iosevka-term-slab-nerd-font` |  | [docs](https://github.com/ryanoasis/nerd-fonts) |
| `font-jetbrains-mono` |  | [docs](https://www.jetbrains.com/lp/mono) |
| `font-jetbrains-mono-nerd-font` |  | [docs](https://github.com/ryanoasis/nerd-fonts) |
| `font-lekton-nerd-font` |  | [docs](https://github.com/ryanoasis/nerd-fonts) |
| `font-liberation-nerd-font` |  | [docs](https://github.com/ryanoasis/nerd-fonts) |
| `font-lilex-nerd-font` |  | [docs](https://github.com/ryanoasis/nerd-fonts) |
| `font-m+-nerd-font` |  | [docs](https://github.com/ryanoasis/nerd-fonts) |
| `font-martian-mono-nerd-font` |  | [docs](https://github.com/ryanoasis/nerd-fonts) |
| `font-meslo-lg-nerd-font` |  | [docs](https://github.com/ryanoasis/nerd-fonts) |
| `font-monaspice-nerd-font` |  | [docs](https://github.com/ryanoasis/nerd-fonts) |
| `font-monocraft-nerd-font` |  | [docs](https://github.com/IdreesInc/Monocraft) |
| `font-monofur-nerd-font` |  | [docs](https://github.com/ryanoasis/nerd-fonts) |
| `font-monoid-nerd-font` |  | [docs](https://github.com/ryanoasis/nerd-fonts) |
| `font-mononoki-nerd-font` |  | [docs](https://github.com/ryanoasis/nerd-fonts) |
| `font-noto-nerd-font` |  | [docs](https://github.com/ryanoasis/nerd-fonts) |
| `font-opendyslexic-nerd-font` |  | [docs](https://github.com/ryanoasis/nerd-fonts) |
| `font-overpass-nerd-font` |  | [docs](https://github.com/ryanoasis/nerd-fonts) |
| `font-profont-nerd-font` |  | [docs](https://github.com/ryanoasis/nerd-fonts) |
| `font-proggy-clean-tt-nerd-font` |  | [docs](https://github.com/ryanoasis/nerd-fonts) |
| `font-recursive-mono-nerd-font` |  | [docs](https://github.com/ryanoasis/nerd-fonts) |
| `font-roboto-mono-nerd-font` |  | [docs](https://github.com/ryanoasis/nerd-fonts) |
| `font-sauce-code-pro-nerd-font` |  | [docs](https://github.com/ryanoasis/nerd-fonts) |
| `font-shure-tech-mono-nerd-font` |  | [docs](https://github.com/ryanoasis/nerd-fonts) |
| `font-space-mono-nerd-font` |  | [docs](https://github.com/ryanoasis/nerd-fonts) |
| `font-symbols-only-nerd-font` |  | [docs](https://github.com/ryanoasis/nerd-fonts) |
| `font-terminess-ttf-nerd-font` |  | [docs](https://github.com/ryanoasis/nerd-fonts) |
| `font-tinos-nerd-font` |  | [docs](https://github.com/ryanoasis/nerd-fonts) |
| `font-ubuntu-mono-nerd-font` |  | [docs](https://github.com/ryanoasis/nerd-fonts) |
| `font-ubuntu-nerd-font` |  | [docs](https://github.com/ryanoasis/nerd-fonts) |
| `font-ubuntu-sans-nerd-font` |  | [docs](https://github.com/ryanoasis/nerd-fonts) |
| `font-victor-mono-nerd-font` |  | [docs](https://github.com/ryanoasis/nerd-fonts) |
| `font-zed-mono-nerd-font` |  | [docs](https://github.com/ryanoasis/nerd-fonts) |

## VS Code Extensions

`@group vscode-ext` · 108 entries

| Package | What it is | Learn more |
|---|---|---|
| `aaron-bond.better-comments` | Improve your code commenting by annotating with alert, informational, TODOs, and more! | [docs](https://marketplace.visualstudio.com/items?itemName=aaron-bond.better-comments) |
| `adpyke.codesnap` | 📷 Take beautiful screenshots of your code | [docs](https://marketplace.visualstudio.com/items?itemName=adpyke.codesnap) |
| `alefragnani.bookmarks` | Mark lines and jump to them | [docs](https://marketplace.visualstudio.com/items?itemName=alefragnani.bookmarks) |
| `alefragnani.project-manager` | Easily switch between projects | [docs](https://marketplace.visualstudio.com/items?itemName=alefragnani.project-manager) |
| `aliariff.vscode-erb-beautify` | Format/Beautify ERB files | [docs](https://marketplace.visualstudio.com/items?itemName=aliariff.vscode-erb-beautify) |
| `andrewbutson.vscode-openai` | vscode-openai seamlessly incorporates OpenAI features into VSCode, providing integration with SCM, Code Editor and Chat. | [docs](https://marketplace.visualstudio.com/items?itemName=andrewbutson.vscode-openai) |
| `anthropic.claude-code` | Claude Code for VS Code: Harness the power of Claude Code without leaving your IDE | [docs](https://marketplace.visualstudio.com/items?itemName=anthropic.claude-code) |
| `batatop.terminal-auto-rename` | Automatically renames the terminal with the current folder name. | [docs](https://marketplace.visualstudio.com/items?itemName=batatop.terminal-auto-rename) |
| `biomejs.biome` | Toolchain of the web | [docs](https://marketplace.visualstudio.com/items?itemName=biomejs.biome) |
| `bradlc.vscode-tailwindcss` | Intelligent Tailwind CSS tooling for VS Code | [docs](https://marketplace.visualstudio.com/items?itemName=bradlc.vscode-tailwindcss) |
| `bung87.rails` | Ruby on Rails support for Visual Studio Code | [docs](https://marketplace.visualstudio.com/items?itemName=bung87.rails) |
| `bung87.vscode-gemfile` | provide hover link in Gemfile refers to online site | [docs](https://marketplace.visualstudio.com/items?itemName=bung87.vscode-gemfile) |
| `castwide.solargraph` | A Ruby language server featuring code completion, intellisense, and inline documentation | [docs](https://marketplace.visualstudio.com/items?itemName=castwide.solargraph) |
| `christian-kohler.npm-intellisense` | Visual Studio Code plugin that autocompletes npm modules in import statements | [docs](https://marketplace.visualstudio.com/items?itemName=christian-kohler.npm-intellisense) |
| `christian-kohler.path-intellisense` | Visual Studio Code plugin that autocompletes filenames | [docs](https://marketplace.visualstudio.com/items?itemName=christian-kohler.path-intellisense) |
| `chrmarti.regex` | Regex matches previewer for JavaScript, TypeScript, PHP and Haxe in Visual Studio Code. | [docs](https://marketplace.visualstudio.com/items?itemName=chrmarti.regex) |
| `daltonmenezes.aura-theme` | A beautiful dark theme for Visual Studio Code | [docs](https://marketplace.visualstudio.com/items?itemName=daltonmenezes.aura-theme) |
| `dart-code.dart-code` | Dart language support and debugger for Visual Studio Code. | [docs](https://marketplace.visualstudio.com/items?itemName=dart-code.dart-code) |
| `dart-code.flutter` | Flutter support and debugger for Visual Studio Code. | [docs](https://marketplace.visualstudio.com/items?itemName=dart-code.flutter) |
| `davidpallinder.rails-test-runner` | Easily run your rails tests from within Visual Studio Code (vscode) | [docs](https://marketplace.visualstudio.com/items?itemName=davidpallinder.rails-test-runner) |
| `dbaeumer.vscode-eslint` | Integrates ESLint JavaScript into VS Code. | [docs](https://marketplace.visualstudio.com/items?itemName=dbaeumer.vscode-eslint) |
| `donjayamanne.githistory` | View git log, file history, compare branches or commits | [docs](https://marketplace.visualstudio.com/items?itemName=donjayamanne.githistory) |
| `dotjoshjohnson.xml` | XML Formatting, XQuery, and XPath Tools for Visual Studio Code | [docs](https://marketplace.visualstudio.com/items?itemName=dotjoshjohnson.xml) |
| `drewxs.tokyo-night-dark` | Darker version of Tokyo Night Dark | [docs](https://marketplace.visualstudio.com/items?itemName=drewxs.tokyo-night-dark) |
| `dsznajder.es7-react-js-snippets` | Extensions for React, React-Native and Redux in JS/TS with ES7+ syntax. Customizable. Built-in integration with prettier. | [docs](https://marketplace.visualstudio.com/items?itemName=dsznajder.es7-react-js-snippets) |
| `eamodio.gitlens` | Supercharge Git within VS Code — Visualize code authorship at a glance via Git blame annotations and CodeLens, seamlessly navigate and explore Git repositories, gain valuable insights via rich visualizations and powerful comparison commands, and so much more | [docs](https://marketplace.visualstudio.com/items?itemName=eamodio.gitlens) |
| `editorconfig.editorconfig` | EditorConfig Support for Visual Studio Code | [docs](https://marketplace.visualstudio.com/items?itemName=editorconfig.editorconfig) |
| `elia.erb-formatter` | Format ERB files with speed and precision. | [docs](https://marketplace.visualstudio.com/items?itemName=elia.erb-formatter) |
| `enkia.tokyo-night` | A clean Visual Studio Code theme that celebrates the lights of Downtown Tokyo at night. | [docs](https://marketplace.visualstudio.com/items?itemName=enkia.tokyo-night) |
| `esbenp.prettier-vscode` | Code formatter using prettier | [docs](https://marketplace.visualstudio.com/items?itemName=esbenp.prettier-vscode) |
| `fill-labs.dependi` | Empowers developers to efficiently manage dependencies and address vulnerabilities in Rust, Go, JavaScript, Typescript, PHP, Python, Dart, C#, and Elixir projects. | [docs](https://marketplace.visualstudio.com/items?itemName=fill-labs.dependi) |
| `firsttris.vscode-jest-runner` | Run and debug Jest, Vitest, Node.js, Bun, Rstest and Deno tests with ease, right from your editor. | [docs](https://marketplace.visualstudio.com/items?itemName=firsttris.vscode-jest-runner) |
| `formulahendry.auto-close-tag` | Automatically add HTML/XML close tag, same as Visual Studio IDE or Sublime Text | [docs](https://marketplace.visualstudio.com/items?itemName=formulahendry.auto-close-tag) |
| `formulahendry.auto-rename-tag` | Auto rename paired HTML/XML tag | [docs](https://marketplace.visualstudio.com/items?itemName=formulahendry.auto-rename-tag) |
| `formulahendry.code-runner` | Run C, C++, Java, JS, PHP, Python, Perl, Ruby, Go, Lua, Groovy, PowerShell, CMD, BASH, F#, C#, VBScript, TypeScript, CoffeeScript, Scala, Swift, Julia, Crystal, OCaml, R, AppleScript, Elixir, VB.NET, Clojure, Haxe, Obj-C, Rust, Racket, Scheme, AutoHotkey, AutoIt, Kotlin, Dart, Pascal, Haskell, Nim, D, Lisp, Kit, V, SCSS, Sass, CUDA, Less, Fortran, Ring, Standard ML, Zig, Mojo, Erlang, SPWN, Pkl, Gleam | [docs](https://marketplace.visualstudio.com/items?itemName=formulahendry.code-runner) |
| `github.github-vscode-theme` | GitHub theme for VS Code | [docs](https://marketplace.visualstudio.com/items?itemName=github.github-vscode-theme) |
| `github.vscode-github-actions` | GitHub Actions workflows and runs for github.com hosted repositories in VS Code | [docs](https://marketplace.visualstudio.com/items?itemName=github.vscode-github-actions) |
| `github.vscode-pull-request-github` | %description% | [docs](https://marketplace.visualstudio.com/items?itemName=github.vscode-pull-request-github) |
| `gruntfuggly.todo-tree` | Show TODO, FIXME, etc. comment tags in a tree view | [docs](https://marketplace.visualstudio.com/items?itemName=gruntfuggly.todo-tree) |
| `heybourn.headwind` | An opinionated class sorter for Tailwind CSS | [docs](https://marketplace.visualstudio.com/items?itemName=heybourn.headwind) |
| `infeng.vscode-react-typescript` | Code snippets for react in typescript | [docs](https://marketplace.visualstudio.com/items?itemName=infeng.vscode-react-typescript) |
| `irongeek.vscode-env` | Adds formatting and syntax highlighting support for env files (.env) to Visual Studio Code | [docs](https://marketplace.visualstudio.com/items?itemName=irongeek.vscode-env) |
| `jakebecker.elixir-ls` | Elixir support with debugger, autocomplete, and more - Powered by ElixirLS. | [docs](https://marketplace.visualstudio.com/items?itemName=jakebecker.elixir-ls) |
| `kaiwood.endwise` | Wisely add closing keywords in Ruby, Crystal, Elixir, Julia, Lua, Makefiles, and shell scripts. | [docs](https://marketplace.visualstudio.com/items?itemName=kaiwood.endwise) |
| `kisstkondoros.vscode-codemetrics` | Computes complexity in TypeScript / JavaScript files. | [docs](https://marketplace.visualstudio.com/items?itemName=kisstkondoros.vscode-codemetrics) |
| `kisstkondoros.vscode-gutter-preview` | Shows image preview in the gutter and on hover | [docs](https://marketplace.visualstudio.com/items?itemName=kisstkondoros.vscode-gutter-preview) |
| `kohkimakimoto.vscode-mac-dictionary` | Integrates Mac Dictionary.app with vscode. | [docs](https://marketplace.visualstudio.com/items?itemName=kohkimakimoto.vscode-mac-dictionary) |
| `koichisasada.vscode-rdbg` | Ruby's rdbg debugger support for VSCode | [docs](https://marketplace.visualstudio.com/items?itemName=koichisasada.vscode-rdbg) |
| `lamarcke.kanagawa-black` | A fork of the Kanagawa VS Code theme, with pitch black niceties. | [docs](https://marketplace.visualstudio.com/items?itemName=lamarcke.kanagawa-black) |
| `lokalise.i18n-ally` | 🌍 All in one i18n extension for VS Code | [docs](https://marketplace.visualstudio.com/items?itemName=lokalise.i18n-ally) |
| `mechatroner.rainbow-csv` | Highlight CSV and TSV files, Run SQL-like queries | [docs](https://marketplace.visualstudio.com/items?itemName=mechatroner.rainbow-csv) |
| `mgmcdermott.vscode-language-babel` | VSCode syntax highlighting for today's JavaScript | [docs](https://marketplace.visualstudio.com/items?itemName=mgmcdermott.vscode-language-babel) |
| `mhutchie.git-graph` | View a Git Graph of your repository, and perform Git actions from the graph. | [docs](https://marketplace.visualstudio.com/items?itemName=mhutchie.git-graph) |
| `mikestead.dotenv` | Support for dotenv file syntax | [docs](https://marketplace.visualstudio.com/items?itemName=mikestead.dotenv) |
| `mintlify.document` | AI powered documentation writer for JavaScript, Python, Java, Typescript & all other languages | [docs](https://marketplace.visualstudio.com/items?itemName=mintlify.document) |
| `misogi.ruby-rubocop` | execute rubocop for current Ruby code. | [docs](https://marketplace.visualstudio.com/items?itemName=misogi.ruby-rubocop) |
| `mongodb.mongodb-vscode` | Connect to MongoDB and Atlas directly from your VS Code environment, navigate your databases and collections, inspect your schema and use playgrounds to prototype queries and aggregations. | [docs](https://marketplace.visualstudio.com/items?itemName=mongodb.mongodb-vscode) |
| `ms-azuretools.vscode-containers` | Makes it easy to create, manage, and debug containerized applications. | [docs](https://marketplace.visualstudio.com/items?itemName=ms-azuretools.vscode-containers) |
| `ms-azuretools.vscode-docker` | Makes it easy to create, manage, and debug containerized applications. | [docs](https://marketplace.visualstudio.com/items?itemName=ms-azuretools.vscode-docker) |
| `ms-python.debugpy` | Python Debugger extension using debugpy. | [docs](https://marketplace.visualstudio.com/items?itemName=ms-python.debugpy) |
| `ms-python.python` | Python language support with extension access points for IntelliSense (Pylance), Debugging (Python Debugger), linting, formatting, refactoring, unit tests, and more. | [docs](https://marketplace.visualstudio.com/items?itemName=ms-python.python) |
| `ms-python.vscode-pylance` | A performant, feature-rich language server for Python in VS Code | [docs](https://marketplace.visualstudio.com/items?itemName=ms-python.vscode-pylance) |
| `ms-python.vscode-python-envs` | Provides a unified python environment experience | [docs](https://marketplace.visualstudio.com/items?itemName=ms-python.vscode-python-envs) |
| `ms-vscode.live-server` | Hosts a local server in your workspace for you to preview your webpages on. | [docs](https://marketplace.visualstudio.com/items?itemName=ms-vscode.live-server) |
| `ms-vscode.vscode-typescript-next` | Enables typescript@next to power VS Code's built-in JavaScript and TypeScript support | [docs](https://marketplace.visualstudio.com/items?itemName=ms-vscode.vscode-typescript-next) |
| `mtxr.sqltools` | Connecting users to many of the most commonly used databases. Welcome to database management done right. | [docs](https://marketplace.visualstudio.com/items?itemName=mtxr.sqltools) |
| `mtxr.sqltools-driver-mysql` | SQLTools MySQL/MariaDB/TiDB | [docs](https://marketplace.visualstudio.com/items?itemName=mtxr.sqltools-driver-mysql) |
| `mtxr.sqltools-driver-pg` | SQLTools PostgreSQL/Cockroach Driver | [docs](https://marketplace.visualstudio.com/items?itemName=mtxr.sqltools-driver-pg) |
| `mtxr.sqltools-driver-sqlite` | SQLTools SQLite | [docs](https://marketplace.visualstudio.com/items?itemName=mtxr.sqltools-driver-sqlite) |
| `naumovs.color-highlight` | Highlight web colors in your editor | [docs](https://marketplace.visualstudio.com/items?itemName=naumovs.color-highlight) |
| `noku.rails-run-spec-vscode` | Rails Run Spec Files | [docs](https://marketplace.visualstudio.com/items?itemName=noku.rails-run-spec-vscode) |
| `oderwat.indent-rainbow` | Makes indentation easier to read | [docs](https://marketplace.visualstudio.com/items?itemName=oderwat.indent-rainbow) |
| `openai.chatgpt` | Codex is a coding agent that works with you everywhere you code — included in ChatGPT Plus, Pro, Business, Edu, and Enterprise plans. | [docs](https://marketplace.visualstudio.com/items?itemName=openai.chatgpt) |
| `pantajoe.vscode-elixir-credo` | VSC Support for Elixir linter 'Credo'. | [docs](https://marketplace.visualstudio.com/items?itemName=pantajoe.vscode-elixir-credo) |
| `patbenatar.advanced-new-file` | Create files anywhere in your workspace from the keyboard | [docs](https://marketplace.visualstudio.com/items?itemName=patbenatar.advanced-new-file) |
| `phoenixframework.phoenix` | Syntax highlighting support for HEEx | [docs](https://marketplace.visualstudio.com/items?itemName=phoenixframework.phoenix) |
| `pkief.material-icon-theme` | Material Design Icons for Visual Studio Code | [docs](https://marketplace.visualstudio.com/items?itemName=pkief.material-icon-theme) |
| `planbcoding.vscode-react-refactor` | Recompose your overgrown JSX without worrying about the given data. | [docs](https://marketplace.visualstudio.com/items?itemName=planbcoding.vscode-react-refactor) |
| `pranaygp.vscode-css-peek` | Allow peeking to css ID and class strings as definitions from html files to respective CSS. Allows peek and goto definition. | [docs](https://marketplace.visualstudio.com/items?itemName=pranaygp.vscode-css-peek) |
| `redhat.vscode-yaml` | YAML Language Support by Red Hat, with built-in Kubernetes syntax support | [docs](https://marketplace.visualstudio.com/items?itemName=redhat.vscode-yaml) |
| `riey.erb` | ERB language support for Visual Studio Code | [docs](https://marketplace.visualstudio.com/items?itemName=riey.erb) |
| `ritwickdey.liveserver` | Launch a development local Server with live reload feature for static & dynamic pages | [docs](https://marketplace.visualstudio.com/items?itemName=ritwickdey.liveserver) |
| `rust-lang.rust-analyzer` | Rust language support for Visual Studio Code | [docs](https://marketplace.visualstudio.com/items?itemName=rust-lang.rust-analyzer) |
| `shd101wyy.markdown-preview-enhanced` | %description% | [docs](https://marketplace.visualstudio.com/items?itemName=shd101wyy.markdown-preview-enhanced) |
| `shopify.ruby-extensions-pack` | An opinionated and auto-configured set of extensions for Ruby development | [docs](https://marketplace.visualstudio.com/items?itemName=shopify.ruby-extensions-pack) |
| `shopify.ruby-lsp` | VS Code plugin for connecting with the Ruby LSP | [docs](https://marketplace.visualstudio.com/items?itemName=shopify.ruby-lsp) |
| `sianglim.slim` | Slim language support based on https://github.com/slim-template/ruby-slim.tmbundle | [docs](https://marketplace.visualstudio.com/items?itemName=sianglim.slim) |
| `sorbet.sorbet-vscode-extension` | Ruby IDE features, powered by Sorbet. | [docs](https://marketplace.visualstudio.com/items?itemName=sorbet.sorbet-vscode-extension) |
| `sporto.rails-go-to-spec` | Switch between code and spec in Rails | [docs](https://marketplace.visualstudio.com/items?itemName=sporto.rails-go-to-spec) |
| `steoates.autoimport` | Automatically finds, parses and provides code actions and code completion for all available imports. Works with Typescript and TSX | [docs](https://marketplace.visualstudio.com/items?itemName=steoates.autoimport) |
| `streetsidesoftware.code-spell-checker` | Spelling checker for source code | [docs](https://marketplace.visualstudio.com/items?itemName=streetsidesoftware.code-spell-checker) |
| `swellaby.rust-pack` | Extension Pack for Rust | [docs](https://marketplace.visualstudio.com/items?itemName=swellaby.rust-pack) |
| `switchcase.code-challenging-timer` | Set yourself a time limit and try to beat it. | [docs](https://marketplace.visualstudio.com/items?itemName=switchcase.code-challenging-timer) |
| `tamasfe.even-better-toml` | Fully-featured TOML support | [docs](https://marketplace.visualstudio.com/items?itemName=tamasfe.even-better-toml) |
| `tomoki1207.pdf` | Display pdf file in VSCode. | [docs](https://marketplace.visualstudio.com/items?itemName=tomoki1207.pdf) |
| `ue.alphabetical-sorter` | Multi line or single line alphabetical sorter. | [docs](https://marketplace.visualstudio.com/items?itemName=ue.alphabetical-sorter) |
| `usernamehw.errorlens` | Improve highlighting of errors, warnings and other language diagnostics. | [docs](https://marketplace.visualstudio.com/items?itemName=usernamehw.errorlens) |
| `vortizhe.simple-ruby-erb` | Provides simple Ruby and ERB language, code snippets and ERB tag helper support for Visual Studio Code without messing with linting or debugging | [docs](https://marketplace.visualstudio.com/items?itemName=vortizhe.simple-ruby-erb) |
| `vscjava.vscode-java-dependency` | %description% | [docs](https://marketplace.visualstudio.com/items?itemName=vscjava.vscode-java-dependency) |
| `vscjava.vscode-java-pack` | Popular extensions for Java development that provides Java IntelliSense, debugging, testing, Maven/Gradle support, project management and more | [docs](https://marketplace.visualstudio.com/items?itemName=vscjava.vscode-java-pack) |
| `wayou.vscode-todo-highlight` | highlight TODOs, FIXMEs, and any keywords, annotations... | [docs](https://marketplace.visualstudio.com/items?itemName=wayou.vscode-todo-highlight) |
| `wix.vscode-import-cost` | Display import/require package size in the editor | [docs](https://marketplace.visualstudio.com/items?itemName=wix.vscode-import-cost) |
| `wmaurer.change-case` | Quickly change the case (camelCase, CONSTANT_CASE, snake_case, etc) of the current selection or current word | [docs](https://marketplace.visualstudio.com/items?itemName=wmaurer.change-case) |
| `xabikos.javascriptsnippets` | Code snippets for JavaScript in ES6 syntax | [docs](https://marketplace.visualstudio.com/items?itemName=xabikos.javascriptsnippets) |
| `xabikos.reactsnippets` | Code snippets for Reactjs development in ES6 syntax | [docs](https://marketplace.visualstudio.com/items?itemName=xabikos.reactsnippets) |
| `yzhang.markdown-all-in-one` | %ext.description% | [docs](https://marketplace.visualstudio.com/items?itemName=yzhang.markdown-all-in-one) |
| `zh9528.file-size` | Show the current text file size in the status bar. | [docs](https://marketplace.visualstudio.com/items?itemName=zh9528.file-size) |
| `zhuangtongfa.material-theme` | Atom's iconic One Dark theme for Visual Studio Code | [docs](https://marketplace.visualstudio.com/items?itemName=zhuangtongfa.material-theme) |

