#!/usr/bin/env bash
# ============================================
# FONT SUITE — dotfiles font
# ============================================
# The real command against a copy of the theme machinery, with fc-list
# stubbed so "installed" is whatever the test says it is.
# ============================================
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

MOCK="$TEST_TMP/dotfiles"
STUB="$TEST_TMP/stub"
mkdir -p "$MOCK/scripts" "$MOCK/bin" "$STUB" "$MOCK/.config/ghostty" "$MOCK/.config/zed" "$MOCK/.config/vscode"
cp -R "$ROOT/themes" "$MOCK/themes"
for f in theme-utils.sh theme-render.sh theme-background.sh apply-theme.sh _helpers.sh; do
    cp "$ROOT/scripts/$f" "$MOCK/scripts/"
done
for b in dotfiles-font dotfiles-hook dotfiles-toggle; do
    cp "$ROOT/bin/$b" "$MOCK/bin/"
done
echo '{"theme": {"mode": "dark", "dark": "old"}, "buffer_font_family": "Fira Code", "tab_size": 2}' > "$MOCK/.config/zed/settings.base.json"
printf '{\n  "workbench.colorTheme": "{{ vscode_theme }}",\n  "editor.fontFamily": "{{ font_family }}",\n  "editor.fontSize": 18,\n}\n' > "$MOCK/.config/vscode/settings.base.json"
export DOTFILES_DIR="$MOCK"
export DOTFILES_STATE_DIR="$HOME/.local/state/dotfiles"
RENDERED="$DOTFILES_STATE_DIR/current/theme"
FONT="$MOCK/bin/dotfiles-font"
INSTALLED="$TEST_TMP/installed-fonts"
printf 'Fira Code\nJetBrainsMono Nerd Font\nMenlo\n' > "$INSTALLED"
cat > "$STUB/fc-list" <<STUB
#!/bin/bash
# fc-list :family="X" family  -> that family if installed; fc-list :spacing=mono family -> all
for a in "\$@"; do
    case "\$a" in
        :family=*) grep -Fx -- "\${a#:family=}" "$INSTALLED"; exit 0 ;;
    esac
done
cat "$INSTALLED"
STUB
chmod +x "$STUB/fc-list"
export PATH="$STUB:$PATH"
run() { bash "$FONT" "$@" 2>&1; }

section "current and list"
assert_eq "$(run current)" "Fira Code" "default family before anything is set"
assert_eq "$(run)" "Fira Code" "no argument means current"
out=$(run list)
assert_contains "$out" "JetBrainsMono Nerd Font" "list shows installed monospace families"

section "set before any theme"
out=$(run set "Menlo")
assert_contains "$out" "Font: Menlo" "reports the family"
assert_contains "$out" "No theme applied yet" "explains it takes effect at the first theme"
assert_eq "$(cat "$DOTFILES_STATE_DIR/font")" "Menlo" "state file written"
assert_eq "$(run current)" "Menlo" "current reads the state file"

section "the family reaches every app through the theme render"
echo "tokyo-night" > "$HOME/.dotfiles-theme"
bash "$MOCK/scripts/apply-theme.sh" tokyo-night true >/dev/null 2>&1
assert_file_contains "$RENDERED/ghostty-font" '^font-family = "Menlo"$' "Ghostty font file rendered"
assert_file_contains "$MOCK/.config/ghostty/font.generated" '^font-family = "Menlo"$' "and installed as font.generated"
assert_file_contains "$RENDERED/wezterm-font.lua" "^return 'Menlo'$" "WezTerm font file rendered"
assert_eq "$(jq -r .buffer_font_family "$MOCK/.config/zed/settings.json")" "Menlo" "Zed buffer font set"
assert_file_contains "$MOCK/.config/vscode/settings.json" '"editor.fontFamily": "Menlo"' "VS Code font set"
assert_eq "$(jq -r .buffer_font_family "$MOCK/.config/zed/settings.base.json")" "Fira Code" "Zed base keeps its default"
assert_file_contains "$MOCK/.config/vscode/settings.base.json" '"editor.fontFamily": "{{ font_family }}"' "VS Code base keeps the placeholder"

section "set with a theme re-renders and fires the hook"
mkdir -p "$HOME/.config/dotfiles/hooks/font-set.d"
# shellcheck disable=SC2016  # $1 is meant for the hook, not this shell
printf '#!/bin/bash\necho "font:$1" > "%s/hook-ran"\n' "$HOME" > "$HOME/.config/dotfiles/hooks/font-set.d/10-record.sh"
out=$(run set "JetBrainsMono Nerd Font")
assert_contains "$out" "Font: JetBrainsMono Nerd Font" "reports the family"
assert_file_contains "$RENDERED/ghostty-font" '^font-family = "JetBrainsMono Nerd Font"$' "Ghostty re-rendered"
assert_eq "$(jq -r .buffer_font_family "$MOCK/.config/zed/settings.json")" "JetBrainsMono Nerd Font" "Zed re-rendered"
assert_eq "$(cat "$HOME/hook-ran")" "font:JetBrainsMono Nerd Font" "font-set hook ran with the family"
# An in-app Zed edit survives a font change and lands in the base
jq '.tab_size = 8' "$MOCK/.config/zed/settings.json" > "$TEST_TMP/z" && mv "$TEST_TMP/z" "$MOCK/.config/zed/settings.json"
run set "Menlo" >/dev/null
assert_eq "$(jq -r .tab_size "$MOCK/.config/zed/settings.base.json")" "8" "in-app Zed edit adopted across a font change"
assert_eq "$(jq -r .buffer_font_family "$MOCK/.config/zed/settings.base.json")" "Fira Code" "base font default untouched by the adopt"

section "validation"
set +e; out=$(run set "Comic Sans"); rc=$?; set -e
assert_eq "$rc" "1" "an uninstalled family is refused"
assert_contains "$out" "No installed font family matches 'Comic Sans'" "and named"
assert_eq "$(run current)" "Menlo" "state unchanged after a refusal"
set +e; out=$(run set); rc=$?; set -e
assert_eq "$rc" "1" "set without a family is a usage error"
set +e; out=$(run bogus); rc=$?; set -e
assert_eq "$rc" "1" "unknown verb exits 1"
out=$(PATH="/usr/bin:/bin" run set "Anything Goes")   # no fontconfig (and no jq) on this PATH
assert_contains "$out" "Font: Anything Goes" "without fontconfig the family is taken on trust"

section "reset"
out=$(run reset)
assert_contains "$out" "Font: Fira Code (default)" "reset names the default"
assert_file_not_exists "$DOTFILES_STATE_DIR/font" "state file removed"
assert_file_contains "$RENDERED/ghostty-font" '^font-family = "Fira Code"$' "render back to the default"
assert_eq "$(cat "$HOME/hook-ran")" "font:Fira Code" "hook fired with the default"

section "bash 3.2"
assert_succeeds "parses under /bin/bash" /bin/bash -n "$FONT"
assert_eq "$(/bin/bash "$FONT" current)" "Fira Code" "runs under /bin/bash"
