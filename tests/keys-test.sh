#!/usr/bin/env bash

# ============================================
# KEYBINDING CHEATSHEET TEST SUITE
# ============================================
# Tests bin/dotfiles-keys against a fixture aerospace.toml: every value
# form (single quotes, triple quotes, arrays, trailing comments), key
# prettifying, `# desc:` overrides, derived descriptions, the markdown
# tables, --update between markers, and --check drift detection. Then
# checks the real config/doc pair is in sync.
# Usage: tests/run keys   (or /opt/homebrew/bin/bash tests/keys-test.sh)
# ============================================

set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

REAL_DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
K="$REAL_DOTFILES_DIR/bin/dotfiles-keys"

WORK=$(mktemp -d)

cat > "$WORK/aerospace.toml" <<'EOF'
# Fixture config
persistent-workspaces = ['1', '2']

[gaps]
    inner.horizontal = 0

[mode.main.binding]
    # Comments that are not desc lines are ignored
    ctrl-shift-w = '''exec-and-forget open -a "Warp"'''
    # desc: Launch Chrome, new window (workspace 3)
    ctrl-shift-c = '''exec-and-forget open -na "Google Chrome" --args --new-window'''
    ctrl-shift-h = 'focus left'
    ctrl-alt-j = "move down"
    ctrl-shift-1 = 'workspace 1'
    ctrl-alt-1 = 'move-node-to-workspace 1'
    ctrl-shift-tab = 'workspace-back-and-forth'
    ctrl-shift-slash = 'layout tiles horizontal vertical'   # trailing comment
    ctrl-shift-n = 'exec-and-forget ~/.config/aerospace/scripts/cycle-app-windows.sh chrome next'
    alt-shift-m = 'focus-monitor --wrap-around next'
    ctrl-shift-semicolon = 'mode service'

    # desc: Not attached: blank line follows

    ctrl-shift-minus = 'resize smart -50'

[mode.service.binding]
    esc = ['reload-config', 'mode main']
    f = ['layout floating tiling', 'mode main'] # Toggle
    shift-down = ['volume set 0', 'mode main']
    down = 'volume down'

[[on-window-detected]]
if.app-id = 'x'
run = 'move-node-to-workspace 1'
EOF

cp "$WORK/aerospace.toml" "$WORK/pristine.toml"   # Test 4 edits the fixture; the lint tests want the original

tsv() { "$K" --config "$WORK/aerospace.toml" --tsv; }
row() { tsv | awk -F'\t' -v k="$1" '$2 == k { print $1 "|" $3 "|" $4 }'; }

echo ""
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║   Keybinding Cheatsheet Tests                             ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""

section "Test 1: Parsing and derived descriptions"
assert_eq "$(tsv | wc -l | tr -d ' ')" "16" "16 bindings parsed (on-window-detected ignored)"
assert_eq "$(row 'Ctrl+Shift+W')" 'main|Launch Warp|exec-and-forget open -a "Warp"' "triple-quoted launcher"
assert_eq "$(row 'Ctrl+Shift+H')" "main|Focus window left|focus left" "single-quoted command"
assert_eq "$(row 'Ctrl+Alt+J')" "main|Move window down|move down" "double-quoted command"
assert_eq "$(row 'Ctrl+Shift+1')" "main|Switch to workspace 1|workspace 1" "workspace"
assert_eq "$(row 'Ctrl+Alt+1')" "main|Move window to workspace 1|move-node-to-workspace 1" "move-node-to-workspace"
assert_eq "$(row 'Ctrl+Shift+Tab')" "main|Toggle last two workspaces|workspace-back-and-forth" "back-and-forth"
assert_eq "$(row 'Ctrl+Shift+/')" "main|Layout: tiles|layout tiles horizontal vertical" "trailing comment stripped, slash prettified"
assert_eq "$(row 'Ctrl+Shift+N')" "main|Run cycle-app-windows.sh chrome next|exec-and-forget ~/.config/aerospace/scripts/cycle-app-windows.sh chrome next" "script exec described by basename"
assert_eq "$(row 'Alt+Shift+M')" "main|Focus monitor next|focus-monitor --wrap-around next" "wrap-around flag dropped"
assert_eq "$(row 'Ctrl+Shift+;')" "main|Enter service mode|mode service" "mode change"
assert_eq "$(row 'Ctrl+Shift+-')" "main|Resize -50|resize smart -50" "desc followed by a blank line does not attach"
echo ""

section "Test 2: desc overrides and service mode"
assert_eq "$(row 'Ctrl+Shift+C')" 'main|Launch Chrome, new window (workspace 3)|exec-and-forget open -na "Google Chrome" --args --new-window' "# desc: overrides the derived text"
assert_eq "$(row 'Esc')" "service|Reload config|reload-config, mode main" "array binding: first element described, all shown"
assert_eq "$(row 'F')" "service|Toggle floating / tiling|layout floating tiling, mode main" "array with trailing comment"
assert_eq "$(row 'Shift+Down')" "service|Mute|volume set 0, mode main" "volume set 0 → Mute"
assert_eq "$(row 'Down')" "service|Volume down|volume down" "service-mode plain binding"
echo ""

section "Test 3: Markdown"
md=$("$K" --config "$WORK/aerospace.toml" --markdown)
assert_contains "$md" "### Main mode" "main heading"
# shellcheck disable=SC2016  # markdown backticks
assert_contains "$md" '### Service mode (`Ctrl+Shift+;` first)' "service heading"
assert_contains "$md" "| Key | Action | AeroSpace command |" "table header"
# shellcheck disable=SC2016
assert_contains "$md" '| `Ctrl+Shift+W` | Launch Warp | `exec-and-forget open -a "Warp"` |' "table row"
echo ""

section "Test 4: --update and --check"
cat > "$WORK/KEYBINDINGS.md" <<'EOF'
# Keys

Intro text stays.

<!-- AEROSPACE_KEYS_START -->
old content
<!-- AEROSPACE_KEYS_END -->

## Neovim

Untouched.
EOF
set +e; "$K" --config "$WORK/aerospace.toml" --doc "$WORK/KEYBINDINGS.md" --check >/dev/null 2>&1; rc=$?; set -e
assert_eq "$rc" "1" "--check fails before --update"
out=$("$K" --config "$WORK/aerospace.toml" --doc "$WORK/KEYBINDINGS.md" --update)
assert_contains "$out" "16 bindings" "--update reports binding count"
doc=$(cat "$WORK/KEYBINDINGS.md")
assert_contains "$doc" "Intro text stays." "text before markers kept"
assert_contains "$doc" "Untouched." "text after markers kept"
# shellcheck disable=SC2016
assert_contains "$doc" '| `Ctrl+Shift+W` |' "generated table inserted"
if echo "$doc" | /usr/bin/grep -q "old content"; then fail "old block not replaced"; else pass "old block replaced"; fi
set +e; "$K" --config "$WORK/aerospace.toml" --doc "$WORK/KEYBINDINGS.md" --check >/dev/null 2>&1; rc=$?; set -e
assert_eq "$rc" "0" "--check passes after --update"
"$K" --config "$WORK/aerospace.toml" --doc "$WORK/KEYBINDINGS.md" --update >/dev/null
assert_eq "$(cat "$WORK/KEYBINDINGS.md")" "$doc" "--update is idempotent"
sed -i '' "s/^    ctrl-shift-minus = 'resize smart -50'$/    ctrl-shift-q = 'close'\\
    ctrl-shift-minus = 'resize smart -50'/" "$WORK/aerospace.toml"
set +e; out=$("$K" --config "$WORK/aerospace.toml" --doc "$WORK/KEYBINDINGS.md" --check 2>&1); rc=$?; set -e
assert_eq "$rc" "1" "--check detects a binding added after the last --update"
assert_contains "$out" "run: dotfiles keys --update" "--check tells you how to fix it"
sed -i '' 's/<!-- AEROSPACE_KEYS_START -->//' "$WORK/KEYBINDINGS.md"
set +e; "$K" --config "$WORK/aerospace.toml" --doc "$WORK/KEYBINDINGS.md" --update >/dev/null 2>&1; rc=$?; set -e
assert_eq "$rc" "1" "--update refuses a doc without markers"
echo ""

section "Test 5b: --lint"
out=$("$K" --config "$WORK/pristine.toml" --lint)
assert_matches "$out" "^[0-9][0-9]* bindings: no duplicate chords" "fixture lints clean"
cp "$WORK/pristine.toml" "$WORK/bad.toml"
cat >> "$WORK/bad.toml" <<'EOF'

[mode.main.binding]
    shift-ctrl-h = 'focus right'
    ctrl-shift-x = 'some-new-command --flag'
    ctrl-shift-y = 'exec-and-forget ~/.config/aerospace/scripts/does-not-exist.sh'
EOF
set +e; out=$("$K" --config "$WORK/bad.toml" --lint 2>&1); rc=$?; set -e
assert_eq "$rc" "1" "problems exit 1"
assert_contains "$out" "[main] Shift+Ctrl+H (focus right): duplicate of ctrl-shift-h" "a chord bound twice is caught regardless of modifier order"
assert_contains "$out" "[main] Ctrl+Shift+X (some-new-command --flag): no readable description" "a command the cheatsheet cannot describe needs a # desc:"
assert_contains "$out" "script not in the repo: ~/.config/aerospace/scripts/does-not-exist.sh" "a script the repo does not ship is caught"
assert_not_contains "$out" "cycle-app-windows.sh" "a shipped script is fine"
sed -i '' 's/^    ctrl-shift-x = /    # desc: Do the new thing\
    ctrl-shift-x = /' "$WORK/bad.toml"
set +e; out=$("$K" --config "$WORK/bad.toml" --lint 2>&1); set -e
assert_not_contains "$out" "Ctrl+Shift+X" "a # desc: line satisfies the description check"
assert_not_contains "$(tsv)" $'\t'"duplicate" "--tsv output is unchanged by lint bookkeeping"
echo ""

section "Test 5c: Real config lints clean"
set +e; out=$("$K" --lint 2>&1); rc=$?; set -e
assert_eq "$rc" "0" "aerospace.toml has no duplicate chords, undescribed bindings or missing scripts"
echo ""

section "Test 5: Real config and doc are in sync"
set +e; out=$("$K" --check 2>&1); rc=$?; set -e
assert_eq "$rc" "0" "docs/KEYBINDINGS.md matches aerospace.toml"
real_count=$("$K" --tsv | wc -l | tr -d ' ')
if [[ "$real_count" -gt 50 ]]; then pass "real config parses ($real_count bindings)"; else fail "real config parsed only $real_count bindings"; fi
set +e; /bin/bash "$K" --tsv >/dev/null; rc=$?; set -e
assert_eq "$rc" "0" "runs under /bin/bash 3.2"
