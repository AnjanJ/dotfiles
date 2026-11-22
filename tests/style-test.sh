#!/usr/bin/env bash
# doc: Style — the AGENTS.md rules shellcheck cannot express: shebang and strict mode, no `((VAR++))`, bash 3.2 builtins only on the install path, osascript never aimed at an app outside the watchdogged helpers, .gitignore patterns without trailing comments
# ============================================
# STYLE SUITE — the AGENTS.md rules shellcheck cannot express
# ============================================
# Each check here is a rule that has already bitten this repo once:
# `((VAR++))` returning 1 at zero under `set -e`, bash 4 builtins on
# the /bin/bash 3.2 bootstrap path, and osascript aimed at an
# application (which hangs on the Automation prompt) outside the
# watchdogged helpers. Comment lines are ignored throughout so a rule
# may be mentioned without being broken.
# ============================================
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

cd "$ROOT"

# Lines of code (comments and blank lines stripped) matching a pattern,
# reported as file:line so a failure says where to look.
code_lines_matching() {
    local pattern="$1"
    shift
    /usr/bin/grep -nE -- "$pattern" "$@" 2>/dev/null | /usr/bin/grep -vE '^[^:]+:[0-9]+:[[:space:]]*#' || true
}

commands=(bin/dotfiles bin/dotfiles-* bin/work-* bin/repos-clone)
libraries=(bin/_work-helpers bin/_launcher-helpers scripts/*.sh)

section "shebang and strict mode"

bad_shebang=""
for f in "${commands[@]}" "${libraries[@]}" install.sh update.sh; do
    [[ "$(head -1 "$f")" == "#!/usr/bin/env bash" ]] || bad_shebang+="$f"$'\n'
done
assert_eq "$bad_shebang" "" "every script starts with #!/usr/bin/env bash"

no_strict=""
for f in "${commands[@]}"; do
    /usr/bin/grep -q '^set -euo pipefail' "$f" || no_strict+="$f"$'\n'
done
assert_eq "$no_strict" "" "every command sets -euo pipefail (libraries are sourced and must not)"

strict_lib=""
for f in "${libraries[@]}"; do
    /usr/bin/grep -q '^set -e' "$f" && strict_lib+="$f"$'\n'
done
assert_eq "$strict_lib" "" "no sourced library sets -e for its caller"

section "arithmetic"

# ((VAR++)) evaluates to the old value, so at zero it returns 1 and
# `set -e` ends the script. AGENTS.md: VAR=$((VAR + 1)).
increments=$(code_lines_matching '\(\([A-Za-z_][A-Za-z0-9_]*(\+\+|--)\)\)' "${commands[@]}" "${libraries[@]}" install.sh update.sh)
assert_eq "$increments" "" "no ((VAR++)) or ((VAR--)) increments"

section "quoting"

# `cmd` inside a double-quoted message is a command substitution: a
# theme-update error message once ran the real `dotfiles update` from a
# test this way. Escape the backticks or use single quotes.
# shellcheck disable=SC2016  # the backticks are the pattern being searched for
backticks=$(code_lines_matching '"[^"]*[^\\]`[^`"]+`[^"]*"' "${commands[@]}" "${libraries[@]}" install.sh update.sh)
assert_eq "$backticks" "" "no unescaped \`command\` inside a double-quoted string"

section "bash 3.2 on the install path"

# install.sh runs under /bin/bash from `bash <(curl ...)` and sources
# these; update.sh can run there too after a fresh clone.
install_path=(install.sh update.sh scripts/_helpers.sh scripts/install-answers.sh scripts/theme-utils.sh
    scripts/package-utils.sh scripts/symlink-map.sh scripts/setup-git.sh scripts/setup-ssh.sh scripts/setup-git-signing.sh
    tests/base-test.sh tests/e2e/install-e2e.sh)
for f in "${install_path[@]}"; do
    [[ -f "$f" ]] || fail "install-path file exists: $f"
done
bash4=$(code_lines_matching 'declare -A|mapfile|readarray|\$\{[A-Za-z_][A-Za-z0-9_]*(,,|\^\^)\}|\|&' "${install_path[@]}")
assert_eq "$bash4" "" "no declare -A, mapfile, readarray, \${v,,} or |& on the install path"

syntax_errors=""
for f in "${install_path[@]}"; do
    /bin/bash -n "$f" 2>/dev/null || syntax_errors+="$f"$'\n'
done
assert_eq "$syntax_errors" "" "install-path files parse under /bin/bash 3.2"

section "osascript"

# `osascript display notification` has no target and is safe. Anything
# that tells an application must sit behind the 5s watchdog in
# apply-theme.sh / theme-background.sh, or the session hangs on the
# Automation prompt.
targeted=$(code_lines_matching 'osascript.*tell app' "${commands[@]}" "${libraries[@]}" install.sh update.sh \
    .config/aerospace/scripts/*.sh .config/sketchybar/sketchybarrc .config/sketchybar/plugins/*.sh \
    | /usr/bin/grep -vE '^scripts/(apply-theme|theme-background)\.sh:' || true)
assert_eq "$targeted" "" "osascript only targets applications inside the watchdogged theme helpers"

section "command metadata"

no_summary=""
for f in bin/dotfiles-*; do
    [[ "$(sed -n '2p' "$f")" == "# dotfiles:summary="* ]] || no_summary+="$f"$'\n'
done
assert_eq "$no_summary" "" "line 2 of every bin/dotfiles-* is the summary header"

section ".gitignore"

# git has no trailing comments: "foo  # why" ignores a file literally
# named that, and foo itself is committed.
trailing=$(/usr/bin/grep -nE '^[^#].*[[:space:]]#' .gitignore || true)
assert_eq "$trailing" "" "no .gitignore pattern carries a trailing comment"
for f in .zshrc-work .gitconfig-work .gitconfig.local .claude/settings.local.json .config/claude/settings.json .env; do
    git check-ignore -q "$f" || fail "$f is gitignored"
done
pass "machine-local and private files are gitignored"
# The global ignore (linked to ~/.gitignore_global) applies to every repo
# on the machine, so MemPalace's personal data cannot be added anywhere.
gi_repo="$TEST_TMP/gi-repo"
git init -q "$gi_repo"
for f in .mempalace/palace/chroma.sqlite3 .mempalace-rebuild/x notes/chroma.sqlite3 notes/chroma.sqlite3-wal; do
    git -C "$gi_repo" -c core.excludesfile="$ROOT/.gitignore_global" check-ignore -q "$f" \
        || fail "the global gitignore keeps MemPalace data out of every repo ($f)"
done
git -C "$gi_repo" -c core.excludesfile="$ROOT/.gitignore_global" check-ignore -q README.md \
    && fail "the global gitignore leaves ordinary files alone"
pass "the global gitignore keeps MemPalace data out of every repo"
