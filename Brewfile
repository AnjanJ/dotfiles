# @group taps — Homebrew tap registries (always included)
tap "antoniorodr/memo"
tap "charmbracelet/tap"
tap "cloudflare/cloudflare"
tap "felixkratz/formulae"
tap "heroku/brew"
tap "jorgerojas26/lazysql"
tap "nikitabobko/tap"
tap "render-oss/render"
tap "steipete/tap"
tap "supabase/tap"
tap "yakitrak/yakitrak"

# @group core — Essential CLI tools (always installed)
brew "bat"
brew "direnv"
brew "eza"
brew "fd"
brew "fzf"
brew "fzf-tab"             # Fuzzy tab completion (turns every tab into an fzf menu)
brew "gh"
brew "git"
brew "jq"                  # Industry-standard JSON CLI for piping/filtering
brew "mas"
brew "mise"
brew "ripgrep"
brew "shellcheck"
brew "starship"
brew "tree"
brew "wget"
brew "zoxide"
brew "zsh-autosuggestions"     # Fish-style ghost-text suggestions from history
brew "zsh-syntax-highlighting" # Color commands as you type (catches typos pre-enter)

# @group editors — Code editors & terminals
brew "neovim"
cask "ghostty"
cask "visual-studio-code"
cask "warp"
cask "wezterm"
cask "zed"

# @group window-mgmt — Tiling window manager & status bar
cask "nikitabobko/tap/aerospace"
brew "felixkratz/formulae/borders"
brew "felixkratz/formulae/sketchybar"

# @group terminal-tools — Terminal enhancements & TUI tools
brew "git-delta"
brew "gitui"
brew "httpie"
brew "lazydocker"
brew "lazygit"
brew "lnav"
brew "lsd"
brew "pandoc"
brew "tailspin"
brew "tlrc"
brew "unar"
brew "weasyprint"
brew "yazi"
brew "zellij"

# @group ai — AI/LLM CLI tooling for shell-native AI workflows
brew "llm"                     # Pipe-friendly LLM CLI (Simon Willison) — replaces mods.
                               # Install Ollama plugin once: `llm install llm-ollama`
cask "ollama-app"              # Local LLM runtime (run qwen, llama3, etc. offline)

# @group databases — Database engines & GUI clients
brew "litecli"
brew "lazysql"
brew "mycli"
brew "mysql", restart_service: :changed
brew "pgcli"
brew "pgvector"
brew "postgresql@14", restart_service: :changed
brew "redis", restart_service: :changed
cask "beekeeper-studio"
cask "postico"
cask "redis-insight"

# @group cloud-deploy — Cloud & deployment CLIs
brew "cloudflared"
brew "docker"
brew "flyctl"
brew "heroku"
brew "render"
brew "supabase/tap/supabase"
cask "docker-desktop"

# @group media — Media processing tools
brew "ffmpeg"
brew "ffmpeg-full"
brew "glib"
brew "librsvg"
brew "pango"
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
cask "1password"
cask "1password-cli"
cask "notion"
cask "obsidian"
cask "proton-mail"
cask "proton-pass"
cask "protonvpn"
cask "raycast"
brew "antoniorodr/memo/memo"
brew "yakitrak/yakitrak/obsidian-cli"
mas "1Password for Safari", id: 1569813296
mas "Dashlane", id: 517914548
mas "Tailscale", id: 1475387142

# @group work — Enterprise & work apps
cask "slack"
cask "zoom"
mas "Okta Verify", id: 490179405
mas "Windows App", id: 1295203466

# @group languages — Language-specific tools
brew "criterion"
brew "uv"
brew "zig"
go "cmd/go"
go "cmd/gofmt"

# @group fonts — Nerd Fonts (curated set; was 77, trimmed to 6 most-used)
cask "font-jetbrains-mono-nerd-font" # Active wezterm font (wezterm.lua:17)
cask "font-symbols-only-nerd-font"   # Icon fallback in wezterm (wezterm.lua:21) — required
cask "font-fira-code-nerd-font"      # Industry-standard ligatures
cask "font-geist-mono-nerd-font"     # Vercel font, modern/clean for screenshots
cask "font-iosevka-nerd-font"        # Narrow & dense — useful for logs/wide tables
cask "font-monaspice-nerd-font"      # GitHub Monaspace family

# @group vscode-ext — VS Code extensions
vscode "aaron-bond.better-comments"
vscode "adpyke.codesnap"
vscode "alefragnani.bookmarks"
vscode "alefragnani.project-manager"
vscode "aliariff.vscode-erb-beautify"
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
vscode "davidpallinder.rails-test-runner"
vscode "dbaeumer.vscode-eslint"
vscode "donjayamanne.githistory"
vscode "dotjoshjohnson.xml"
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
vscode "github.copilot"
vscode "github.copilot-chat"
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
vscode "lokalise.i18n-ally"
vscode "mechatroner.rainbow-csv"
vscode "mgmcdermott.vscode-language-babel"
vscode "mhutchie.git-graph"
vscode "mikestead.dotenv"
vscode "mintlify.document"
vscode "misogi.ruby-rubocop"
vscode "ms-azuretools.vscode-containers"
vscode "ms-azuretools.vscode-docker"
vscode "ms-python.debugpy"
vscode "ms-python.python"
vscode "ms-python.vscode-pylance"
vscode "ms-python.vscode-python-envs"
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
vscode "wayou.vscode-todo-highlight"
vscode "wix.vscode-import-cost"
vscode "wmaurer.change-case"
vscode "xabikos.javascriptsnippets"
vscode "xabikos.reactsnippets"
vscode "yzhang.markdown-all-in-one"
vscode "zh9528.file-size"

# @group mac-apps — Mac App Store apps
mas "2FAS - Two Factor Authentication", id: 6443941139
mas "Bandwidth+", id: 490461369
mas "Developer", id: 640199958
mas "DuckDuckGo", id: 663592361
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
mas "TextSniper", id: 1528890965
mas "Tot", id: 1491071483
mas "Xcode", id: 497799835

# @group extras — Miscellaneous utilities
brew "gemini-cli"
brew "libidn"
brew "libre"
brew "libxmlsec1"
brew "libyaml"
brew "openssl@1.1"
brew "putty"
brew "shared-mime-info"
brew "charmbracelet/tap/freeze", link: false
brew "steipete/tap/bird"
brew "steipete/tap/gifgrep"
brew "steipete/tap/goplaces"
brew "steipete/tap/imsg"
brew "steipete/tap/peekaboo"
brew "steipete/tap/remindctl"
brew "steipete/tap/sag"
brew "steipete/tap/songsee"
brew "steipete/tap/summarize"
brew "steipete/tap/wacli"
cask "android-platform-tools"
cask "bruno"
cask "claude-code"
cask "firefox"
cask "freeze"
cask "requestly"
cask "zen"
