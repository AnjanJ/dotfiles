#!/usr/bin/env bash
# Claude Code settings: base file tracked, live file generated.
#
# ~/.claude/settings.json links to .config/claude/settings.json, and Claude
# Code rewrites that file itself (/config, /permissions, auto mode's
# environment notes). The repo is public, and some of what Claude Code
# writes is machine-local and private: `autoMode` records project names,
# hosts and paths. So the repo tracks settings.base.json and this script
# writes settings.json (gitignored) from it.
#
# Each run is a three-way merge at the top level, against the copy written
# last time (kept in the state dir):
#   - a key that differs between the live file and that copy was changed in
#     Claude Code, so it is adopted into the base (or dropped, if deleted);
#   - every other key takes the base's value, so a base pulled from another
#     machine is not undone by a stale live file;
#   - LOCAL_KEYS never enter the base and are kept in the live file as they
#     are.
# With no copy yet (first run), every difference counts as a Claude Code
# edit, which is how the Zed and VS Code bases adopt too.
#
# Usage: claude-settings.sh [--quiet]
# Overrides for tests: DOTFILES_DIR, DOTFILES_STATE_DIR.
# Bash 3.2 compatible: apply-theme runs it on the install path.

# Keys Claude Code writes that must stay on this machine.
CLAUDE_LOCAL_KEYS='["autoMode"]'

claude_settings_render() {
    local quiet="${1:-}"
    local dir="$DOTFILES_DIR/.config/claude"
    local base="$dir/settings.base.json"
    local live="$dir/settings.json"
    local state="${DOTFILES_STATE_DIR:-$HOME/.local/state/dotfiles}"
    local rendered="$state/claude-settings.rendered.json"
    local tmp_base tmp_live

    [[ -f "$base" ]] || return 0
    command -v jq >/dev/null 2>&1 || {
        [[ -f "$live" ]] || cp "$base" "$live"
        [[ "$quiet" == "--quiet" ]] || echo "  jq not installed: Claude settings copied from the base without merging" >&2
        return 0
    }
    if [[ -f "$live" ]] && ! jq -e . "$live" >/dev/null 2>&1; then
        echo "  Claude settings.json is not valid JSON; left as it is" >&2
        return 0
    fi

    mkdir -p "$state"
    tmp_base=$(mktemp)
    tmp_live=$(mktemp)

    local live_json="{}" rendered_json="null"
    [[ -f "$live" ]] && live_json=$(cat "$live")
    [[ -f "$rendered" ]] && jq -e . "$rendered" >/dev/null 2>&1 && rendered_json=$(cat "$rendered")

    # With no live file there is nothing to adopt: the copy is the live file.
    [[ -f "$live" ]] || rendered_json="$live_json"

    # shellcheck disable=SC2016  # jq program: $live, $r and $lk are jq variables
    jq --argjson live "$live_json" --argjson r "$rendered_json" --argjson lk "$CLAUDE_LOCAL_KEYS" '
        . as $b
        | ($r // ($b + ($live | with_entries(select(.key as $k | $lk | index($k)))))) as $prev
        | reduce ((($live | keys) + ($prev | keys)) | unique[] | select(. as $k | $lk | index($k) | not)) as $k
            ($b;
             if ($live | has($k)) != ($prev | has($k)) or $live[$k] != $prev[$k] then
                 (if $live | has($k) then .[$k] = $live[$k] else del(.[$k]) end)
             else . end)
    ' "$base" > "$tmp_base"

    jq --argjson live "$live_json" --argjson lk "$CLAUDE_LOCAL_KEYS" \
        '. + ($live | with_entries(select(.key as $k | $lk | index($k))))' "$tmp_base" > "$tmp_live"

    if ! cmp -s <(jq -S . "$base") <(jq -S . "$tmp_base"); then
        cp "$tmp_base" "$base"
        [[ "$quiet" == "--quiet" ]] || echo "  Claude settings changed in Claude Code → adopted into .config/claude/settings.base.json"
    fi
    if [[ ! -f "$live" ]] || ! cmp -s <(jq -S . "$live") <(jq -S . "$tmp_live"); then
        # In place, not mv: ~/.claude/settings.json links to this path, and
        # rewriting the same inode keeps any open watcher on it.
        cat "$tmp_live" > "$live"
    fi
    cp "$tmp_live" "$rendered"
    chmod 600 "$rendered"
    rm -f "$tmp_base" "$tmp_live"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    set -euo pipefail
    DOTFILES_DIR="${DOTFILES_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
    claude_settings_render "${1:-}"
fi
