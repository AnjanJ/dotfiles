#!/usr/bin/env bash

# ============================================
# DOTFILES INSTALLATION SCRIPT
# ============================================
# One-command setup for macOS development environment
#
# Usage:
#   bash install.sh                          # Non-interactive, sensible defaults
#   bash install.sh --interactive            # Prompt for every choice
#   bash install.sh --name "AJ" --email "aj@example.com"
#   bash <(curl -fsSL https://raw.githubusercontent.com/AnjanJ/dotfiles/main/install.sh)
#
# Flags:
#   --interactive       Prompt for every choice (original behavior)
#   --name "Name"       Git user.name
#   --email "a@b.com"   Git personal email
#   --work-email "x@y"  Git work email (enables work identity)
#   --work-dir "~/work/code" Work directory (default: ~/work/code)
#   --theme <name>      Theme: tokyo-night, aura, catppuccin, or a light
#                       one: catppuccin-latte, flexoki-light (default: tokyo-night)
#   --ssh <mode>        SSH: 1password, existing, generate, skip
#                       Default: auto-detect 1Password SSH agent if running,
#                       otherwise skip. Force with --ssh 1password.
#   --groups "a,b,c"    Package groups to install (comma-separated)
#   --no-macos-defaults Skip macOS defaults
#   --no-runtimes       Skip `mise install` (Erlang and Rust compile from
#                       source; run `mise install` later)
#   --answers <file>    JSON answers file for unattended installs (see
#                       docs/dotfiles-answers.example.json); also read from
#                       DOTFILES_ANSWERS or ~/.dotfiles-answers.json
#   --force             Force reinstall even if already configured
#   --help              Show this help
#
# Environment variables (flags take precedence):
#   DOTFILES_GIT_NAME, DOTFILES_GIT_EMAIL, DOTFILES_WORK_EMAIL
#   DOTFILES_WORK_DIR, DOTFILES_THEME, DOTFILES_SSH_MODE, DOTFILES_GROUPS
#   DOTFILES_NO_SUDO=1 (never ask for a password), DOTFILES_NO_RUNTIMES=1
#   DOTFILES_ANSWERS=<file>
#
# Precedence: flags, then environment, then the answers file, then defaults.
# ============================================

# ── Bootstrap: handle curl-pipe-bash ──────────
# If this script is piped via curl, clone the repo first and re-exec.
_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd)"

if [[ ! -f "$_SCRIPT_DIR/scripts/_helpers.sh" ]]; then
    echo ""
    echo "Bootstrapping: dotfiles repo not found locally..."
    DOTFILES_REPO="https://github.com/AnjanJ/dotfiles.git"
    DOTFILES_TARGET="$HOME/dotfiles"

    if ! command -v git &>/dev/null; then
        echo "Git not found. Installing Xcode Command Line Tools..."
        xcode-select --install 2>/dev/null || true
        echo "Please re-run this script after Xcode tools finish installing."
        exit 1
    fi

    if [[ -d "$DOTFILES_TARGET/.git" ]]; then
        echo "Dotfiles already cloned at $DOTFILES_TARGET, pulling latest..."
        git -C "$DOTFILES_TARGET" pull origin main 2>/dev/null || true
    else
        git clone "$DOTFILES_REPO" "$DOTFILES_TARGET"
    fi

    exec bash "$DOTFILES_TARGET/install.sh" "$@"
fi

set -euo pipefail

# Homebrew's env hints add several lines of noise after every install.
# We print our own progress; theirs just buries it.
export HOMEBREW_NO_ENV_HINTS=1

# ── Abnormal-exit reporting ───────────────────
# Under `set -e` any unhandled failure kills the script silently — you get
# a returned prompt and no idea which step died. These traps name the step,
# line, and command so a failed run is diagnosable instead of a mystery.
#
# Deliberately plain `echo` rather than print_warning: these traps are
# installed BEFORE scripts/_helpers.sh is sourced, so on an early failure
# the pretty printers don't exist yet and calling them would fail inside
# the trap — losing the very message we're trying to surface.
#
# Note: SIGKILL (e.g. the OOM killer) cannot be trapped. If a run dies with
# no output from any of these, that absence is itself the diagnosis —
# suspect memory pressure, not a bug in this script.
_CURRENT_STEP="startup"
_INSTALL_COMPLETE=false

_on_error() {
    local exit_code=$?
    local line_no=$1
    echo "" >&2
    echo "  ==========================================" >&2
    echo "  ❌ INSTALL FAILED" >&2
    echo "  ==========================================" >&2
    echo "" >&2
    echo "    Step:     $_CURRENT_STEP" >&2
    echo "    Line:     $line_no of install.sh" >&2
    echo "    Command:  ${BASH_COMMAND}" >&2
    echo "    Exit:     $exit_code" >&2
    echo "" >&2
    echo "    This script is idempotent — fix the cause and re-run." >&2
    echo "    Downloads are cached, so a re-run resumes rather than restarts." >&2
    echo "" >&2
}

_on_exit() {
    local exit_code=$?
    # Stop the sudo keep-alive (set later, once sudo is obtained) so no
    # background process outlives the script.
    [[ -n "${_SUDO_KEEPALIVE_PID:-}" ]] && kill "$_SUDO_KEEPALIVE_PID" 2>/dev/null
    if [[ "$_INSTALL_COMPLETE" == false && $exit_code -eq 0 ]]; then
        # Exited cleanly but never reached the end — a subshell called
        # exit, or the process was signalled.
        echo "" >&2
        echo "  ⚠️  Install ended early during: $_CURRENT_STEP" >&2
        echo "     Re-run to continue — nothing is half-applied." >&2
        echo "" >&2
    fi
}

_on_interrupt() {
    echo "" >&2
    echo "  ⚠️  Interrupted during: $_CURRENT_STEP" >&2
    echo "     Re-run to continue — nothing is half-applied." >&2
    echo "" >&2
    exit 130
}

trap '_on_error $LINENO' ERR
trap _on_exit EXIT
trap _on_interrupt INT TERM

# ── Parse Arguments ───────────────────────────

INTERACTIVE=false
FORCE_INSTALL=false
APPLY_MACOS_DEFAULTS=true
INSTALL_RUNTIMES=true
[[ -n "${DOTFILES_NO_RUNTIMES:-}" ]] && INSTALL_RUNTIMES=false

# Env var defaults (flags override these)
GIT_NAME="${DOTFILES_GIT_NAME:-}"
GIT_EMAIL="${DOTFILES_GIT_EMAIL:-}"
GIT_WORK_EMAIL="${DOTFILES_WORK_EMAIL:-}"
WORK_DIR="${DOTFILES_WORK_DIR:-}"
SELECTED_THEME="${DOTFILES_THEME:-}"
SSH_MODE="${DOTFILES_SSH_MODE:-}"
SELECTED_GROUPS="${DOTFILES_GROUPS:-}"
ANSWERS_FILE="${DOTFILES_ANSWERS:-}"

_CURRENT_STEP="parsing arguments"

while [[ $# -gt 0 ]]; do
    case $1 in
        --interactive) INTERACTIVE=true; shift ;;
        --force) FORCE_INSTALL=true; shift ;;
        --name) GIT_NAME="$2"; shift 2 ;;
        --email) GIT_EMAIL="$2"; shift 2 ;;
        --work-email) GIT_WORK_EMAIL="$2"; shift 2 ;;
        --work-dir) WORK_DIR="$2"; shift 2 ;;
        --theme) SELECTED_THEME="$2"; shift 2 ;;
        --ssh) SSH_MODE="$2"; shift 2 ;;
        --groups) SELECTED_GROUPS="$2"; shift 2 ;;
        --no-macos-defaults) APPLY_MACOS_DEFAULTS=false; shift ;;
        --no-runtimes) INSTALL_RUNTIMES=false; shift ;;
        --answers) ANSWERS_FILE="$2"; shift 2 ;;
        --help)
            # Print the usage block from the header
            sed -n '/^# Usage:/,/^# ====/{ /^# ====/d; s/^# //; s/^#//; p; }' "$0"
            _INSTALL_COMPLETE=true   # --help is a legitimate early exit
            exit 0
            ;;
        *)
            echo "Warning: unknown option '$1' ignored (see --help)" >&2
            shift
            ;;
    esac
done

# ── Answers file (below flags and environment) ──
# Named explicitly, or ~/.dotfiles-answers.json when that exists. A
# named file that is missing or invalid stops the run: an unattended
# install that silently fell back to prompts or defaults is worse.
_CURRENT_STEP="reading the answers file"
if [[ -z "$ANSWERS_FILE" && -f "$HOME/.dotfiles-answers.json" ]]; then
    ANSWERS_FILE="$HOME/.dotfiles-answers.json"
fi
if [[ -n "$ANSWERS_FILE" ]]; then
    source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/scripts/install-answers.sh"
    install_answers_load "$ANSWERS_FILE" || exit 1
fi

# Export for sub-scripts
export INTERACTIVE FORCE_INSTALL GIT_NAME GIT_EMAIL GIT_WORK_EMAIL WORK_DIR SSH_MODE SELECTED_GROUPS

# ── Setup ─────────────────────────────────────

_CURRENT_STEP="loading helpers"

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Shared colors & print functions
source "$DOTFILES_DIR/scripts/_helpers.sh"

# Check if running on macOS
if [[ "$(uname)" != "Darwin" ]]; then
    print_error "This script is only for macOS"
    _INSTALL_COMPLETE=true   # deliberate exit, not a crash
    exit 1
fi

# ── Sudo: ask once, hold for the whole run ────
# Several casks run `sudo /usr/sbin/installer` internally. macOS expires the
# sudo timestamp after ~5 minutes, so on a long install you get re-prompted
# repeatedly — and worse, those prompts appear mid-`brew bundle` where output
# is interleaved and it isn't obvious anything is waiting.
#
# So: prompt ONCE here, up front, where the ask is expected. Then refresh the
# existing timestamp in the background so it never expires mid-run.
#
# The keep-alive re-runs `sudo -n true`, which only refreshes an ALREADY
# valid timestamp and can never itself prompt. It exits when the parent does,
# so no process is left holding root after the script ends. We deliberately
# do NOT cache a password anywhere — the timestamp is the mechanism macOS
# provides for exactly this, and stashing a password would be far worse.
_CURRENT_STEP="requesting sudo access"

_SUDO_KEEPALIVE_PID=""

if sudo -n true 2>/dev/null; then
    print_success "sudo already authenticated"
    _SUDO_OK=true
else
    echo ""
    print_step "Some casks need administrator rights to install."
    print_step "Enter your macOS password once — it won't be asked again."
    print_step "(Skip with Ctrl-C only if you don't want those casks; or set"
    print_step " DOTFILES_NO_SUDO=1 to never be asked.)"
    echo ""
    if [[ -n "${DOTFILES_NO_SUDO:-}" ]]; then
        _SUDO_OK=false
        print_warning "DOTFILES_NO_SUDO set — skipping casks that need an installer"
    elif sudo -v; then
        _SUDO_OK=true
    else
        _SUDO_OK=false
        print_warning "No sudo access — casks needing an installer will be skipped"
    fi
fi

if [[ "${_SUDO_OK:-false}" == true ]]; then
    # Refresh every 60s until the parent exits.
    while true; do
        sudo -n true 2>/dev/null || exit
        sleep 60
        kill -0 "$$" 2>/dev/null || exit
    done &
    _SUDO_KEEPALIVE_PID=$!
    # Cleanup is handled inside _on_exit — installing a second EXIT trap here
    # would REPLACE the existing one and silence the early-exit reporting.
fi

echo ""
echo ""
echo "  AJ's Dotfiles Installation"
echo "  =========================================="
echo ""
echo "  This will install:"
echo "    - Homebrew packages"
echo "    - Aerospace (window manager) + sketchybar + borders"
echo "    - Ghostty terminal"
echo "    - Neovim + AstroNvim"
echo "    - Zellij (terminal multiplexer)"
echo "    - Zed editor (settings, snippets, tasks)"
echo "    - Starship prompt"
echo "    - Shell configuration (zsh + autosuggestions + syntax-highlighting + fzf-tab)"
echo "    - AI CLI tooling (llm + ollama + gh copilot)"
echo "    - Git smart defaults + identity setup"
echo "    - SSH keys (1Password, import, generate, or existing)"
echo "    - Custom scripts (~/bin)"
echo "    - Theme: Tokyo Night, Aura, or Catppuccin (your choice!)"
echo ""
echo "  Idempotent -- safe to re-run anytime"
echo ""
echo "  Mac App Store apps are skipped unless you're signed in."
echo "  Xcode (~15GB) is opt-in and never blocks the rest of the install."
echo ""
echo "  This takes a while. The two slow parts are the Homebrew download"
echo "  phase and step 6, where Erlang and Rust compile from source."
echo ""
echo ""

if [[ "$INTERACTIVE" == true ]]; then
    read -r -p "Continue with installation? (y/n) " -n 1
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_warning "Installation cancelled"
        _INSTALL_COMPLETE=true   # user cancelled deliberately
        exit 1
    fi
fi

echo ""
print_step "Dotfiles directory: $DOTFILES_DIR"

# ============================================
# THEME SELECTION
# ============================================
_CURRENT_STEP="theme selection"

source "$DOTFILES_DIR/scripts/theme-utils.sh"

if [[ -z "$SELECTED_THEME" ]]; then
    if [[ "$INTERACTIVE" == true ]]; then
        # --interactive: always let the user choose
        SELECTED_THEME=$(prompt_theme_choice)
    elif [[ -f "$HOME/.dotfiles-theme" ]]; then
        # Re-run without --interactive: keep previous choice
        SELECTED_THEME=$(get_current_theme)
    else
        # Fresh install without --interactive: take the documented default
        # so `bash <(curl ...)` really is non-interactive. Change later with
        # `dotfiles theme <name>` or pass --theme / DOTFILES_THEME.
        SELECTED_THEME="tokyo-night"
    fi
fi

if ! validate_theme "$SELECTED_THEME"; then
    print_warning "Invalid theme '$SELECTED_THEME', using tokyo-night"
    SELECTED_THEME="tokyo-night"
fi

echo ""
print_success "Theme: $SELECTED_THEME"

# ============================================
# 1. INSTALL HOMEBREW
# ============================================
_CURRENT_STEP="Step 1: installing Homebrew"
echo ""
print_step "Step 1: Installing Homebrew..."

if ! command -v brew &> /dev/null; then
    print_warning "Homebrew not found. Installing..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Add Homebrew to PATH for Apple Silicon
    if [[ $(uname -m) == 'arm64' ]]; then
        if ! grep -q '/opt/homebrew/bin/brew shellenv' ~/.zprofile 2>/dev/null; then
            # shellcheck disable=SC2016
            echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
        fi
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
    print_success "Homebrew installed"
else
    print_success "Homebrew already installed ($(brew --version | head -1))"
fi

# ── Rosetta 2 (Apple Silicon only) ────────────
# Some casks ship Intel-only installer packages — adobe-digital-editions is
# one. Without Rosetta, `/usr/sbin/installer` fails with "This package
# requires Rosetta 2", and because that failure happens INSIDE the cask's
# sudo installer it looked like a password problem rather than an
# architecture one.
#
# Installing it up front is cheap (~1s if already present) and turns an
# unavoidable failure into a working install.
_CURRENT_STEP="Step 1b: Rosetta 2"

if [[ "$(uname -m)" == "arm64" ]]; then
    # oahd is the Rosetta daemon — running means Rosetta is installed.
    if /usr/bin/pgrep -q oahd; then
        print_success "Rosetta 2 already installed"
    else
        echo ""
        print_step "Step 1b: Installing Rosetta 2 (needed by Intel-only casks)..."
        if sudo softwareupdate --install-rosetta --agree-to-license; then
            print_success "Rosetta 2 installed"
        else
            print_warning "Rosetta 2 install failed — Intel-only casks will be skipped"
        fi
    fi
fi

# ============================================
# 2. INSTALL PACKAGES FROM BREWFILE
# ============================================
_CURRENT_STEP="Step 2: installing Homebrew packages"
echo ""
print_step "Step 2: Installing packages from Brewfile..."

source "$DOTFILES_DIR/scripts/package-utils.sh"

# Determine which groups to install
_PACKAGE_SELECTIONS=""

if [[ -n "$SELECTED_GROUPS" ]]; then
    # --groups flag: convert comma-separated list to selections format
    IFS=',' read -ra _groups_arr <<< "$SELECTED_GROUPS"
    for g in "${_groups_arr[@]}"; do
        _PACKAGE_SELECTIONS+="+${g}"$'\n'
    done
    _PACKAGE_SELECTIONS="${_PACKAGE_SELECTIONS%$'\n'}"
    save_selected_groups "$_PACKAGE_SELECTIONS"
elif [[ "$INTERACTIVE" == true ]]; then
    _PACKAGE_SELECTIONS=$(prompt_package_selection "$DOTFILES_DIR/Brewfile")
elif [[ -f "$PACKAGES_STATE_FILE" ]]; then
    _PACKAGE_SELECTIONS=$(get_saved_groups)
fi

cd "$DOTFILES_DIR"

# Failures are collected rather than just warned about, so the summary at
# the very end can tell you exactly what to retry. On a fresh Mac, cask and
# mas entries fail routinely (not signed into the App Store, network blips),
# and those errors otherwise scroll past hundreds of lines of brew output.
FAILED_PACKAGES=()

# Xcode is ~15GB from the App Store and frequently stalls or fails on a
# fresh machine. Pull it out of the main bundle so it can't hold up the
# rest of the install; it gets its own opt-in step below.
XCODE_ENTRY=$(grep -E '^mas "Xcode"' "$DOTFILES_DIR/Brewfile" || true)

# Build the Brewfile we'll actually install from.
if [[ -n "$_PACKAGE_SELECTIONS" ]]; then
    _INSTALL_BREWFILE=$(generate_filtered_brewfile "$DOTFILES_DIR/Brewfile" "$_PACKAGE_SELECTIONS")
    _BREWFILE_IS_TEMP=true
else
    _INSTALL_BREWFILE=$(mktemp "${TMPDIR:-/tmp}/Brewfile.XXXXXX")
    cp "$DOTFILES_DIR/Brewfile" "$_INSTALL_BREWFILE"
    _BREWFILE_IS_TEMP=true
fi

# mas entries only work when the App Store is signed in — strip them
# otherwise, rather than letting all 24 fail one by one.
#
# Detection differs by mas major version: `mas account` was REMOVED in
# mas 2.x (exits 64 "Unexpected argument"), so relying on it alone would
# report "not signed in" on every modern install and silently skip every
# App Store app. `mas config` prints a two-letter storefront when an
# account is active.
appstore_ready() {
    command -v mas &>/dev/null || return 1
    mas config 2>/dev/null | grep -qE '^store [^ ]* [A-Z]{2}' && return 0
    mas account &>/dev/null && return 0   # mas 1.x fallback
    return 1
}

# mas ships in the core group, but appstore_ready() needs it to already
# exist. On a freshly-wiped machine it doesn't — Homebrew itself was only
# installed moments ago in step 1 — so the check below would report "not
# signed in" and silently strip every App Store app on the first run.
# This only ever reproduces on a genuinely fresh box, which is why it
# survived so long. Install mas up front.
if ! command -v mas &>/dev/null; then
    print_step "Installing mas first (needed to detect App Store sign-in)..."
    brew install mas || print_warning "Could not install mas — App Store apps will be skipped"
fi

APPSTORE_READY=false
if appstore_ready; then
    APPSTORE_READY=true
fi

# ── Trust third-party taps ────────────────────
# Homebrew 6 refuses to load formulae or casks from untrusted third-party
# taps, and a single refusal aborts the ENTIRE fetch phase — so one
# untrusted tap blocks all ~100 packages. Trusting them up front turns a
# cascade of confusing failures into a no-op.
#
# Trust is not a formality: a tap is arbitrary Ruby that brew runs with
# your privileges. Only taps declared in this repo's own Brewfile are
# trusted here — review a tap before you add it, not after.
_CURRENT_STEP="Step 2a: trusting third-party taps"
echo ""
print_step "Step 2a: Trusting third-party taps declared in the Brewfile..."

while IFS= read -r _tap; do
    [[ -z "$_tap" ]] && continue
    if brew trust "$_tap" &>/dev/null; then
        print_success "Trusted tap: $_tap"
    else
        print_warning "Could not trust tap: $_tap (its packages may be skipped)"
    fi
done < <(grep -E '^tap "' "$_INSTALL_BREWFILE" | sed 's/^tap "\([^"]*\)".*/\1/' || true)

# Always drop Xcode from the bundle — it's handled separately.
_CURRENT_STEP="Step 2: installing Homebrew packages"
echo ""
_stripped=$(mktemp "${TMPDIR:-/tmp}/Brewfile.XXXXXX")
if [[ "$APPSTORE_READY" == true ]]; then
    grep -vE '^mas "Xcode"' "$_INSTALL_BREWFILE" > "$_stripped"
    print_success "App Store signed in — Mac App Store apps will be installed"
else
    grep -vE '^mas ' "$_INSTALL_BREWFILE" > "$_stripped"
    _mas_count=$(grep -cE '^mas ' "$_INSTALL_BREWFILE" || true)
    print_warning "Not signed in to the App Store — skipping $_mas_count Mac App Store app(s)"
    print_warning "  Sign in via App Store.app, then re-run: brew bundle install --file=Brewfile"
fi
mv "$_stripped" "$_INSTALL_BREWFILE"

_PKG_TOTAL=$(grep -cE '^(brew|cask|mas|vscode) ' "$_INSTALL_BREWFILE" || true)
print_step "Installing $_PKG_TOTAL packages."
print_warning "Homebrew downloads everything before installing anything, so the"
print_warning "first several minutes are quiet. That is not a hang."
echo ""

# ── Per-entry fallback ────────────────────────
# `brew bundle` fetches EVERYTHING before installing ANYTHING, and one bad
# fetch aborts the whole phase. A single upstream checksum mismatch (a
# vendor republishing a download without a version bump, say) therefore
# blocks all ~100 packages — you end up with a fully configured machine
# and no tools on it.
#
# So: try the fast bulk path first, and if it fails, install entry by entry
# so one broken package costs exactly one package. Each entry is handed
# back to `brew bundle` as a single-line Brewfile rather than parsed into
# `brew install` — that preserves per-entry options like `link: false` and
# `restart_service: :changed`, which a naive parser would drop.
install_entries_individually() {
    local brewfile="$1"
    local line name kind tmp taps
    local done_count=0

    taps=$(grep -E '^tap "' "$brewfile" || true)

    while IFS= read -r line; do
        [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
        [[ "$line" =~ ^(brew|cask|mas|vscode)[[:space:]] ]] || continue

        kind="${line%% *}"
        # Entries look like: kind "name"[, opts]. Strip up to the opening
        # quote, then everything from the closing one — native expansions
        # rather than a sed subprocess (and one less fork per package).
        name="${line#*\"}"
        name="${name%%\"*}"
        done_count=$((done_count + 1))

        printf "  [%d/%d] %-6s %-40s " "$done_count" "$_PKG_TOTAL" "$kind" "$name"

        tmp=$(mktemp "${TMPDIR:-/tmp}/Brewfile.one.XXXXXX")
        # Carry the taps over so tapped formulae still resolve.
        printf '%s\n' "$taps" > "$tmp"
        echo "$line" >> "$tmp"

        # Keep the output so a failure can be classified rather than just
        # counted — "why" is the thing that was missing when these failed.
        local log
        log=$(mktemp "${TMPDIR:-/tmp}/brew.one.log.XXXXXX")

        if brew bundle install --file="$tmp" &>"$log"; then
            echo "ok"
        else
            local reason=""
            if grep -q "No apps found in the App Store" "$log"; then
                reason=" — App Store ID is dead/region-locked; look it up with: mas search '$name'"
            elif grep -qi "requires Rosetta" "$log"; then
                reason=" — Intel-only package; run: sudo softwareupdate --install-rosetta"
            elif grep -qi "SHA256 mismatch\|checksum" "$log"; then
                reason=" — upstream checksum mismatch (vendor republished); retry later"
            elif grep -qi "is already installed" "$log"; then
                reason=" — already installed outside Homebrew"
            fi
            echo "FAILED${reason}"
            FAILED_PACKAGES+=("$kind $name${reason}")
        fi
        rm -f "$tmp" "$log"
    done < "$brewfile"
}

if brew bundle install --file="$_INSTALL_BREWFILE" --verbose; then
    print_success "All $_PKG_TOTAL packages installed"
else
    echo ""
    print_warning "Bulk install failed — in brew bundle, one bad package aborts"
    print_warning "the whole batch. Retrying one at a time so a single failure"
    print_warning "cannot block the other $((_PKG_TOTAL - 1)). Slower, but complete."
    echo ""
    install_entries_individually "$_INSTALL_BREWFILE"
fi

[[ "$_BREWFILE_IS_TEMP" == true ]] && rm -f "$_INSTALL_BREWFILE"

# ── Xcode (opt-in, separate) ──────────────────
_CURRENT_STEP="Step 2b: Xcode (optional)"

if [[ -n "$XCODE_ENTRY" && "$APPSTORE_READY" == true ]]; then
    if [[ -d "/Applications/Xcode.app" ]]; then
        print_success "Xcode already installed"
    else
        _install_xcode=false
        if [[ "$INTERACTIVE" == true ]]; then
            read -r -p "Install Xcode now? ~15GB, can take 30+ min (y/n) " -n 1
            echo
            [[ $REPLY =~ ^[Yy]$ ]] && _install_xcode=true
        fi

        if [[ "$_install_xcode" == true ]]; then
            print_step "Installing Xcode (~15GB — this will take a while)..."
            if mas install 497799835; then
                print_success "Xcode installed"
            else
                FAILED_PACKAGES+=("Xcode (mas 497799835) — install from the App Store manually")
            fi
        else
            print_warning "Skipped Xcode (~15GB). Install later: mas install 497799835"
        fi
    fi
fi

# ============================================
# 3. CREATE NECESSARY DIRECTORIES
# ============================================
# Only directories that are NOT themselves symlink targets.
#
# Pre-creating ~/.config/nvim et al. used to break step 4: `ln -sf` onto an
# existing directory creates the link INSIDE it (~/.config/nvim/nvim ->
# repo) instead of replacing it. Step 4 reported success, the health check
# then reported "not a symlink", and those configs silently never applied.
# create_symlink now also handles a pre-existing real directory, but not
# creating them in the first place is the actual fix.
# ============================================
_CURRENT_STEP="Step 3: creating config directories"
echo ""
print_step "Step 3: Creating configuration directories..."

mkdir -p ~/.config/zed/snippets
mkdir -p ~/bin

print_success "Directories created"

# ============================================
# 4. CREATE SYMLINKS
# ============================================
# Deliberately BEFORE `mise install` (step 6). Installing runtimes
# compiles Erlang and Rust from source — that can take 30+ minutes and
# fails outright without the right build deps. Under `set -euo pipefail`
# a failed compile aborts the whole script, so when this ran first you
# ended up with packages but NO configs on a freshly-wiped machine.
#
# Symlinking is fast and near-impossible to fail, so it goes first: the
# worst case is now "runtimes missing" (rerun `mise install`) instead of
# "nothing configured".
# ============================================
_CURRENT_STEP="Step 4: creating symlinks"
echo ""
print_step "Step 4: Creating symlinks..."

# Helper function to create symlink with idempotent backup
create_symlink() {
    local source="$1"
    local target="$2"
    local name="$3"

    if [ -L "$target" ] && [ "$(readlink "$target")" = "$source" ] && [ "$FORCE_INSTALL" = false ]; then
        print_success "$name already linked"
        return 0
    fi

    backup_if_needed "$target"

    # A real (non-symlink) directory at the target must be REMOVED, not
    # linked over: `ln -sf dir existing_dir` silently nests the link inside
    # it. backup_if_needed has already copied it to $BACKUP_DIR, so this is
    # recoverable. This also repairs machines broken by the old step-3
    # mkdir behaviour.
    if [ -d "$target" ] && [ ! -L "$target" ]; then
        rm -rf "$target"
        print_warning "$name: replaced existing directory (backed up)"
    fi

    mkdir -p "$(dirname "$target")"
    ln -sf "$source" "$target"
    print_success "$name linked"
}

# The full list of managed links lives in scripts/symlink-map.sh —
# the single source of truth shared with update/sync/doctor/health.
source "$DOTFILES_DIR/scripts/symlink-map.sh"
dotfiles_for_each_link create_symlink

print_success "All symlinks processed"

# ============================================
# 5. APPLY SELECTED THEME
# ============================================
_CURRENT_STEP="Step 5: applying $SELECTED_THEME theme"
echo ""
print_step "Step 5: Applying $SELECTED_THEME theme everywhere..."

source "$DOTFILES_DIR/scripts/apply-theme.sh"
apply_theme "$SELECTED_THEME"

# ============================================
# 6. SET UP MISE (VERSION MANAGER)
# ============================================
# Runs AFTER symlinks + theme so a source-compile failure can't leave
# the machine unconfigured. See the note on step 4.
_CURRENT_STEP="Step 6: mise runtimes (Erlang/Rust compile from source)"
echo ""
print_step "Step 6: Setting up mise (version manager)..."

# mise was installed by brew bundle moments ago, but this shell's PATH was
# resolved before that. Re-evaluate brew's shellenv rather than reporting
# "mise: command not found" and skipping every runtime.
if ! command -v mise &>/dev/null && [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
    hash -r
fi

if [[ "$INSTALL_RUNTIMES" == false ]]; then
    # The CI end-to-end install and anyone who wants configs now and
    # compilers later. Symlinks and theme are already in place above.
    print_warning "Skipping language runtimes (--no-runtimes). Later: mise install"
elif ! command -v mise &>/dev/null; then
    print_warning "mise not on PATH — skipping runtime install"
    print_warning "  Restart your shell, then run: mise install"
    FAILED_PACKAGES+=("mise runtimes — mise itself was unavailable; run 'mise install' later")
elif [[ ! -e "$HOME/.config/mise/config.toml" ]]; then
    print_warning "mise config not found — skipping runtime install"
else
    # Trust the config file (mise refuses to read untrusted configs)
    mise trust "$HOME/.config/mise/config.toml" 2>/dev/null || true

    print_step "Installing language runtimes..."
    print_warning "Erlang and Rust compile from source. Expect 30+ minutes and"
    print_warning "long silences between compiler output — that is not a hang."
    echo ""

    # Deliberately NOT fatal: `set -e` would abort the entire install on a
    # single failed compile. Everything below this point still runs.
    if mise install --verbose; then
        print_success "Language runtimes installed"
        echo ""
        mise list 2>/dev/null || true
    else
        print_warning "Some runtimes failed to build. Everything else continues."
        print_warning "  Retry individually, e.g.: mise install erlang"
        FAILED_PACKAGES+=("mise runtimes — rerun 'mise install' to see which")
    fi
fi

# ============================================
# 7. SET UP NEOVIM
# ============================================
_CURRENT_STEP="Step 7: Neovim"
echo ""
print_step "Step 7: Setting up Neovim..."

# AstroNvim will auto-install on first launch
print_success "Neovim configuration linked (plugins will install on first launch)"

# ============================================
# 7b. SET UP AI CLI (llm + ollama)
# ============================================
# Brewfile already installed `llm` and `ollama`. We need to:
#   - Wire `llm` to talk to Ollama (one-time plugin install, fast)
# We deliberately DO NOT pull models here (each is multi-GB) or set API
# keys (private). Those are surfaced in "Next Steps" at end of install.
_CURRENT_STEP="Step 7b: wiring llm <-> ollama"
echo ""
print_step "Step 7b: Wiring llm <-> ollama..."

if command -v llm &>/dev/null; then
    if ! llm plugins 2>/dev/null | grep -q llm-ollama; then
        print_step "Installing llm-ollama plugin..."
        llm install llm-ollama && print_success "llm-ollama plugin installed"
    else
        print_success "llm-ollama plugin already installed"
    fi
else
    print_warning "llm not found — skipping plugin install (check Brewfile)"
fi

# ============================================
# 8. SET UP SHELL
# ============================================
_CURRENT_STEP="Step 8: shell setup"
echo ""
print_step "Step 8: Setting up shell..."

# Make zsh the default shell if it isn't already.
#
# Deliberately match on the *basename*, not the full path: macOS ships
# /bin/zsh while `which zsh` resolves to /opt/homebrew/bin/zsh. Comparing
# full paths is true on every run, so the old check called chsh every time
# and blocked the whole install on an interactive password prompt.
if [[ "$SHELL" != */zsh ]]; then
    print_warning "Setting zsh as default shell (may prompt for your password)..."
    if chsh -s "$(command -v zsh)"; then
        print_success "Default shell changed to zsh"
    else
        print_warning "Could not change shell automatically. Run: chsh -s $(command -v zsh)"
    fi
else
    print_success "zsh is already the default shell"
fi

# ============================================
# 8b. GIT CONFIGURATION
# ============================================
_CURRENT_STEP="Step 8b: git configuration"
source "$DOTFILES_DIR/scripts/setup-git.sh"
setup_git

# ============================================
# 8c. SSH CONFIGURATION
# ============================================
_CURRENT_STEP="Step 8c: SSH configuration"
source "$DOTFILES_DIR/scripts/setup-ssh.sh"
setup_ssh

# ============================================
# 9. MACOS DEFAULTS
# ============================================
_CURRENT_STEP="Step 9: macOS defaults"
echo ""
if [[ "$INTERACTIVE" == true ]]; then
    read -r -p "Apply recommended macOS defaults? (y/n) " -n 1
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        APPLY_MACOS_DEFAULTS=false
    fi
fi

if [[ "$APPLY_MACOS_DEFAULTS" == true ]]; then
    print_step "Step 9: Applying macOS defaults..."

    # Keyboard settings
    defaults write NSGlobalDomain KeyRepeat -int 2
    defaults write NSGlobalDomain InitialKeyRepeat -int 15

    # Appearance
    defaults write NSGlobalDomain AppleInterfaceStyle -string "Dark"

    # Finder settings
    defaults write com.apple.finder ShowPathbar -bool true
    defaults write com.apple.finder ShowStatusBar -bool true
    defaults write com.apple.finder ShowSidebar -bool true
    defaults write com.apple.finder _FXShowPosixPathInTitle -bool true
    defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"
    defaults write com.apple.finder AppleShowAllFiles -bool true
    defaults write com.apple.finder NewWindowTarget -string "PfHm"
    defaults write com.apple.finder ShowExternalHardDrivesOnDesktop -bool true
    defaults write com.apple.finder ShowHardDrivesOnDesktop -bool true
    defaults write com.apple.finder ShowMountedServersOnDesktop -bool true
    defaults write com.apple.finder ShowRemovableMediaOnDesktop -bool true

    # Dock settings
    defaults write com.apple.dock autohide -bool true
    defaults write com.apple.dock show-recents -bool false
    defaults write com.apple.dock minimize-to-application -bool true
    defaults write com.apple.dock expose-group-apps -bool true

    # Window behavior
    defaults write NSGlobalDomain AppleMiniaturizeOnDoubleClick -bool false
    defaults write NSGlobalDomain com.apple.springing.enabled -bool true
    defaults write NSGlobalDomain com.apple.springing.delay -float 0.5

    # Trackpad settings
    defaults write com.apple.AppleMultitouchTrackpad Clicking -bool true
    defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerDrag -bool true
    defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
    defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadThreeFingerDrag -bool true

    # Menu bar clock
    defaults write com.apple.menuextra.clock ShowDate -int 0
    defaults write com.apple.menuextra.clock ShowDayOfWeek -bool true

    # Hot corners (bottom-right → Quick Note)
    defaults write com.apple.dock wvous-br-corner -int 14
    defaults write com.apple.dock wvous-br-modifier -int 0

    # Restart affected services
    killall Finder 2>/dev/null || true
    killall Dock 2>/dev/null || true

    print_success "macOS defaults applied (24 settings)"
    print_warning "Some settings require logout/restart to take effect"
else
    print_success "macOS defaults skipped"
fi

# ============================================
# 10. RUN HEALTH CHECK
# ============================================
# NON-FATAL by design. health-check.sh exits non-zero whenever anything is
# missing, which under `set -e` killed the install immediately before the
# summary — the diagnostic destroying the report it exists to inform. A
# check that reports problems must never itself become one.
# ============================================
_CURRENT_STEP="Step 10: health check"
echo ""
print_step "Step 10: Running health check..."
if bash "$DOTFILES_DIR/scripts/health-check.sh"; then
    print_success "Health check passed"
else
    print_warning "Health check reported issues (listed above) — install continues"
fi

# ============================================
# INSTALLATION COMPLETE
# ============================================
_CURRENT_STEP="printing summary"
echo ""
echo "  =========================================="
echo "  Installation Complete!"
echo "  =========================================="
echo ""
echo "📋 Next Steps:"
echo ""
echo "1. Restart your terminal or run: exec \$SHELL -l"
echo ""
echo "2. Open Neovim to install plugins:"
echo "   nvim"
echo "   (AstroNvim will auto-install)"
echo ""
echo "3. Start Aerospace (will start on next login):"
echo "   aerospace reload"
echo ""
echo "4. Verify language runtimes:"
echo "   mise list"
echo "   # Anything missing (Erlang/Rust compile from source and can fail):"
echo "   mise install"
echo ""
echo "5. Android SDK (needed by Flutter):"
echo "   sdkmanager --licenses"
echo "   sdkmanager \"platform-tools\" \"platforms;android-35\""
echo "   flutter config --jdk-dir \"\$(mise where java@temurin-17)\""
echo "   flutter doctor -v"
echo ""
echo "6. Sign in to 1Password (recommended for SSH + secrets):"
echo ""
echo "   # a) Open 1Password.app → sign in to your account"
echo "   #    (your vaults sync from cloud automatically)"
echo "   # b) Enable the SSH Agent:"
echo "   #    1Password → Settings → Developer → 'Set Up SSH Agent'"
echo "   # c) Wire the agent into ~/.ssh/config (one-time):"
echo "   bash $DOTFILES_DIR/scripts/setup-ssh.sh"
echo "   # d) Test it:"
echo "   ssh -T git@github.com   # should succeed via Touch ID"
echo ""
echo "   Note: SSH keys must already be in your 1Password vault (synced"
echo "   from another machine, or add them via 1Password → New Item → SSH Key)."
echo ""
echo "7. Set up AI tooling (one-time, optional):"
echo ""
echo "   # Pull a local model (~5GB, ~5 min) — recommended default"
echo "   ollama pull qwen2.5-coder:7b"
echo "   llm models default qwen2.5-coder:7b"
echo ""
echo "   # Optional: a larger general model for harder reasoning"
echo "   ollama pull qwen3:14b"
echo ""
echo "   # Optional: hosted-API plugins for llm"
echo "   llm install llm-anthropic llm-gemini"
echo "   llm keys set anthropic    # paste key when prompted"
echo "   llm keys set openai"
echo ""
echo "   # Authenticate gh + GitHub Copilot CLI (for ghcs / ghce)"
echo "   gh auth login"
echo ""
echo "8. Regenerate the package catalog after Brewfile changes:"
echo "   python3 $DOTFILES_DIR/scripts/catalog/build-catalog.py"
echo ""
echo "9. Run health check anytime:"
echo "   dotfiles health"
echo ""
echo "10. Update dotfiles in the future:"
echo "    bash $DOTFILES_DIR/update.sh"
echo ""
echo "🎨 Theme: $SELECTED_THEME (applied everywhere)"
echo "   Switch anytime: dotfiles theme"
echo ""
if [[ -d "$BACKUP_DIR" ]]; then
    echo "🔧 Backup location: $BACKUP_DIR"
    echo ""
fi

# ── What did NOT install ──────────────────────
# Printed last, on purpose: brew emits hundreds of lines and individual
# failures scroll away long before the install finishes.
if [[ ${#FAILED_PACKAGES[@]} -gt 0 ]]; then
    echo "  =========================================="
    echo "  ⚠️  THESE DID NOT INSTALL (${#FAILED_PACKAGES[@]})"
    echo "  =========================================="
    echo ""
    for pkg in "${FAILED_PACKAGES[@]}"; do
        echo "    - $pkg"
    done
    echo ""
    echo "  Retry all of them with:"
    echo "    cd $DOTFILES_DIR && brew bundle install --file=Brewfile"
    echo ""
    echo "  A cask that fails on a checksum mismatch is an upstream problem:"
    echo "  the vendor republished the download without a version bump. Wait"
    echo "  for the cask to be updated, or comment it out of the Brewfile."
    echo ""
else
    print_success "Every selected package installed cleanly"
    echo ""
fi

# Reached the end — tells the EXIT trap this was a normal finish.
_INSTALL_COMPLETE=true

echo "Enjoy your new setup! 🚀"
echo ""
