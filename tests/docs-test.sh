#!/usr/bin/env bash
# ============================================
# DOCS SUITE — prose that must agree with the code
# ============================================
# The comparison with Omarchy found four docs describing a setup that
# no longer existed. `dotfiles keys --check` fixed the keybindings;
# this suite covers the rest: suite counts, the MAINTENANCE suite list,
# the app list in THEMES.md, and the command table in the agent skill.
# Every check derives the truth from the filesystem or the CLI, never
# from another doc.
# ============================================
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

cd "$ROOT"

section "suite counts"

suites=()
for f in tests/*-test.sh; do
    [[ "$f" == tests/base-test.sh ]] && continue
    suites+=("$(basename "$f" -test.sh)")
done
count=${#suites[@]}
[[ $count -gt 0 ]] || fail "suites discovered"

assert_file_contains README.md "$count CI suites" "README.md states the suite count ($count)"
assert_file_contains docs/STRUCTURE.md "# $count suites" "docs/STRUCTURE.md states the suite count ($count)"
assert_file_contains docs/MAINTENANCE.md "runs $count test suites" "docs/MAINTENANCE.md states the suite count ($count)"

section "MAINTENANCE.md lists every suite"

# Each bullet in the Testing list names its suite as (`area`), so a new
# tests/<area>-test.sh must be described there and a removed one must
# be dropped.
# shellcheck disable=SC2016  # the backticks are literal markdown, not a command substitution
listed=$(/usr/bin/grep -oE '^- \*\*[^*]+\*\* \(`[a-z0-9-]+`' docs/MAINTENANCE.md | /usr/bin/grep -oE '`[a-z0-9-]+`$' | tr -d '`')
for area in "${suites[@]}"; do
    /usr/bin/grep -qx "$area" <<<"$listed" || fail "docs/MAINTENANCE.md describes the $area suite" "add a '- **Name** (\`$area\`) — …' bullet under Testing"
done
pass "docs/MAINTENANCE.md describes every suite"
while IFS= read -r area; do
    [[ -n "$area" ]] || continue
    [[ -f "tests/$area-test.sh" ]] || fail "every suite listed in docs/MAINTENANCE.md exists" "no tests/$area-test.sh for the (\`$area\`) bullet"
done <<<"$listed"
pass "every suite listed in docs/MAINTENANCE.md exists"

section "THEMES.md app list"

# Header counts and the summary sentence must agree with the cells.
auto_cell=$(/usr/bin/grep -E '^\| Ghostty' docs/THEMES.md | head -1 | cut -d'|' -f2)
manual_cell=$(/usr/bin/grep -E '^\| Ghostty' docs/THEMES.md | head -1 | cut -d'|' -f3)
[[ -n "$auto_cell" && -n "$manual_cell" ]] || fail "THEMES.md has the app table"
auto_n=$(tr ',' '\n' <<<"$auto_cell" | /usr/bin/grep -c .)
manual_n=$(tr ',' '\n' <<<"$manual_cell" | /usr/bin/grep -c .)
assert_file_contains docs/THEMES.md "| Auto-configured ($auto_n) | Manual — links provided ($manual_n) |" "THEMES.md table headers count their cells ($auto_n / $manual_n)"
assert_file_contains docs/THEMES.md "\*\*$((auto_n + manual_n)) apps\*\*: $auto_n configured automatically, $manual_n with manual" "THEMES.md summary sentence matches the table"

# Every template renders for an app; that app must be named in the doc.
for tpl in themes/_templates/*.tpl; do
    stem=$(basename "$tpl" .tpl)
    stem=${stem%%.*}
    stem=${stem%%-*}
    case "$stem" in
        nvim) name="Neovim" ;;
        claude) name="Claude Code" ;;
        *) name="$stem" ;;
    esac
    /usr/bin/grep -qi -- "$name" docs/THEMES.md || fail "THEMES.md names every templated app" "$tpl renders for '$name', which THEMES.md never mentions"
done
pass "THEMES.md names every templated app"

for theme in themes/*/; do
    theme=$(basename "$theme")
    [[ "$theme" == _* ]] && continue
    /usr/bin/grep -q "$theme" docs/THEMES.md || fail "THEMES.md names every bundled theme" "$theme is missing"
done
pass "THEMES.md names every bundled theme"

section "agent skill command table"

# The skill is what an agent reads instead of `dotfiles --help`; every
# public route must appear there with its verb.
missing=""
while IFS=$'\t' read -r route _; do
    group="${route%% *}"
    verb="${route#* }"
    [[ "$verb" == "$route" ]] && verb=""
    if [[ -n "$verb" ]]; then
        /usr/bin/grep -E "dotfiles $group" agents/skills/dotfiles/commands.md | /usr/bin/grep -q -- "$verb" || missing+="$route"$'\n'
    else
        /usr/bin/grep -qE '`dotfiles '"$group"'( |`|\\)' agents/skills/dotfiles/commands.md || missing+="$route"$'\n'
    fi
done < <(bin/dotfiles commands --plain)
assert_eq "$missing" "" "agents/skills/dotfiles/commands.md documents every public route"

# Toggles documented in the skill are the ones dotfiles-toggle knows.
for flag in $(/usr/bin/grep -oE 'dotfiles:summary=.*\((.*)\)' bin/dotfiles-toggle | sed 's/.*(\(.*\))/\1/' | tr ',' ' '); do
    /usr/bin/grep -q -- "\`$flag\`" agents/skills/dotfiles/commands.md || fail "skill documents every toggle" "$flag is missing from commands.md"
done
pass "skill documents every toggle"

section "hook events"

# Events fired by the code must be the events the skill and the hook
# command's own help advertise.
fired=$(/usr/bin/grep -rhoE 'dotfiles[-_ ]hook"? [a-z][a-z-]*' bin scripts install.sh update.sh | awk '{print $NF}' | sort -u)
for event in $fired; do
    /usr/bin/grep -q "$event" agents/skills/dotfiles/commands.md || fail "skill documents every hook event" "$event is fired but undocumented"
    /usr/bin/grep -q "$event" bin/dotfiles-hook || fail "dotfiles hook --help lists every event" "$event is fired but not in the help"
done
pass "every fired hook event is documented"
