# ============================================
# Brewfile — true state of this machine
# ============================================
# Regenerate the ground truth with:
#   brew bundle dump --file=/tmp/Brewfile.dump --force
#
# Group markers (# @group NAME) are load-bearing: scripts/package-utils.sh
# parses them for the installer's group picker and --groups flag.
# Keep them, and keep every package under exactly one group.
#
# 'taps' and 'core' are always installed (see _REQUIRED_GROUPS).
# ============================================

# @group taps — Homebrew tap registries (always included)
tap "antoniorodr/memo"
tap "nikitabobko/tap"
tap "steipete/tap"
tap "yakitrak/yakitrak"
tap "felixkratz/formulae", "https://github.com/FelixKratz/homebrew-formulae"


# @group core — Essential CLI tools (always installed)
brew "atuin", restart_service: :changed
brew "bat"
brew "direnv"
brew "eza"
brew "fd"
brew "fzf"
brew "fzf-tab"
brew "gh"
brew "git"
brew "jq"
brew "mas"
brew "mise"
brew "ripgrep"
brew "shellcheck"
brew "starship"
brew "tree"
brew "wget"
brew "zoxide"
brew "zsh-autosuggestions"
brew "zsh-syntax-highlighting"

# @group editors — Code editors & terminals
brew "neovim"
cask "ghostty"
cask "visual-studio-code"
cask "wezterm"
cask "zed"
cask "warp"


# @group window-mgmt — Tiling window manager & status bar
cask "aerospace"
brew "sketchybar"
brew "borders"

# @group terminal-tools — Terminal enhancements & TUI tools
brew "cliclick"
brew "git-delta"
brew "grip"
brew "httpie"
brew "lazydocker"
brew "lazygit"
brew "lnav"
brew "lsd"
brew "mole"
brew "pandoc"
brew "tailspin"
brew "tlrc"
brew "unar"
brew "weasyprint"
brew "zellij"

# @group ai — AI/LLM CLI tooling
brew "gemini-cli"
brew "llm"
brew "summarize"                 # steipete/tap
cask "chatgpt"
cask "claude"
cask "claude-code@latest"
cask "ollama-app"

# @group databases — Database engines & GUI clients
brew "lazysql"
brew "litecli"
brew "mycli"
brew "mysql", restart_service: :changed
brew "pgcli"
brew "pgvector"
brew "postgresql@16", restart_service: :changed, link: true
brew "redis", restart_service: :changed
cask "beekeeper-studio"
cask "postico"
cask "redis-insight"

# @group cloud-deploy — Cloud & deployment CLIs
brew "docker", link: false
brew "render"
brew "supabase"
cask "docker-desktop"

# @group media — Media processing tools
brew "ffmpeg-full"               # superset of ffmpeg; do not also list bare ffmpeg
brew "imagemagick-full", link: true
brew "librsvg"
brew "poppler"
brew "yt-dlp"
cask "vlc"
mas "Gifski", id: 1351639930
mas "GIPHY CAPTURE", id: 668208984

# @group communication — Personal messaging
cask "discord"
cask "signal"
cask "telegram"
mas "WhatsApp", id: 310633997

# @group productivity — Personal productivity
brew "antoniorodr/memo/memo"
brew "yakitrak/yakitrak/obsidian-cli"
brew "steipete/tap/remindctl"
cask "1password"
cask "1password-cli"
cask "notion"
cask "obsidian"
cask "proton-mail"
cask "protonvpn"
cask "proton-pass"
mas "Dashlane", id: 517914548
mas "1Password for Safari", id: 1569813296
mas "2FAS - Two Factor Authentication", id: 6443941139
mas "Tailscale", id: 1475387142
mas "TextSniper", id: 1528890965

# @group work — Enterprise & work apps
cask "slack"
cask "zoom"

# @group languages — Language-specific tools
# Runtimes themselves are mise-managed (.config/mise/config.toml).
# Java is mise temurin-17 — required by android-commandlinetools & Flutter.
brew "cargo-nextest"
brew "uv"
brew "zig"
cask "android-commandlinetools"
# cask "android-platform-tools"  # checksum mismatch upstream 2026-07-31 — adb comes from sdkmanager instead
cask "flutter"

# @group browsers — Web browsers
cask "firefox"
cask "google-chrome"
cask "zen"
mas "DuckDuckGo", id: 663592361

# @group utilities — Misc desktop utilities
cask "balenaetcher"
cask "calibre"
cask "libreoffice"
cask "raspberry-pi-imager"
cask "stremio"
cask "thorium"                   # Thorium Reader (EPUB), not the browser
cask "tuta-mail"
mas "Bandwidth+", id: 490461369
mas "Developer", id: 640199958
mas "Hidden Bar", id: 1452453066
mas "iStat Menus 7", id: 6499559693   # v6's ID (1319778037) is delisted; 7 is a separate listing
mas "Kindle", id: 302584613
mas "LanguageTool", id: 1534275760
mas "LocalSend", id: 1661733229
mas "Menu Bar Calendar", id: 1558360383
mas "Noir", id: 1592917505
mas "Numbers", id: 361304891          # 409203825 is the iOS listing — not installable on macOS
mas "Save to Raindrop.io", id: 1549370672
mas "Tot", id: 1491071483
mas "Xcode", id: 497799835

# @group extras — steipete CLI tools & build libs
brew "steipete/tap/gifgrep"
brew "steipete/tap/peekaboo"
brew "libyaml"                   # ruby-build needs this

# @group fonts — coding (LCD + e-ink) and reading faces
cask "font-fira-code"
cask "font-fira-code-nerd-font"
cask "font-jetbrains-mono"
cask "font-jetbrains-mono-nerd-font"
cask "font-symbols-only-nerd-font"
cask "font-ibm-plex-mono"        # e-ink: sturdy stems, open apertures
cask "font-bitter"               # e-ink reading
cask "font-literata"             # ebook reading

# @group vscode-ext — VS Code extensions
# AI
vscode "anthropic.claude-code"

# Language servers — the diagnostics you review against
vscode "shopify.ruby-extensions-pack"
vscode "jakebecker.elixir-ls"
vscode "phoenixframework.phoenix"
vscode "rust-lang.rust-analyzer"
vscode "dart-code.dart-code"
vscode "dart-code.flutter"
vscode "ms-python.python"
vscode "ms-python.vscode-pylance"
vscode "ms-vscode.vscode-typescript-next"
vscode "koichisasada.vscode-rdbg"

# Review surface
vscode "usernamehw.errorlens"
vscode "eamodio.gitlens"
vscode "github.vscode-pull-request-github"
vscode "github.vscode-github-actions"
vscode "streetsidesoftware.code-spell-checker"

# Formatting / config files
vscode "esbenp.prettier-vscode"
vscode "dbaeumer.vscode-eslint"
vscode "bradlc.vscode-tailwindcss"
vscode "editorconfig.editorconfig"
vscode "mikestead.dotenv"
vscode "redhat.vscode-yaml"
vscode "tamasfe.even-better-toml"
vscode "mechatroner.rainbow-csv"

# Themes — must match your theme switcher
vscode "daltonmenezes.aura-theme"
vscode "enkia.tokyo-night"
vscode "pkief.material-icon-theme"