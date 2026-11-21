#!/usr/bin/env bash
# doc: Docs — suite counts in README/STRUCTURE/MAINTENANCE, this list, the THEMES.md app table, the skill's command table, toggles and hook events, all derived from the code, and `docs/PACKAGE_CATALOG.md` matching the Brewfile with every package described (`build-catalog.py --check`)
# ============================================
# DOCS SUITE — prose that must agree with the code
# ============================================
# The comparison with Omarchy found four docs describing a setup that
# no longer existed. `dotfiles keys --check` fixed the keybindings;
# this suite covers the rest: the facts scripts/docs-sync.py generates
# (suite counts, the Testing list, toggle lists), the app list in
# THEMES.md, and the command table in the agent skill.
# Every check derives the truth from the filesystem or the CLI, never
# from another doc.
# ============================================
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

cd "$ROOT"

section "generated facts: suite counts, the Testing list, toggle lists"

# scripts/docs-sync.py derives these from tests/*-test.sh (each suite's
# "# doc:" line) and bin/dotfiles-toggle's flag table; --check fails when a
# doc lags. A new suite or toggle needs its own line plus one run of it.
out=$(python3 scripts/docs-sync.py --check 2>&1) || fail "docs match their sources" "$out"
pass "docs match their sources (scripts/docs-sync.py --check)"

# The check must actually catch drift: a copy with one more suite and one
# more toggle reports the files that lag, and a sync fixes them.
copy="$TEST_TMP/repo"
mkdir -p "$copy/tests" "$copy/bin" "$copy/docs" "$copy/agents/skills/dotfiles" "$copy/scripts"
cp tests/*-test.sh "$copy/tests/"
cp bin/dotfiles-toggle "$copy/bin/"
cp README.md QUICK_REFERENCE.md "$copy/"
cp docs/STRUCTURE.md docs/MAINTENANCE.md "$copy/docs/"
cp agents/skills/dotfiles/commands.md "$copy/agents/skills/dotfiles/"
printf '#!/usr/bin/env bash\n# doc: Example — a suite added for this test\n' > "$copy/tests/zz-example-test.sh"
/usr/bin/awk '{ if ($0 ~ /^#   tap-auto-update /) print "#   zz-flag        a flag added for this test"; print }' bin/dotfiles-toggle > "$copy/bin/dotfiles-toggle"
set +e; out=$(DOCS_SYNC_ROOT="$copy" python3 scripts/docs-sync.py --check 2>&1); rc=$?; set -e
assert_eq "$rc" "1" "--check fails when a suite and a toggle are added"
assert_contains "$out" "README.md" "naming the suite count's doc"
assert_contains "$out" "QUICK_REFERENCE.md" "and a toggle list's doc"
DOCS_SYNC_ROOT="$copy" python3 scripts/docs-sync.py >/dev/null
assert_succeeds "a sync brings the copy back in line" env DOCS_SYNC_ROOT="$copy" python3 scripts/docs-sync.py --check
# shellcheck disable=SC2016  # backticks are literal markdown
assert_file_contains "$copy/docs/MAINTENANCE.md" '^- \*\*Example\*\* (`zz-example`) — a suite added for this test$' "the new suite gets its bullet"
assert_file_contains "$copy/bin/dotfiles-toggle" "^KNOWN_FLAGS=(.* zz-flag tap-auto-update)$" "and KNOWN_FLAGS gains the flag"

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


section "hook events"

# Events fired by the code must be the events the skill and the hook
# command's own help advertise.
fired=$(/usr/bin/grep -rhoE 'dotfiles[-_ ]hook"? [a-z][a-z-]*' bin scripts install.sh update.sh | awk '{print $NF}' | sort -u)
for event in $fired; do
    /usr/bin/grep -q "$event" agents/skills/dotfiles/commands.md || fail "skill documents every hook event" "$event is fired but undocumented"
    /usr/bin/grep -q "$event" bin/dotfiles-hook || fail "dotfiles hook --help lists every event" "$event is fired but not in the help"
done
pass "every fired hook event is documented"

section "front-door docs"

# The cheat sheet and the maintenance guide are what a person reads, the
# skill is what an agent reads. Each toggle, fired hook event, command
# group and theme template must reach the human docs too, or a feature
# ships visible only to agents.
for event in $fired; do
    /usr/bin/grep -q "$event" docs/MAINTENANCE.md || fail "docs/MAINTENANCE.md lists every hook event" "$event is missing"
done
pass "docs/MAINTENANCE.md lists every hook event"
for group in $(bin/dotfiles commands --plain | cut -f1 | awk '{print $1}' | sort -u); do
    for doc in QUICK_REFERENCE.md docs/MAINTENANCE.md; do
        /usr/bin/grep -qE "dotfiles $group([ -]|\`|$)" "$doc" || fail "$doc mentions every command group" "dotfiles $group is missing"
    done
done
pass "QUICK_REFERENCE.md and MAINTENANCE.md mention every command group"
for tpl in themes/_templates/*.tpl; do
    /usr/bin/grep -q "$(basename "$tpl")" docs/THEMES.md || fail "docs/THEMES.md lists every template" "$(basename "$tpl") is missing"
done
pass "docs/THEMES.md lists every template"

section "package catalog"

# docs/PACKAGE_CATALOG.md is generated from the Brewfile and the metadata in
# scripts/catalog/meta/. It went months without a rebuild once; --check
# rebuilds it in memory and fails when it differs (build date aside) or a
# package has no description or link.
if out=$(python3 scripts/catalog/build-catalog.py --check 2>&1); then
    pass "docs/PACKAGE_CATALOG.md matches the Brewfile and every package is described"
else
    fail "docs/PACKAGE_CATALOG.md matches the Brewfile and every package is described" "$out"
fi
