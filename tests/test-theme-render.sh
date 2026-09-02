#!/usr/bin/env bash

# ============================================
# THEME RENDERER TEST SUITE
# ============================================
# Tests scripts/theme-render.sh in isolation: every token form, the
# colour maths, derived keys for minimal palettes, the vars file, and
# the exit codes for a bad palette / unresolved token.
#
# Runs under stock bash 3.2 as well as bash 5 — the renderer is on the
# curl-bootstrap path.
# Usage: bash tests/test-theme-render.sh
# ============================================

set -euo pipefail

REAL_DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RENDER="$REAL_DOTFILES_DIR/scripts/theme-render.sh"

PASS=0
FAIL=0
FAILURES=()

pass() { PASS=$((PASS + 1)); echo -e "  \033[0;32m✓\033[0m $1"; }
fail() { FAIL=$((FAIL + 1)); FAILURES+=("$1"); echo -e "  \033[0;31m✗\033[0m $1"; }

assert_eq() {
    local actual="$1" expected="$2" label="$3"
    if [[ "$actual" == "$expected" ]]; then pass "$label"; else fail "$label (expected '$expected', got '$actual')"; fi
}

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

cat > "$WORK/colors.toml" <<'EOF'
# a comment
mode = "dark"
accent = "#7aa2f7"
background = "#1a1b26"   # trailing comment
foreground = '#c0caf5'
red = "#f7768e"
green = "#9ece6a"
yellow = "#e0af68"
blue = "#7aa2f7"
magenta = "#bb9af7"
cyan = "#7dcfff"
muted = "#565f89"
EOF
printf 'theme_name="tokyo-night"\nbat_theme="TwoDark"\n' > "$WORK/vars"

# render <template-text> [vars] → stdout
render() {
    local tpl="$WORK/t.tpl"
    printf '%s\n' "$1" > "$tpl"
    bash "$RENDER" "$WORK/colors.toml" "${2:-$WORK/vars}" "$tpl" 2>/dev/null
}

echo ""
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║   Theme Renderer Tests                                    ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""

echo "Test 1: Token forms"
assert_eq "$(render '{{ accent }}')" "#7aa2f7" "plain key"
assert_eq "$(render '{{accent}}')" "#7aa2f7" "no inner spaces"
assert_eq "$(render '{{   accent   }}')" "#7aa2f7" "extra inner spaces"
assert_eq "$(render '{{ accent_strip }}')" "7aa2f7" "_strip drops the #"
assert_eq "$(render '{{ accent_rgb }}')" "122,162,247" "_rgb gives decimals"
assert_eq "$(render '{{ accent_argb }}')" "0xff7aa2f7" "_argb gives 0xffRRGGBB"
assert_eq "$(render 'a={{ red }} b={{ green }}')" "a=#f7768e b=#9ece6a" "two tokens on one line"
assert_eq "$(render 'literal & text {{ blue }} 50%')" "literal & text #7aa2f7 50%" "ampersand and percent survive"
assert_eq "$(render "$(printf 'l1 {{ red }}\nl2 {{ cyan }}')")" "$(printf 'l1 #f7768e\nl2 #7dcfff')" "multi-line template"
echo ""

echo "Test 2: Palette parsing"
assert_eq "$(render '{{ foreground }}')" "#c0caf5" "single-quoted value"
assert_eq "$(render '{{ background }}')" "#1a1b26" "trailing comment stripped"
assert_eq "$(render '{{ mode }}')" "dark" "non-colour key"
echo ""

echo "Test 3: Colour maths"
assert_eq "$(render '{{ mix background foreground 50% }}')" "#6d738e" "mix 50% by percentage"
assert_eq "$(render '{{ mix background foreground 0.5 }}')" "#6d738e" "mix 0.5 by fraction"
assert_eq "$(render '{{ mix background foreground 0% }}')" "#1a1b26" "mix 0% is the first colour"
assert_eq "$(render '{{ mix background foreground 100% }}')" "#c0caf5" "mix 100% is the second colour"
assert_eq "$(render '{{ mix_strip background foreground 50% }}')" "6d738e" "mix_strip"
assert_eq "$(render '{{ mix_rgb background foreground 50% }}')" "109,115,142" "mix_rgb"
assert_eq "$(render '{{ mix_argb background foreground 50% }}')" "0xff6d738e" "mix_argb"
assert_eq "$(render '{{ mix background #ffffff 10% }}')" "#31323c" "mix with a literal hex"
echo ""

echo "Test 4: Derived keys for a minimal palette"
cat > "$WORK/minimal.toml" <<'EOF'
background = "#101010"
foreground = "#e0e0e0"
red = "#ff0000"
green = "#00ff00"
yellow = "#ffff00"
blue = "#0000ff"
magenta = "#ff00ff"
cyan = "#00ffff"
EOF
drender() { printf '%s\n' "$1" > "$WORK/d.tpl"; bash "$RENDER" "$WORK/minimal.toml" "" "$WORK/d.tpl" 2>/dev/null; }
assert_eq "$(drender '{{ accent }}')" "#0000ff" "accent defaults to blue"
assert_eq "$(drender '{{ orange }}')" "#ffff00" "orange defaults to yellow"
assert_eq "$(drender '{{ purple }}')" "#ff00ff" "purple defaults to magenta"
assert_eq "$(drender '{{ mode }}')" "dark" "mode from dark background luminance"
assert_eq "$(drender '{{ is_light }}')" "false" "is_light false"
assert_eq "$(drender '{{ theme_type }}')" "dark" "theme_type mirrors mode"
assert_eq "$(drender '{{ bright_red }}')" "#ff3333" "bright_red = red mixed 20% toward white"
assert_eq "$(drender '{{ dark_background }}')" "#0c0c0c" "dark_background = background 25% toward black"
assert_eq "$(drender '{{ muted }}')" "#787878" "muted = fg/bg midpoint"
assert_eq "$(drender '{{ white }}')" "#e0e0e0" "white defaults to foreground"
assert_eq "$(drender '{{ selection_foreground }}')" "#e0e0e0" "selection_foreground defaults to bright_foreground"
assert_eq "$(drender '{{ black }}')" "#0c0c0c" "black defaults to dark_background"

cat > "$WORK/light.toml" <<'EOF'
background = "#fafafa"
foreground = "#202020"
red = "#aa0000"
green = "#00aa00"
yellow = "#aaaa00"
blue = "#0000aa"
magenta = "#aa00aa"
cyan = "#00aaaa"
EOF
printf '%s\n' '{{ mode }} {{ is_light }}' > "$WORK/l.tpl"
assert_eq "$(bash "$RENDER" "$WORK/light.toml" "" "$WORK/l.tpl" 2>/dev/null)" "light true" "light mode from luminance"
echo ""

echo "Test 5: Vars file and precedence"
assert_eq "$(render '{{ theme_name }}/{{ bat_theme }}')" "tokyo-night/TwoDark" "vars file keys are tokens"
printf 'accent="#000000"\n' > "$WORK/override-vars"
assert_eq "$(render '{{ accent }}' "$WORK/override-vars")" "#000000" "vars file can override a palette key"
assert_eq "$(render '{{ accent }}' "")" "#7aa2f7" "empty vars file argument is allowed"
echo ""

echo "Test 6: Failure modes"
printf '%s\n' '{{ no_such_key }}' > "$WORK/bad.tpl"
set +e; out=$(bash "$RENDER" "$WORK/colors.toml" "" "$WORK/bad.tpl" 2>"$WORK/err"); rc=$?; set -e
assert_eq "$rc" "3" "unresolved token exits 3"
assert_eq "$out" "{{ no_such_key }}" "unresolved token left visible in output"
if /usr/bin/grep -q "unresolved token {{ no_such_key }}" "$WORK/err"; then pass "unresolved token named on stderr"; else fail "unresolved token not reported"; fi

printf '%s\n' '{{ mix background nope 5% }}' > "$WORK/bad2.tpl"
set +e; bash "$RENDER" "$WORK/colors.toml" "" "$WORK/bad2.tpl" >/dev/null 2>&1; rc=$?; set -e
assert_eq "$rc" "3" "mix with unknown colour exits 3"

printf 'background = "nope"\nforeground = "#ffffff"\n' > "$WORK/broken.toml"
set +e; bash "$RENDER" "$WORK/broken.toml" "" "$WORK/bad.tpl" >/dev/null 2>&1; rc=$?; set -e
assert_eq "$rc" "2" "non-hex background exits 2"

printf 'red = "#ff0000"\n' > "$WORK/empty.toml"
set +e; bash "$RENDER" "$WORK/empty.toml" "" "$WORK/bad.tpl" >/dev/null 2>&1; rc=$?; set -e
assert_eq "$rc" "2" "palette without background/foreground exits 2"
echo ""

echo "Test 7: Real templates render without unresolved tokens for every theme"
for theme_dir in "$REAL_DOTFILES_DIR"/themes/*/; do
    theme=$(basename "$theme_dir")
    [[ "$theme" == _* ]] && continue
    [[ -f "$theme_dir/colors.toml" ]] || continue
    {
        cat "$theme_dir/theme.conf"
        echo "theme_name=\"$theme\""
        echo "dotfiles_dir=\"/x\""
        echo "nvim_plugin_spec=\"/x/$theme.lua\""
    } > "$WORK/vars-$theme"
    ok=true
    for tpl in "$REAL_DOTFILES_DIR"/themes/_templates/*.tpl; do
        if ! bash "$RENDER" "$theme_dir/colors.toml" "$WORK/vars-$theme" "$tpl" >/dev/null 2>&1; then
            ok=false
            fail "$theme: $(basename "$tpl") failed to render"
        fi
    done
    [[ "$ok" == true ]] && pass "$theme: all $(find "$REAL_DOTFILES_DIR/themes/_templates" -name '*.tpl' | wc -l | tr -d ' ') templates render"
done
echo ""

echo "════════════════════════════════════════════════════════════"
echo -e "  \033[0;32mPassed: $PASS\033[0m  |  \033[0;31mFailed: $FAIL\033[0m"
echo "════════════════════════════════════════════════════════════"
if [[ ${#FAILURES[@]} -gt 0 ]]; then
    echo ""
    for f in "${FAILURES[@]}"; do echo -e "    \033[0;31m✗\033[0m $f"; done
fi
echo ""
[[ $FAIL -eq 0 ]]
