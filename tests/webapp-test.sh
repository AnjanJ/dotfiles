#!/usr/bin/env bash

# ============================================
# WEB APP LAUNCHER TEST SUITE
# ============================================
# bin/dotfiles-webapp-install and -remove against a mock DOTFILES_DIR
# holding a copy of the real aerospace.toml, bundles written under a
# sandbox Applications dir, curl stubbed (FIXTURE_ICON is what any
# download "returns"), pgrep stubbed so nothing is reloaded for real.
# sips and iconutil are the real macOS tools.
#
# Usage: tests/run webapp   (or /opt/homebrew/bin/bash tests/webapp-test.sh)
# ============================================

set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

MOCK="$TEST_TMP/mock"
APPS="$TEST_TMP/apps"
STUB="$TEST_TMP/stub"
CALLS="$TEST_TMP/calls.log"
TOML="$MOCK/.config/aerospace/aerospace.toml"
ORIGINAL="$TEST_TMP/aerospace.original.toml"
INSTALL="$ROOT/bin/dotfiles-webapp-install"
REMOVE="$ROOT/bin/dotfiles-webapp-remove"

mkdir -p "$MOCK/.config/aerospace" "$MOCK/scripts" "$MOCK/bin" "$APPS" "$STUB"
cp "$ROOT/.config/aerospace/aerospace.toml" "$TOML"
cp "$TOML" "$ORIGINAL"
cp "$ROOT/scripts/_helpers.sh" "$MOCK/scripts/"
cp "$ROOT/bin/dotfiles-restart" "$ROOT/bin/dotfiles-toggle" "$MOCK/bin/"
export DOTFILES_DIR="$MOCK"
export DOTFILES_LAUNCHER_APPS_DIR="$APPS"
export DOTFILES_STATE_DIR="$TEST_TMP/state"
export DOTFILES_LAUNCHER_NO_REGISTER=1   # keep sandbox bundles out of LaunchServices

# A 2x2 red PNG, built here so the suite has no binary fixture to track
FIXTURE="$TEST_TMP/icon.png"
python3 - "$FIXTURE" <<'EOF'
import struct, sys, zlib
def chunk(t, d): return struct.pack('>I', len(d)) + t + d + struct.pack('>I', zlib.crc32(t + d) & 0xffffffff)
raw = b''.join(b'\x00' + b'\xff\x00\x00' * 2 for _ in range(2))
png = b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR', struct.pack('>IIBBBBB', 2, 2, 8, 2, 0, 0, 0)) + chunk(b'IDAT', zlib.compress(raw)) + chunk(b'IEND', b'')
open(sys.argv[1], 'wb').write(png)
EOF

cat > "$STUB/curl" <<EOF
#!/bin/bash
echo "curl \$*" >> "$CALLS"
dest=""
while [[ \$# -gt 0 ]]; do case "\$1" in -o) dest="\$2"; shift 2 ;; *) shift ;; esac; done
[[ -n "\${FIXTURE_ICON:-}" && -n "\$dest" ]] || exit 22
cp "\$FIXTURE_ICON" "\$dest"
EOF
printf '#!/bin/bash\nexit 1\n' > "$STUB/pgrep"
printf '#!/bin/bash\necho "aerospace $*" >> "%s"\n' "$CALLS" > "$STUB/aerospace"
chmod +x "$STUB"/*
export PATH="$STUB:$PATH"

plist() { /usr/libexec/PlistBuddy -c "Print $2" "$APPS/$1.app/Contents/Info.plist" 2>/dev/null; }
launch() { cat "$APPS/$1.app/Contents/MacOS/launch"; }
rule_block() { awk -v b="# dotfiles-webapp: $1 (begin)" -v e="# dotfiles-webapp: $1 (end)" '$0==b{p=1} p{print} $0==e{p=0}' "$TOML"; }
line_of() { /usr/bin/grep -nF -- "$1" "$TOML" | head -1 | cut -d: -f1; }

echo ""
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║   Web App Launcher Tests                                  ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""

section "Test 1: Install with a workspace and a fetched icon"
: > "$CALLS"
set +e; out=$(FIXTURE_ICON="$FIXTURE" "$INSTALL" Gmail https://mail.google.com --workspace 5 2>&1); rc=$?; set -e
assert_eq "$rc" "0" "install exits 0"
assert_dir_exists "$APPS/Gmail.app" "bundle created"
assert_perm "$APPS/Gmail.app/Contents/MacOS/launch" "755" "launch script is executable"
assert_contains "$(launch Gmail)" "open -na \"Google Chrome\" --args --app='https://mail.google.com'" "launch line opens Chrome --app"
assert_eq "$(plist Gmail CFBundleIdentifier)" "com.dotfiles.webapp.gmail" "bundle id derived from the name"
assert_eq "$(plist Gmail DotfilesLauncher)" "webapp" "bundle marked as ours"
assert_eq "$(plist Gmail DotfilesPayload)" "https://mail.google.com" "URL recorded in the plist"
assert_eq "$(plist Gmail CFBundleIconFile)" "icon" "plist points at the icon"
assert_file_exists "$APPS/Gmail.app/Contents/Resources/icon.icns" "icon.icns built from the fetched image"
assert_succeeds "plist is valid" plutil -lint -s "$APPS/Gmail.app/Contents/Info.plist"
assert_file_contains "$CALLS" "apple-touch-icon" "icon fetch tried the site's apple-touch-icon"
block=$(rule_block Gmail)
assert_contains "$block" "if.app-id = 'com.google.Chrome'" "rule matches Chrome"
assert_contains "$block" "if.window-title-regex-substring = 'Gmail'" "rule matches the name by default"
assert_contains "$block" "run = ['move-node-to-workspace 5']" "rule moves to workspace 5"
if [[ "$(line_of '# dotfiles-webapp: Gmail (begin)')" -lt "$(line_of '# --- Workspace 1: Terminal ---')" ]]; then
    pass "launcher rule sits above the app-wide rules"
else
    fail "launcher rule sits above the app-wide rules"
fi
assert_contains "$out" "workspace 5" "reports the placement"
echo ""

section "Test 2: Reinstall replaces, never duplicates"
FIXTURE_ICON="$FIXTURE" "$INSTALL" Gmail mail.google.com --float --workspace 5 --title-regex Inbox >/dev/null 2>&1
assert_count "$TOML" "# dotfiles-webapp: Gmail (begin)" 1 "one rule block after reinstall"
block=$(rule_block Gmail)
assert_contains "$block" "run = ['layout floating', 'move-node-to-workspace 5']" "float and workspace in one rule"
assert_contains "$block" "regex-substring = 'Inbox'" "--title-regex honoured"
assert_contains "$(launch Gmail)" "--app='https://mail.google.com'" "schemeless URL got https"
echo ""

section "Test 3: No icon available is a warning, not a failure"
set +e; out=$("$INSTALL" Example example.com --float 2>&1); rc=$?; set -e
assert_eq "$rc" "0" "install still exits 0"
assert_contains "$out" "No usable icon" "warns about the icon"
assert_file_not_exists "$APPS/Example.app/Contents/Resources/icon.icns" "no icon.icns"
assert_not_contains "$(cat "$APPS/Example.app/Contents/Info.plist")" "CFBundleIconFile" "plist has no icon key"
assert_contains "$(rule_block Example)" "run = ['layout floating']" "float-only rule"
: > "$CALLS"
"$INSTALL" Quiet example.com --no-icon >/dev/null 2>&1
assert_file_not_contains "$CALLS" "curl" "--no-icon never calls curl"
echo ""

section "Test 4: No placement, no rule"
set +e; out=$("$INSTALL" Plain example.com --no-icon 2>&1); rc=$?; set -e
assert_eq "$rc" "0" "install without --workspace/--float exits 0"
assert_contains "$out" "No AeroSpace rule" "says no rule was written"
assert_file_not_contains "$TOML" "dotfiles-webapp: Plain" "no rule block"
echo ""

section "Test 5: Validation"
set +e; "$INSTALL" Bad 'javascript:alert(1)' >/dev/null 2>&1; rc=$?; set -e
assert_eq "$rc" "1" "javascript: URL refused"
set +e; "$INSTALL" Bad 'https://a b.com' >/dev/null 2>&1; rc=$?; set -e
assert_eq "$rc" "1" "URL with whitespace refused"
set +e; "$INSTALL" 'a/b' example.com >/dev/null 2>&1; rc=$?; set -e
assert_eq "$rc" "1" "name with a slash refused"
set +e; "$INSTALL" Bad example.com --workspace 'a b' >/dev/null 2>&1; rc=$?; set -e
assert_eq "$rc" "1" "bad workspace refused"
set +e; "$INSTALL" Bad example.com --bogus >/dev/null 2>&1; rc=$?; set -e
assert_eq "$rc" "1" "unknown option refused"
set +e; "$INSTALL" OnlyName >/dev/null 2>&1; rc=$?; set -e
assert_eq "$rc" "1" "missing URL prints usage and exits 1"
assert_dir_not_exists "$APPS/Bad.app" "nothing installed on a refused call"
echo ""

section "Test 6: Remove"
out=$("$REMOVE" --list)
assert_contains "$out" "Gmail" "--list shows Gmail"
assert_contains "$out" "https://mail.google.com" "--list shows the URL"
mkdir -p "$APPS/Foreign.app/Contents"
assert_not_contains "$out" "Foreign" "--list ignores bundles that are not ours"
set +e; out=$("$REMOVE" Foreign 2>&1); rc=$?; set -e
assert_eq "$rc" "1" "refuses to remove a bundle it did not create"
assert_dir_exists "$APPS/Foreign.app" "foreign bundle untouched"
set +e; out=$("$REMOVE" Nope 2>&1); rc=$?; set -e
assert_eq "$rc" "1" "unknown name exits 1"
assert_contains "$out" "Gmail" "lists what is installed"
"$REMOVE" Gmail >/dev/null
assert_dir_not_exists "$APPS/Gmail.app" "bundle removed"
assert_file_not_contains "$TOML" "dotfiles-webapp: Gmail" "rule removed"
assert_count "$TOML" "# dotfiles-webapp: Example (begin)" 1 "other launcher rule intact"
for n in Example Quiet Plain; do "$REMOVE" "$n" >/dev/null; done
assert_snapshots_equal "$TOML" "$ORIGINAL" "aerospace.toml back to its original after removing everything"
set +e; "$REMOVE" >/dev/null 2>&1; rc=$?; set -e
assert_eq "$rc" "1" "remove with no name exits 1"
echo ""

section "Test 7: A config without markers gets them"
/usr/bin/grep -v 'DOTFILES_LAUNCHERS_' "$ORIGINAL" > "$TOML"
"$INSTALL" Later example.com --float --no-icon >/dev/null 2>&1
first_rule=$(/usr/bin/grep -n '^\[\[on-window-detected\]\]' "$TOML" | head -1 | cut -d: -f1)
if [[ "$(line_of '# DOTFILES_LAUNCHERS_START')" -lt "$first_rule" ]]; then
    pass "markers inserted before the first window rule"
else
    fail "markers inserted before the first window rule"
fi
assert_count "$TOML" "DOTFILES_LAUNCHERS_START" 1 "one start marker"
assert_contains "$(rule_block Later)" "layout floating" "rule written inside the new markers"
echo ""

section "Test 8: Runs under /bin/bash 3.2"
set +e; /bin/bash "$REMOVE" --list >/dev/null; rc=$?; set -e
assert_eq "$rc" "0" "remove --list under /bin/bash"
set +e; /bin/bash "$INSTALL" Legacy example.com --no-icon >/dev/null 2>&1; rc=$?; set -e
assert_eq "$rc" "0" "install under /bin/bash"
echo ""
