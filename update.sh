#!/usr/bin/env bash

# ============================================
# DOTFILES UPDATE SCRIPT
# ============================================
# Keeps your system and dotfiles repo in sync.
#
# What it does:
#   1. Pull latest dotfiles from git (marks aerospace/sketchybar for restart
#      when their configs changed)
#   2. Take a local APFS snapshot, then upgrade Homebrew packages & snapshot
#      diff (preserves organized Brewfile)
#   3. Refresh symlinks, run pending migrations
#   4. Upgrade mise tools (config auto-syncs via symlink)
#   5. Restart only what was marked (dotfiles restart --pending), run hooks
#   6. Commit & push any changes back to repo
#
# Around all of that: a transcript in ~/.local/state/dotfiles/update.log
# (previous run kept as update.log.1) and a lock so two updates cannot
# overlap.
#
# Usage: bash update.sh [--interactive] [--yes] [--no-snapshot]
# ============================================

INTERACTIVE=false
UNATTENDED=false
TAKE_SNAPSHOT=true

for arg in "$@"; do
    case $arg in
        --interactive) INTERACTIVE=true ;;
        --yes|-y) UNATTENDED=true ;;
        --no-snapshot) TAKE_SNAPSHOT=false ;;
        --help)
            echo "Usage: bash update.sh [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --interactive  Prompt before each step"
            echo "  --yes, -y      Unattended: never prompt (cron, ssh, CI)"
            echo "  --no-snapshot  Skip the tmutil local snapshot before brew upgrade"
            echo "  --help         Show this help message"
            echo ""
            echo "Transcript: ~/.local/state/dotfiles/update.log"
            exit 0
            ;;
        *) echo "Warning: unknown option '$arg' ignored (see --help)" >&2 ;;
    esac
done

# --yes is a promise not to ask anything. It beats --interactive, and hooks
# and migrations can read it to skip their own prompts.
if [[ "$UNATTENDED" == true ]]; then
    INTERACTIVE=false
    export DOTFILES_UPDATE_UNATTENDED=1
fi

set -euo pipefail

# Get dotfiles directory
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Shared colors & print functions
source "$DOTFILES_DIR/scripts/_helpers.sh"

# Check if running on macOS
if [[ "$(uname)" != "Darwin" ]]; then
    print_error "This script is only for macOS"
    exit 1
fi

STATE_DIR="${DOTFILES_STATE_DIR:-$HOME/.local/state/dotfiles}"
mkdir -p "$STATE_DIR"
UPDATE_LOG="$STATE_DIR/update.log"

# ── Transcript ────────────────────────────────
# Re-exec under script(1) so the whole run, brew's progress bars included,
# lands in update.log while still showing on the terminal. Without a tty
# (cron, ssh -T) script would give brew a pty it does not have on the
# terminal side, so a plain tee is the honest transcript there.
if [[ -z "${DOTFILES_UPDATE_LOGGED:-}" ]]; then
    export DOTFILES_UPDATE_LOGGED=1
    [[ -f "$UPDATE_LOG" ]] && mv -f "$UPDATE_LOG" "$UPDATE_LOG.1"
    echo "# dotfiles update $(date '+%Y-%m-%d %H:%M:%S') $*" > "$UPDATE_LOG"
    if [[ -t 1 ]] && command -v script >/dev/null 2>&1; then
        exec script -q -a "$UPDATE_LOG" "$BASH" "$0" "$@"
    else
        exec > >(tee -a "$UPDATE_LOG") 2>&1
    fi
fi

# ── Lock ──────────────────────────────────────
# mkdir is atomic, and stock bash has no flock. A pid inside tells a stale
# lock (crashed run, closed terminal) from a live one.
LOCK_DIR="$STATE_DIR/update.lock"
if ! mkdir "$LOCK_DIR" 2>/dev/null; then
    _lock_pid=$(cat "$LOCK_DIR/pid" 2>/dev/null || true)
    if [[ -n "$_lock_pid" ]] && kill -0 "$_lock_pid" 2>/dev/null; then
        print_error "Another update is already running (pid $_lock_pid)"
        echo "  Its transcript: $UPDATE_LOG"
        exit 1
    fi
    print_warning "Removing stale update lock (pid ${_lock_pid:-unknown} is gone)"
    rm -rf "$LOCK_DIR"
    mkdir "$LOCK_DIR"
fi
echo $$ > "$LOCK_DIR/pid"

# A failed run should end with where to look, not a bare exit code.
# Cancelling at the prompt is not a failure and stays quiet.
CANCELLED=false
_update_exit() {
    local rc=$?
    rm -rf "$LOCK_DIR"
    # A run that dies between the auto-stash and its pop (a pull that
    # cannot reach origin, say) must not leave the working tree emptied.
    if [[ "${DID_STASH:-false}" == true && "${STASH_RESTORED:-false}" != true ]]; then
        if git -C "$DOTFILES_DIR" stash pop >/dev/null 2>&1; then
            print_warning "Restored the auto-stashed working tree changes"
        else
            print_error "Could not restore the auto-stash; run: git -C $DOTFILES_DIR stash pop"
        fi
    fi
    if [[ $rc -ne 0 && "$CANCELLED" != true ]]; then
        print_error "Update failed (exit $rc). Transcript: $UPDATE_LOG"
        echo "  Run \`dotfiles health\` for the current state, then \`dotfiles update\` again."
    fi
    exit "$rc"
}
trap _update_exit EXIT

# Hold off idle sleep for the length of the run (brew upgrade on a laptop
# lid-closed at the wrong moment leaves half-linked kegs). -w ends the
# assertion when this pid exits, so nothing is left behind.
if command -v caffeinate >/dev/null 2>&1; then
    caffeinate -i -w $$ >/dev/null 2>&1 &
fi

echo ""
echo ""
echo "  AJ's Dotfiles Update"
echo "  =========================================="
echo ""
echo "  This will:"
echo "    - Pull latest changes from git"
echo "    - Take a local APFS snapshot, then upgrade Homebrew & snapshot Brewfile"
echo "    - Refresh symlinks, run migrations"
echo "    - Upgrade mise tools"
echo "    - Restart whatever changed (aerospace, sketchybar, borders)"
echo "    - Push changes back to repo"
echo ""
echo "  Transcript: $UPDATE_LOG"
echo ""

if [[ "$INTERACTIVE" == true ]]; then
    read -r -p "Continue with update? (y/n) " -n 1
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_warning "Update cancelled"
        CANCELLED=true
        exit 1
    fi
fi

# ============================================
# 1. GIT PULL
# ============================================
echo ""
print_step "Step 1: Pulling latest changes..."

cd "$DOTFILES_DIR"

# Stash uncommitted changes so git pull doesn't conflict, then restore them
DID_STASH=false
if [[ -n $(git status -s) ]]; then
    print_warning "Uncommitted changes detected — stashing temporarily for pull"
    git stash push -m "Auto-stash before update $(date +%Y%m%d_%H%M%S)"
    DID_STASH=true
fi

_before_pull=$(git rev-parse HEAD)
git pull origin main
print_success "Repository updated"

# A pulled change to a live config needs its app restarted, but not now:
# step 5 restarts everything marked, once, after symlinks and migrations.
_pulled=$(git diff --name-only "$_before_pull" HEAD -- .config/aerospace .config/sketchybar .config/borders 2>/dev/null || true)
for _component in aerospace sketchybar borders; do
    if echo "$_pulled" | grep -q "^\.config/$_component/"; then
        bash "$DOTFILES_DIR/bin/dotfiles-restart" --later "$_component"
        print_success "$_component config changed — will restart in step 5"
    fi
done

# Restore stashed changes immediately after pull
if [[ "$DID_STASH" == true ]]; then
    STASH_RESTORED=true
    git stash pop || print_warning "Stash pop had conflicts — resolve manually"
    print_success "Uncommitted changes restored"
fi

# ============================================
# 2. UPDATE HOMEBREW & SNAPSHOT BREWFILE
# ============================================
echo ""
print_step "Step 2: Updating Homebrew packages..."

# A local APFS snapshot is the rollback point for a bad upgrade: mount it
# or restore from Time Machine's browser. macOS thins them itself when
# space is tight, so it costs nothing to keep taking one per update.
if [[ "$TAKE_SNAPSHOT" == true ]]; then
    if _snapshot=$(tmutil localsnapshot 2>&1) && [[ "$_snapshot" == *"Created local snapshot"* ]]; then
        print_success "Local snapshot taken (${_snapshot##*date: })"
        echo "  Roll back: tmutil listlocalsnapshots /"
    else
        print_warning "Could not take a local snapshot — continuing without one"
    fi
else
    print_warning "Skipping local snapshot (--no-snapshot)"
fi

# Update Homebrew itself
brew update

# Upgrade already-installed packages
brew upgrade
brew cleanup

print_success "Homebrew packages upgraded"

# Snapshot: dump current system state for comparison
echo ""
print_step "Step 2b: Snapshotting installed packages..."

# Rotate backup
if [[ -f "$DOTFILES_DIR/Brewfile.backup" ]]; then
    rm "$DOTFILES_DIR/Brewfile.backup"
fi
cp "$DOTFILES_DIR/Brewfile" "$DOTFILES_DIR/Brewfile.backup"
print_success "Previous Brewfile saved to Brewfile.backup"

# Dump current state to a snapshot file (not the main Brewfile — that has @group markers)
brew bundle dump --file="$DOTFILES_DIR/Brewfile.snapshot" --force
print_success "System snapshot taken (Brewfile.snapshot)"
echo "  Tip: Run 'dotfiles cleanup' to find packages not in Brewfile"

# Show what changed vs the organized Brewfile (ignoring @group comments)
if [[ -f "$DOTFILES_DIR/Brewfile.snapshot" ]]; then
    # Compare package lines only. Normalize both files so cosmetic differences
    # (inline comments, indentation, tap-prefixed names) don't show up as drift:
    #   - drop full-line comments and blank lines
    #   - strip trailing inline comments (`brew "jq"  # …`  →  `brew "jq"`)
    #   - resolve `brew "owner/tap/pkg"` → `brew "pkg"` to match what
    #     `brew bundle dump` writes when the tap is already declared
    _normalize_brewfile() {
        sed -E \
            -e 's/[[:space:]]*#.*$//' \
            -e 's/[[:space:]]+$//' \
            -e 's/^(brew |cask )"[^"/]+\/[^"/]+\/([^"]+)"/\1"\2"/' \
            "$1" | grep -v '^[[:space:]]*$' | sort -u
    }
    _brewfile_pkgs=$(_normalize_brewfile "$DOTFILES_DIR/Brewfile")
    _snapshot_pkgs=$(_normalize_brewfile "$DOTFILES_DIR/Brewfile.snapshot")

    BREW_ADDED_LINES=$(comm -13 <(echo "$_brewfile_pkgs") <(echo "$_snapshot_pkgs") || true)
    BREW_REMOVED_LINES=$(comm -23 <(echo "$_brewfile_pkgs") <(echo "$_snapshot_pkgs") || true)
    BREW_ADDED_COUNT=$(echo "$BREW_ADDED_LINES" | grep -c . || true)
    BREW_REMOVED_COUNT=$(echo "$BREW_REMOVED_LINES" | grep -c . || true)

    if [[ "$BREW_ADDED_COUNT" -gt 0 || "$BREW_REMOVED_COUNT" -gt 0 ]]; then
        echo -e "  ${YELLOW}+${BREW_ADDED_COUNT} new on system, -${BREW_REMOVED_COUNT} in Brewfile but not installed${NC}"
        if [[ -n "$BREW_ADDED_LINES" ]]; then
            while IFS= read -r line; do
                [[ -z "$line" ]] && continue
                echo -e "    ${GREEN}+ $line${NC}"
            done <<< "$BREW_ADDED_LINES"
        fi
        if [[ -n "$BREW_REMOVED_LINES" ]]; then
            while IFS= read -r line; do
                [[ -z "$line" ]] && continue
                echo -e "    ${RED}- $line${NC}"
            done <<< "$BREW_REMOVED_LINES"
        fi
    else
        echo -e "  ${GREEN}No changes since last snapshot${NC}"
    fi

    rm -f "$DOTFILES_DIR/Brewfile.snapshot"
fi

# In interactive mode, also install anything in Brewfile missing from system
if [[ "$INTERACTIVE" == true ]]; then
    read -r -p "Install any missing Brewfile packages? This may require your password. (y/n) " -n 1
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        source "$DOTFILES_DIR/scripts/package-utils.sh"
        if [[ -f "$PACKAGES_STATE_FILE" ]]; then
            _saved_selections=$(get_saved_groups)
            if [[ -n "$_saved_selections" ]]; then
                _filtered=$(generate_filtered_brewfile "$DOTFILES_DIR/Brewfile" "$_saved_selections")
                brew bundle install --file="$_filtered"
                rm -f "$_filtered"
            else
                brew bundle install --file="$DOTFILES_DIR/Brewfile"
            fi
        else
            brew bundle install --file="$DOTFILES_DIR/Brewfile"
        fi
        print_success "Brewfile synced to system"
    else
        print_success "Skipped Brewfile sync"
    fi
fi

# ============================================
# 3. REFRESH SYMLINKS
# ============================================
echo ""
print_step "Step 3: Refreshing symlinks..."

# Helper function to create symlink
create_symlink() {
    local source="$1"
    local target="$2"
    local name="$3"

    if [ -L "$target" ] && [ "$(readlink "$target")" = "$source" ]; then
        print_success "$name already up to date"
    else
        mkdir -p "$(dirname "$target")"
        ln -sf "$source" "$target"
        print_success "$name refreshed"
        # A relinked live config is a changed live config to its app
        case "$source" in
            */.config/aerospace*)  bash "$DOTFILES_DIR/bin/dotfiles-restart" --later aerospace ;;
            */.config/sketchybar*) bash "$DOTFILES_DIR/bin/dotfiles-restart" --later sketchybar ;;
            */.config/borders*)    bash "$DOTFILES_DIR/bin/dotfiles-restart" --later borders ;;
        esac
    fi
}

# The full list of managed links lives in scripts/symlink-map.sh —
# the single source of truth shared with install/sync/doctor/health.
source "$DOTFILES_DIR/scripts/symlink-map.sh"
dotfiles_for_each_link create_symlink

# One-off repairs a relink cannot express (see bin/dotfiles-migrate)
bash "$DOTFILES_DIR/bin/dotfiles-migrate" || print_warning "Some migrations failed; they will retry next update"

print_success "Symlinks refreshed"

# ============================================
# 4. UPDATE MISE TOOLS
# ============================================
echo ""
print_step "Step 4: Updating mise tools..."

# Trust the config again (in case it changed)
mise trust ~/.config/mise/config.toml 2>/dev/null || true

# Update mise itself
mise self-update --yes 2>/dev/null || print_warning "mise self-update not available"

# Upgrade all installed tools
# Note: mise config is symlinked to the repo, so any changes
# (e.g. 'mise use python@3.13') are already tracked automatically.
mise upgrade --yes 2>/dev/null || mise install

print_success "mise tools updated"

# ============================================
# 5. RESTART WHAT CHANGED
# ============================================
# Only components marked during this run (pulled config, refreshed link,
# a migration's `dotfiles restart --later`) are touched. The old
# unconditional `aerospace reload-config` reloaded on every run, and
# because the process is spelled AeroSpace its pgrep guard never matched.
echo ""
print_step "Step 5: Restarting what changed..."

bash "$DOTFILES_DIR/bin/dotfiles-restart" --pending

bash "$DOTFILES_DIR/bin/dotfiles-hook" post-update

# ============================================
# 6. COMMIT & PUSH CHANGES
# ============================================
echo ""
print_step "Step 6: Syncing dotfiles repo..."

cd "$DOTFILES_DIR"

CURRENT_BRANCH=$(git branch --show-current)

if ! bash "$DOTFILES_DIR/bin/dotfiles-toggle" --enabled auto-commit; then
    print_warning "auto-commit is toggled off (dotfiles toggle auto-commit) — leaving changes uncommitted"
elif [[ "$CURRENT_BRANCH" != "main" ]]; then
    print_warning "On branch '$CURRENT_BRANCH' — skipping auto-commit/push (only runs on main)"
elif [[ -n $(git status -s) ]]; then
    # Stage tracked changes only (Brewfile.backup is gitignored — local safety net only)
    git add Brewfile .config/mise/config.toml 2>/dev/null || true
    git add -u

    # Skip commit when the only diff is whitespace, comment, or ordering churn
    # in Brewfile/mise config (no functional package changes).
    MEANINGFUL=false
    if ! git diff --cached --quiet; then
        # Any change outside Brewfile/mise config = meaningful by default
        if git diff --cached --name-only | grep -vE '^(Brewfile|\.config/mise/config\.toml)$' | grep -q .; then
            MEANINGFUL=true
        else
            # Only Brewfile/mise diffs — check for actual package adds/removes
            # (ignore comment-only and whitespace-only lines)
            for f in Brewfile .config/mise/config.toml; do
                if git diff --cached -- "$f" | grep -E '^[+-][^+-]' | grep -vE '^[+-]\s*(#|$)' | grep -q .; then
                    MEANINGFUL=true
                    break
                fi
            done
        fi
    fi

    if [[ "$MEANINGFUL" == true ]]; then
        CHANGES=$(git diff --cached --stat | tail -1)
        git commit -m "snapshot: system state

$CHANGES"
        git push origin main
        print_success "Changes pushed to repo"
    else
        print_success "No meaningful changes — skipping snapshot commit"
        git reset HEAD -- . >/dev/null 2>&1 || true
    fi
else
    print_success "Repo already in sync"
fi

# ============================================
# UPDATE COMPLETE
# ============================================
# Refresh the cache behind the login notice so the next shell does not
# announce the commits and packages this run just applied.
bash "$DOTFILES_DIR/bin/dotfiles-update-available" --quiet >/dev/null 2>&1 || true

echo ""
echo "  =========================================="
echo "  Update Complete!"
echo "  =========================================="
echo ""
echo "   Restart your terminal or run: source ~/.zshrc"
echo "   Transcript: $UPDATE_LOG"
echo ""
