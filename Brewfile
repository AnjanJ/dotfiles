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
tap "charmbracelet/tap"
tap "cloudflare/cloudflare"
tap "felixkratz/formulae", "https://github.com/FelixKratz/homebrew-formulae"
tap "heroku/brew"
tap "hmbown/deepseek-tui", "https://github.com/Hmbown/homebrew-deepseek-tui"
tap "jorgerojas26/lazysql"
tap "nikitabobko/tap"
tap "openclaw/tap"
tap "render-oss/render"
tap "steipete/tap"
tap "supabase/tap"
tap "yakitrak/yakitrak"

# @group core — Essential CLI tools (always installed)
brew "atuin", restart_service: :changed  # Shell history sync/search (was missing before)
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
cask "alacritty"
cask "cursor"
cask "ghostty"
cask "rubymine"
cask "visual-studio-code"
cask "warp"
cask "wezterm"
cask "zed"

# @group window-mgmt — Tiling window manager & status bar
cask "aerospace"

# @group terminal-tools — Terminal enhancements & TUI tools
brew "cliclick"
brew "git-delta"
brew "gitui"
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
brew "yazi"
brew "zellij"
cask "freeze"

# @group ai — AI/LLM CLI tooling
brew "gemini-cli"
brew "llm"
brew "summarize"                 # steipete/tap
cask "chatgpt"
cask "claude"                    # Claude desktop app
cask "claude-code@latest"
cask "ollama-app"

# @group databases — Database engines & GUI clients
brew "lazysql"
brew "litecli"
brew "mycli"
brew "mysql", restart_service: :changed
brew "pgcli"
brew "pgvector"
brew "postgresql@14", link: false
brew "postgresql@16", restart_service: :changed, link: true
brew "redis", restart_service: :changed
cask "beekeeper-studio"
cask "postico"
cask "redis-insight"

# @group cloud-deploy — Cloud & deployment CLIs
brew "cloudflared"
brew "docker", link: false
brew "flyctl"
brew "heroku"
brew "render"
brew "supabase"
cask "docker-desktop"

# @group media — Media processing tools
brew "ffmpeg-full"               # superset of ffmpeg; do not also list bare ffmpeg
brew "imagemagick-full", link: true
brew "libre"
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
cask "proton-pass"
cask "protonvpn"
cask "raycast"
cask "wispr-flow"
mas "1Password for Safari", id: 1569813296
mas "2FAS - Two Factor Authentication", id: 6443941139
mas "Dashlane", id: 517914548
mas "Tailscale", id: 1475387142
mas "TextSniper", id: 1528890965

# @group work — Enterprise & work apps
cask "slack"
cask "zoom"
mas "Okta Verify", id: 490179405

# @group languages — Language-specific tools
brew "cargo-nextest"
brew "criterion"
brew "openjdk"
brew "openjdk@17"
brew "uv"
brew "zig"
cask "android-commandlinetools"
cask "android-platform-tools"
cask "flutter"

# @group browsers — Web browsers
cask "firefox"
cask "google-chrome"
cask "helium-browser"
cask "thorium"
cask "zen"
mas "DuckDuckGo", id: 663592361

# @group utilities — Misc desktop utilities
cask "adobe-digital-editions"
cask "balenaetcher"
cask "bruno"
cask "calibre"
cask "libreoffice"
cask "raspberry-pi-imager"
cask "requestly"
cask "stremio"
cask "tuta-mail"
mas "Bandwidth+", id: 490461369
mas "Developer", id: 640199958
mas "Hidden Bar", id: 1452453066
mas "iStat Menus", id: 1319778037
mas "Kindle", id: 302584613
mas "LanguageTool", id: 1534275760
mas "LocalSend", id: 1661733229
mas "Menu Bar Calendar", id: 1558360383
mas "Noir", id: 1592917505
mas "Numbers", id: 409203825
mas "Perplexity", id: 6714467650
mas "Save to Raindrop.io", id: 1549370672
mas "Tot", id: 1491071483
mas "Xcode", id: 497799835

# @group extras — steipete/openclaw CLI tools & low-level libs
brew "steipete/tap/bird"
brew "steipete/tap/gifgrep"
brew "steipete/tap/imsg"
brew "steipete/tap/peekaboo"
brew "steipete/tap/sag"
brew "steipete/tap/songsee"
brew "openclaw/tap/wacli"
brew "openclaw/tap/goplaces", link: false
brew "charmbracelet/tap/freeze", link: false
brew "libidn"
brew "libxmlsec1"
brew "libyaml"
brew "openssl@1.1"               # EOL — remove once nothing needs it
brew "putty"
brew "shared-mime-info"
brew "glib"
brew "pango"
cask "openclaw/tap/goplaces", trusted: true

# @group fonts — Nerd Fonts (all currently installed)
cask "font-0xproto-nerd-font"
cask "font-3270-nerd-font"
cask "font-adwaita-mono-nerd-font"
cask "font-agave-nerd-font"
cask "font-anka-coder"
cask "font-anonymice-nerd-font"
cask "font-arimo-nerd-font"
cask "font-atkynson-mono-nerd-font"
cask "font-aurulent-sans-mono-nerd-font"
cask "font-bigblue-terminal-nerd-font"
cask "font-bitstream-vera-sans-mono-nerd-font"
cask "font-blex-mono-nerd-font"
cask "font-cascadia-code"
cask "font-caskaydia-cove-nerd-font"
cask "font-caskaydia-mono-nerd-font"
cask "font-code-new-roman-nerd-font"
cask "font-comic-shanns-mono-nerd-font"
cask "font-commit-mono-nerd-font"
cask "font-cousine-nerd-font"
cask "font-d2coding-nerd-font"
cask "font-daddy-time-mono-nerd-font"
cask "font-dejavu-sans-mono-nerd-font"
cask "font-departure-mono-nerd-font"
cask "font-droid-sans-mono-nerd-font"
cask "font-envy-code-r-nerd-font"
cask "font-fantasque-sans-mono-nerd-font"
cask "font-fira-code"
cask "font-fira-code-nerd-font"
cask "font-fira-mono-nerd-font"
cask "font-geist-mono-nerd-font"
cask "font-go-mono-nerd-font"
cask "font-gohufont-nerd-font"
cask "font-hack"
cask "font-hack-nerd-font"
cask "font-hasklug-nerd-font"
cask "font-heavy-data-nerd-font"
cask "font-hurmit-nerd-font"
cask "font-ibm-plex-mono"
cask "font-im-writing-nerd-font"
cask "font-inconsolata"
cask "font-inconsolata-go-nerd-font"
cask "font-inconsolata-lgc-nerd-font"
cask "font-inconsolata-nerd-font"
cask "font-intone-mono-nerd-font"
cask "font-iosevka-nerd-font"
cask "font-iosevka-term-nerd-font"
cask "font-iosevka-term-slab-nerd-font"
cask "font-jetbrains-mono"
cask "font-jetbrains-mono-nerd-font"
cask "font-lekton-nerd-font"
cask "font-liberation-nerd-font"
cask "font-lilex-nerd-font"
cask "font-m+-nerd-font"
cask "font-martian-mono-nerd-font"
cask "font-meslo-lg-nerd-font"
cask "font-monaspice-nerd-font"
cask "font-monocraft-nerd-font"
cask "font-monofur-nerd-font"
cask "font-monoid-nerd-font"
cask "font-mononoki-nerd-font"
cask "font-noto-nerd-font"
cask "font-opendyslexic-nerd-font"
cask "font-overpass-nerd-font"
cask "font-profont-nerd-font"
cask "font-proggy-clean-tt-nerd-font"
cask "font-recursive-mono-nerd-font"
cask "font-roboto-mono-nerd-font"
cask "font-sauce-code-pro-nerd-font"
cask "font-shure-tech-mono-nerd-font"
cask "font-space-mono-nerd-font"
cask "font-symbols-only-nerd-font"
cask "font-terminess-ttf-nerd-font"
cask "font-tinos-nerd-font"
cask "font-ubuntu-mono-nerd-font"
cask "font-ubuntu-nerd-font"
cask "font-ubuntu-sans-nerd-font"
cask "font-victor-mono-nerd-font"
cask "font-zed-mono-nerd-font"

# @group vscode-ext — VS Code extensions
vscode "aaron-bond.better-comments"
vscode "adpyke.codesnap"
vscode "alefragnani.bookmarks"
vscode "alefragnani.project-manager"
vscode "aliariff.vscode-erb-beautify"
vscode "andrewbutson.vscode-openai"
vscode "anthropic.claude-code"
vscode "batatop.terminal-auto-rename"
vscode "biomejs.biome"
vscode "bradlc.vscode-tailwindcss"
vscode "bung87.rails"
vscode "bung87.vscode-gemfile"
vscode "castwide.solargraph"
vscode "christian-kohler.npm-intellisense"
vscode "christian-kohler.path-intellisense"
vscode "chrmarti.regex"
vscode "daltonmenezes.aura-theme"
vscode "dart-code.dart-code"
vscode "dart-code.flutter"
vscode "davidpallinder.rails-test-runner"
vscode "dbaeumer.vscode-eslint"
vscode "donjayamanne.githistory"
vscode "dotjoshjohnson.xml"
vscode "drewxs.tokyo-night-dark"
vscode "dsznajder.es7-react-js-snippets"
vscode "eamodio.gitlens"
vscode "editorconfig.editorconfig"
vscode "elia.erb-formatter"
vscode "enkia.tokyo-night"
vscode "esbenp.prettier-vscode"
vscode "fill-labs.dependi"
vscode "firsttris.vscode-jest-runner"
vscode "formulahendry.auto-close-tag"
vscode "formulahendry.auto-rename-tag"
vscode "formulahendry.code-runner"
vscode "github.github-vscode-theme"
vscode "github.vscode-github-actions"
vscode "github.vscode-pull-request-github"
vscode "gruntfuggly.todo-tree"
vscode "heybourn.headwind"
vscode "infeng.vscode-react-typescript"
vscode "irongeek.vscode-env"
vscode "jakebecker.elixir-ls"
vscode "kaiwood.endwise"
vscode "kisstkondoros.vscode-codemetrics"
vscode "kisstkondoros.vscode-gutter-preview"
vscode "kohkimakimoto.vscode-mac-dictionary"
vscode "koichisasada.vscode-rdbg"
vscode "lamarcke.kanagawa-black"
vscode "lokalise.i18n-ally"
vscode "mechatroner.rainbow-csv"
vscode "mgmcdermott.vscode-language-babel"
vscode "mhutchie.git-graph"
vscode "mikestead.dotenv"
vscode "mintlify.document"
vscode "misogi.ruby-rubocop"
vscode "mongodb.mongodb-vscode"
vscode "ms-azuretools.vscode-containers"
vscode "ms-azuretools.vscode-docker"
vscode "ms-python.debugpy"
vscode "ms-python.python"
vscode "ms-python.vscode-pylance"
vscode "ms-python.vscode-python-envs"
vscode "ms-vscode.live-server"
vscode "ms-vscode.vscode-typescript-next"
vscode "mtxr.sqltools"
vscode "mtxr.sqltools-driver-mysql"
vscode "mtxr.sqltools-driver-pg"
vscode "mtxr.sqltools-driver-sqlite"
vscode "naumovs.color-highlight"
vscode "noku.rails-run-spec-vscode"
vscode "oderwat.indent-rainbow"
vscode "openai.chatgpt"
vscode "pantajoe.vscode-elixir-credo"
vscode "patbenatar.advanced-new-file"
vscode "phoenixframework.phoenix"
vscode "pkief.material-icon-theme"
vscode "planbcoding.vscode-react-refactor"
vscode "pranaygp.vscode-css-peek"
vscode "redhat.vscode-yaml"
vscode "riey.erb"
vscode "ritwickdey.liveserver"
vscode "rust-lang.rust-analyzer"
vscode "shd101wyy.markdown-preview-enhanced"
vscode "shopify.ruby-extensions-pack"
vscode "shopify.ruby-lsp"
vscode "sianglim.slim"
vscode "sorbet.sorbet-vscode-extension"
vscode "sporto.rails-go-to-spec"
vscode "steoates.autoimport"
vscode "streetsidesoftware.code-spell-checker"
vscode "swellaby.rust-pack"
vscode "switchcase.code-challenging-timer"
vscode "tamasfe.even-better-toml"
vscode "tomoki1207.pdf"
vscode "ue.alphabetical-sorter"
vscode "usernamehw.errorlens"
vscode "vortizhe.simple-ruby-erb"
vscode "vscjava.vscode-java-dependency"
vscode "vscjava.vscode-java-pack"
vscode "wayou.vscode-todo-highlight"
vscode "wix.vscode-import-cost"
vscode "wmaurer.change-case"
vscode "xabikos.javascriptsnippets"
vscode "xabikos.reactsnippets"
vscode "yzhang.markdown-all-in-one"
vscode "zh9528.file-size"
vscode "zhuangtongfa.material-theme"
