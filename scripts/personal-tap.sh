#!/usr/bin/env bash
# Personal Homebrew tap: where a package lives on after Homebrew deprecates
# or disables it and you choose to keep it. Sourced by bin/dotfiles-tap-*,
# update.sh (its Brewfile drift report) and bin/dotfiles-cleanup.
#
# The recipes live in the repo, in homebrew-tap/{Casks,Formula}/, so every
# machine that clones dotfiles has them and `dotfiles update` commits
# changes with its package snapshot. Homebrew cannot use that folder
# directly: `brew bump-*-pr` refuses a tap that is not its own git repo.
# So Homebrew gets a working copy, a small local git repo under its Taps
# directory, and the two are synced: the folder is copied in before each
# step (ptap_ensure) and a changed recipe is copied back after (ptap_save).
# The working copy's history is scratch; the repo is the record.
#
# The tap's name is per machine, in ~/.config/dotfiles/personal-tap:
#
#   name=<user>/tap                                  default: $(id -un)/tap
#
# Packages kept here are left out of the Brewfile; the folder is their
# record. Library: no `set -e`, bash 3.2 compatible; callers set DOTFILES_DIR.

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

# The recipes' home in the repo.
ptap_src() {
    printf '%s\n' "${DOTFILES_TAP_SRC:-${DOTFILES_DIR:-}/homebrew-tap}"
}

# Where Homebrew keeps a tap's checkout: <user>/<repo> lives in
# Library/Taps/<user>/homebrew-<repo>.
ptap_tap_dir() {
    local tap="$1"
    printf '%s/Library/Taps/%s/homebrew-%s\n' "$(brew --repository 2>/dev/null)" "${tap%%/*}" "${tap#*/}"
}

# Homebrew's working copy of the tap.
ptap_dir() {
    if [[ -n "${DOTFILES_TAP_DIR:-}" ]]; then
        printf '%s\n' "$DOTFILES_TAP_DIR"
    else
        ptap_tap_dir "$(ptap_name)"
    fi
}

# True when the repo carries at least one kept package.
ptap_exists() {
    [[ -n "$(ptap_packages)" ]]
}

# Makes Homebrew's working copy match the repo folder: starts it as a
# local git repo when missing, mirrors Casks/ and Formula/ (a recipe
# deleted from the folder goes from the working copy too), commits, and
# trusts the tap, since Homebrew 7 refuses to load an untrusted one.
ptap_ensure() {
    local name src dir sub f
    name=$(ptap_name)
    src=$(ptap_src)
    dir=$(ptap_dir)
    if [[ ! -d "$dir/.git" ]]; then
        mkdir -p "$dir" && git -C "$dir" init -q -b main || return 1
    fi
    for sub in Casks Formula; do
        mkdir -p "$dir/$sub"
        for f in "$dir/$sub"/*.rb; do
            [[ -f "$f" && ! -f "$src/$sub/$(basename "$f")" ]] && rm -f "$f"
        done
        for f in "$src/$sub"/*.rb; do
            [[ -f "$f" ]] && cp "$f" "$dir/$sub/"
        done
    done
    ptap_commit "sync from $(basename "$(dirname "$src")")/$(basename "$src")"
    # Older Homebrew has no trust command and loads any tap.
    brew trust --tap "$name" >/dev/null 2>&1 || true
}

# Copies a recipe the working copy changed back into the repo folder, or
# removes it there when the working copy no longer has it.
ptap_save() {
    local kind="$1" name="$2" sub src dir
    if [[ "$kind" == cask ]]; then sub=Casks; else sub=Formula; fi
    src=$(ptap_src)
    dir=$(ptap_dir)
    if [[ -f "$dir/$sub/$name.rb" ]]; then
        mkdir -p "$src/$sub"
        cp "$dir/$sub/$name.rb" "$src/$sub/$name.rb"
    else
        rm -f "$src/$sub/$name.rb"
    fi
}

# One line per package in the repo folder: "cask <token>" or "formula <name>".
ptap_packages() {
    local src f
    src=$(ptap_src)
    for f in "$src"/Casks/*.rb; do
        [[ -f "$f" ]] && printf 'cask %s\n' "$(basename "$f" .rb)"
    done
    for f in "$src"/Formula/*.rb; do
        [[ -f "$f" ]] && printf 'formula %s\n' "$(basename "$f" .rb)"
    done
    return 0
}

# True when the package is installed at all, from any tap.
ptap_installed() {
    local kind="$1" name="$2"
    if [[ "$kind" == cask ]]; then
        [[ -n "$(brew list --cask --versions "$name" 2>/dev/null)" ]]
    else
        [[ -n "$(brew list --formula --versions "$name" 2>/dev/null)" ]]
    fi
}

# True when the installed copy came from the personal tap, per its install
# receipt; a short name alone would match the official recipe too.
ptap_installed_from_tap() {
    local kind="$1" name="$2" receipt tap f
    tap=$(ptap_name)
    if [[ "$kind" == cask ]]; then
        receipt="$(brew --caskroom 2>/dev/null)/$name/.metadata/INSTALL_RECEIPT.json"
    else
        receipt=""
        for f in "$(brew --cellar 2>/dev/null)/$name"/*/INSTALL_RECEIPT.json; do
            [[ -f "$f" ]] && receipt="$f"
        done
    fi
    [[ -f "$receipt" ]] || return 1
    [[ "$(jq -r '.source.tap // ""' "$receipt" 2>/dev/null)" == "$tap" ]]
}

# Brewfile lines for what the tap holds, so the drift report and
# `dotfiles cleanup` treat kept packages as wanted.
ptap_brewfile_lines() {
    local name kind pkg packages
    packages=$(ptap_packages)
    [[ -n "$packages" ]] || return 0
    name=$(ptap_name)
    printf 'tap "%s"\n' "$name"
    while read -r kind pkg; do
        case "$kind" in
            cask) printf 'cask "%s/%s"\n' "$name" "$pkg" ;;
            formula) printf 'brew "%s/%s"\n' "$name" "$pkg" ;;
        esac
    done <<<"$packages"
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

# Commits the working copy, so Homebrew's tools see a clean tap.
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
