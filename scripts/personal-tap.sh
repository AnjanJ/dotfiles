#!/usr/bin/env bash
# Personal Homebrew tap: where a package lives on after Homebrew deprecates
# or disables it and you choose to keep it. Sourced by bin/dotfiles-tap-*,
# update.sh (its Brewfile drift report) and bin/dotfiles-cleanup.
#
# The tap's name and optional git remote live outside the repo, in
# ~/.config/dotfiles/personal-tap, because the repo is public and the list
# of apps you kept is yours:
#
#   name=<user>/tap                                  default: $(id -un)/tap
#   remote=git@github.com:<user>/homebrew-tap.git    optional
#
# Without a remote the tap is a local git repo under Homebrew's Taps
# directory. With one, every change is pushed and a fresh machine taps it
# from there. Packages kept here are left out of the public Brewfile; the
# tap itself is their record.
#
# Library: no `set -e`, bash 3.2 compatible.

PTAP_CONFIG="${DOTFILES_CONFIG_DIR:-$HOME/.config/dotfiles}/personal-tap"

ptap_conf() {
    local key="$1"
    [[ -f "$PTAP_CONFIG" ]] || return 0
    sed -n "s/^${key}=//p" "$PTAP_CONFIG" | tail -1
}

ptap_name() {
    local name="${DOTFILES_TAP:-}"
    [[ -n "$name" ]] || name=$(ptap_conf name)
    [[ -n "$name" ]] || name="$(id -un | tr '[:upper:]' '[:lower:]' | tr -cd 'a-z0-9-')/tap"
    printf '%s\n' "$name"
}

# Where Homebrew keeps a tap's checkout: <user>/<repo> lives in
# Library/Taps/<user>/homebrew-<repo>.
ptap_tap_dir() {
    local tap="$1"
    printf '%s/Library/Taps/%s/homebrew-%s\n' "$(brew --repository 2>/dev/null)" "${tap%%/*}" "${tap#*/}"
}

ptap_dir() {
    if [[ -n "${DOTFILES_TAP_DIR:-}" ]]; then
        printf '%s\n' "$DOTFILES_TAP_DIR"
    else
        ptap_tap_dir "$(ptap_name)"
    fi
}

ptap_exists() {
    [[ -d "$(ptap_dir)/.git" ]]
}

# Taps the remote on a machine that has none yet, or starts an empty local
# tap, then trusts it: Homebrew 7 refuses to load casks and formulae from
# a tap nobody trusted.
ptap_ensure() {
    local name dir remote
    name=$(ptap_name)
    dir=$(ptap_dir)
    remote=$(ptap_conf remote)
    if [[ ! -d "$dir/.git" ]]; then
        if [[ -n "$remote" && -z "${DOTFILES_TAP_DIR:-}" ]]; then
            brew tap "$name" "$remote" || return 1
        else
            mkdir -p "$dir" && git -C "$dir" init -q -b main || return 1
        fi
    fi
    mkdir -p "$dir/Casks" "$dir/Formula"
    if [[ -n "$remote" ]] && ! git -C "$dir" remote get-url origin >/dev/null 2>&1; then
        git -C "$dir" remote add origin "$remote"
    fi
    # Older Homebrew has no trust command and loads any tap.
    brew trust --tap "$name" >/dev/null 2>&1 || true
}

# One line per package: "cask <token>" or "formula <name>".
ptap_packages() {
    local dir f
    dir=$(ptap_dir)
    for f in "$dir"/Casks/*.rb; do
        [[ -f "$f" ]] && printf 'cask %s\n' "$(basename "$f" .rb)"
    done
    for f in "$dir"/Formula/*.rb; do
        [[ -f "$f" ]] && printf 'formula %s\n' "$(basename "$f" .rb)"
    done
    return 0
}

# Brewfile lines for what the tap holds, so the drift report and
# `dotfiles cleanup` treat kept packages as wanted.
ptap_brewfile_lines() {
    ptap_exists || return 0
    local name kind pkg
    name=$(ptap_name)
    printf 'tap "%s"\n' "$name"
    while read -r kind pkg; do
        case "$kind" in
            cask) printf 'cask "%s/%s"\n' "$name" "$pkg" ;;
            formula) printf 'brew "%s/%s"\n' "$name" "$pkg" ;;
        esac
    done < <(ptap_packages)
}

# A Brewfile followed by the tap's lines, for readers that should count
# kept packages as listed. The Brewfile may lack a final newline, and its
# last line must not run into the tap's first.
ptap_with_brewfile() {
    local file="$1"
    cat "$file"
    [[ -n "$(tail -c 1 "$file")" ]] && echo
    ptap_brewfile_lines
}

# Commits everything in the tap and pushes when it has a remote. A failed
# push is a warning: the commit is safe locally and the next run retries.
ptap_commit() {
    local msg="$1" dir
    dir=$(ptap_dir)
    git -C "$dir" add -A
    git -C "$dir" diff --cached --quiet && return 0
    if [[ -n "$(git -C "$dir" config user.email 2>/dev/null)" ]]; then
        git -C "$dir" commit -q -m "$msg"
    else
        git -C "$dir" -c user.name=dotfiles -c user.email=dotfiles@localhost commit -q -m "$msg"
    fi
    ptap_push
}

ptap_push() {
    local dir
    dir=$(ptap_dir)
    git -C "$dir" remote get-url origin >/dev/null 2>&1 || return 0
    if ! GIT_TERMINAL_PROMPT=0 git -C "$dir" push -q origin HEAD 2>/dev/null; then
        echo "  Could not push the tap to its remote; the change is committed locally and the next update retries" >&2
    fi
    return 0
}

# Prints the recipe a tap last shipped for a package: from the tap's local
# checkout when Homebrew has one, else from GitHub for the two official
# taps (which Homebrew reads from its API, so they are rarely checked out).
ptap_fetch_recipe() {
    local tap="$1" path="$2" local_file repo
    local_file="$(ptap_tap_dir "$tap")/$path"
    if [[ -f "$local_file" ]]; then
        cat "$local_file"
        return 0
    fi
    case "$tap" in
        homebrew/cask) repo="Homebrew/homebrew-cask" ;;
        homebrew/core) repo="Homebrew/homebrew-core" ;;
        *) return 1 ;;
    esac
    curl -fsSL --max-time 30 "https://raw.githubusercontent.com/$repo/HEAD/$path"
}

# Turns an official recipe into one the tap can carry: drops the
# deprecate!/disable! stanza (it may wrap onto continuation lines), drops a
# formula's bottle block (those bottles are built for homebrew/core, so a
# tap formula builds from source), and squeezes the blank lines left behind.
ptap_clean_recipe() {
    local is_formula=0
    [[ "$1" == formula ]] && is_formula=1
    awk -v formula="$is_formula" '
        cont { if ($0 !~ /,[[:space:]]*$/) cont = 0; next }
        /^[[:space:]]*(deprecate|disable)![[:space:]]/ { if ($0 ~ /,[[:space:]]*$/) cont = 1; next }
        formula && /^  bottle do[[:space:]]*$/ { bottle = 1; next }
        bottle { if ($0 ~ /^  end[[:space:]]*$/) bottle = 0; next }
        /^[[:space:]]*$/ { if (blank || opened) next; print; blank = 1; opened = 0; next }
        { print; blank = 0; opened = ($0 ~ /[[:space:]]do([[:space:]]*\|[^|]*\|)?[[:space:]]*$/) }
    '
}

# Removes a package's line from a Brewfile, whatever tap prefix or inline
# comment it carries. Prints the removed line; returns 1 when none matched.
ptap_brewfile_drop() {
    local file="$1" kind="$2" name="$3" word tmp removed
    [[ -f "$file" ]] || return 1
    if [[ "$kind" == cask ]]; then word=cask; else word=brew; fi
    tmp=$(mktemp)
    removed=$(awk -v w="$word" -v n="$name" -v out="$tmp" '
        {
            hit = 0
            if (match($0, /^[a-z]+ "[^"]+"/)) {
                kw = substr($0, 1, index($0, " ") - 1)
                tok = substr($0, RSTART, RLENGTH)
                sub(/^[a-z]+ "/, "", tok); sub(/"$/, "", tok); sub(/.*\//, "", tok)
                if (kw == w && tok == n) hit = 1
            }
            if (hit) print; else print > out
        }
    ' "$file")
    if [[ -z "$removed" ]]; then
        rm -f "$tmp"
        return 1
    fi
    # Write in place, not mv: keep the Brewfile's own inode, permissions and
    # any link. awk ends every line with a newline; a file that had none at
    # the end keeps having none, so the diff shows only the removed line.
    if [[ -n "$(tail -c 1 "$file")" ]]; then
        printf '%s' "$(cat "$tmp")" > "$file"
    else
        cat "$tmp" > "$file"
    fi
    rm -f "$tmp"
    printf '%s\n' "$removed"
}

# "fails_gatekeeper_check" → "fails gatekeeper check"
ptap_humanize() {
    printf '%s\n' "$1" | tr '_' ' '
}
