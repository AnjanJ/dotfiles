#!/usr/bin/env bash

# ============================================
# TUI LAUNCHER TEST SUITE
# ============================================
# bin/dotfiles-tui-install and -remove against a mock DOTFILES_DIR with
# a copy of the real aerospace.toml, bundles under a sandbox
# Applications dir, a fixture standing in for Ghostty's icon, curl
# stubbed, pgrep stubbed so nothing is reloaded for real.
#
# Usage: tests/run tui   (or /opt/homebrew/bin/bash tests/tui-test.sh)
# ============================================

set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

MOCK="$TEST_TMP/mock"
APPS="$TEST_TMP/apps"
STUB="$TEST_TMP/stub"
CALLS="$TEST_TMP/calls.log"
TOML="$MOCK/.config/aerospace/aerospace.toml"
ORIGINAL="$TEST_TMP/aerospace.original.toml"
INSTALL="$ROOT/bin/dotfiles-tui-install"
REMOVE="$ROOT/bin/dotfiles-tui-remove"

mkdir -p "$MOCK/.config/aerospace" "$MOCK/scripts" "$MOCK/bin" "$APPS" "$STUB"
cp "$ROOT/.config/aerospace/aerospace.toml" "$TOML"
cp "$TOML" "$ORIGINAL"
cp "$ROOT/scripts/_helpers.sh" "$MOCK/scripts/"
cp "$ROOT/bin/dotfiles-restart" "$ROOT/bin/dotfiles-toggle" "$MOCK/bin/"
export DOTFILES_DIR="$MOCK"
export DOTFILES_LAUNCHER_APPS_DIR="$APPS"
export DOTFILES_STATE_DIR="$TEST_TMP/state"
export DOTFILES_LAUNCHER_NO_REGISTER=1   # keep sandbox bundles out of LaunchServices

GHOSTTY_ICNS="$TEST_TMP/Ghostty.icns"
echo "not really an icns, just bytes to copy" > "$GHOSTTY_ICNS"
export DOTFILES_GHOSTTY_ICNS="$GHOSTTY_ICNS"

FIXTURE="$TEST_TMP/icon.png"
python3 - "$FIXTURE" <<'EOF'
import struct, sys, zlib
def chunk(t, d): return struct.pack('>I', len(d)) + t + d + struct.pack('>I', zlib.crc32(t + d) & 0xffffffff)
raw = b''.join(b'\x00' + b'\x00\x00\xff' * 2 for _ in range(2))
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
chmod +x "$STUB"/*
export PATH="$STUB:$PATH"

plist() { /usr/libexec/PlistBuddy -c "Print $2" "$APPS/$1.app/Contents/Info.plist" 2>/dev/null; }
launch() { cat "$APPS/$1.app/Contents/MacOS/launch"; }
rule_block() { awk -v b="# dotfiles-tui: $1 (begin)" -v e="# dotfiles-tui: $1 (end)" '$0==b{p=1} p{print} $0==e{p=0}' "$TOML"; }

echo ""
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║   TUI Launcher Tests                                      ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""

section "Test 1: Default install floats and borrows Ghostty's icon"
set +e; out=$("$INSTALL" lazygit lazygit 2>&1); rc=$?; set -e
assert_eq "$rc" "0" "install exits 0"
assert_dir_exists "$APPS/lazygit.app" "bundle created"
assert_contains "$(launch lazygit)" "open -na Ghostty --args --title='lazygit' -e /bin/zsh -lic 'lazygit'" "launch line runs the command in Ghostty via a login shell"
assert_eq "$(plist lazygit CFBundleIdentifier)" "com.dotfiles.tui.lazygit" "bundle id"
assert_eq "$(plist lazygit DotfilesLauncher)" "tui" "bundle marked as ours"
assert_eq "$(plist lazygit DotfilesPayload)" "lazygit" "command recorded"
assert_snapshots_equal "$APPS/lazygit.app/Contents/Resources/icon.icns" "$GHOSTTY_ICNS" "Ghostty's icon copied in"
assert_succeeds "plist is valid" plutil -lint -s "$APPS/lazygit.app/Contents/Info.plist"
block=$(rule_block lazygit)
assert_contains "$block" "if.app-id = 'com.mitchellh.ghostty'" "rule matches Ghostty"
assert_contains "$block" "regex-substring = 'lazygit'" "rule matches the title"
assert_contains "$block" "run = ['layout floating']" "floats by default"
assert_contains "$out" "float" "reports the placement"
echo ""

section "Test 2: Options"
FIXTURE_ICON="$FIXTURE" "$INSTALL" "System Monitor" "btop --utf-force" --workspace 6 --icon https://example.com/i.png >/dev/null 2>&1
assert_contains "$(launch 'System Monitor')" "--title='System Monitor' -e /bin/zsh -lic 'btop --utf-force'" "name and command quoted for the shell"
assert_eq "$(plist 'System Monitor' CFBundleIdentifier)" "com.dotfiles.tui.system-monitor" "slug for a name with a space"
assert_contains "$(rule_block 'System Monitor')" "run = ['layout floating', 'move-node-to-workspace 6']" "float plus workspace"
if [[ "$(stat -f %z "$APPS/System Monitor.app/Contents/Resources/icon.icns")" -gt 1000 ]]; then
    pass "--icon URL converted to a real icns"
else
    fail "--icon URL converted to a real icns"
fi
set +e; out=$("$INSTALL" Disk "dust; read -n 1 -s" --tile 2>&1); rc=$?; set -e
assert_eq "$rc" "0" "--tile install exits 0"
assert_contains "$out" "No AeroSpace rule" "--tile without a workspace writes no rule"
assert_file_not_contains "$TOML" "dotfiles-tui: Disk" "no rule block for Disk"
"$INSTALL" Tiled htop --tile --workspace 8 >/dev/null 2>&1
assert_contains "$(rule_block Tiled)" "run = ['move-node-to-workspace 8']" "--tile with a workspace only moves"
set +e; out=$("$INSTALL" NoIcon top --icon /nonexistent.png 2>&1); rc=$?; set -e
assert_eq "$rc" "0" "unreadable --icon is not fatal"
assert_contains "$out" "using Ghostty's" "falls back to Ghostty's icon"
set +e; out=$(DOTFILES_GHOSTTY_ICNS=/nonexistent.icns "$INSTALL" Bare top 2>&1); rc=$?; set -e
assert_eq "$rc" "0" "missing Ghostty icon is not fatal"
assert_file_not_exists "$APPS/Bare.app/Contents/Resources/icon.icns" "no icon when nothing is available"
"$INSTALL" Quote "echo it's" --no-icon >/dev/null 2>&1
assert_contains "$(launch Quote)" "-lic 'echo it'\\''s'" "single quote in the command escaped"
echo ""

section "Test 3: Validation"
set +e; "$INSTALL" 'a/b' top >/dev/null 2>&1; rc=$?; set -e
assert_eq "$rc" "1" "name with a slash refused"
set +e; "$INSTALL" Bad "" >/dev/null 2>&1; rc=$?; set -e
assert_eq "$rc" "1" "empty command refused"
set +e; "$INSTALL" Bad top --workspace 'x y' >/dev/null 2>&1; rc=$?; set -e
assert_eq "$rc" "1" "bad workspace refused"
set +e; "$INSTALL" OnlyName >/dev/null 2>&1; rc=$?; set -e
assert_eq "$rc" "1" "missing command exits 1"
assert_dir_not_exists "$APPS/Bad.app" "nothing installed on a refused call"
echo ""

section "Test 4: Remove"
out=$("$REMOVE" --list)
assert_contains "$out" "lazygit" "--list shows lazygit"
assert_contains "$out" "btop --utf-force" "--list shows the command"
"$REMOVE" lazygit >/dev/null
assert_dir_not_exists "$APPS/lazygit.app" "bundle removed"
assert_file_not_contains "$TOML" "dotfiles-tui: lazygit" "rule removed"
assert_count "$TOML" "# dotfiles-tui: System Monitor (begin)" 1 "other rule intact"
set +e; out=$("$REMOVE" Nope 2>&1); rc=$?; set -e
assert_eq "$rc" "1" "unknown name exits 1"
for n in "System Monitor" Disk Tiled NoIcon Bare Quote; do "$REMOVE" "$n" >/dev/null; done
assert_snapshots_equal "$TOML" "$ORIGINAL" "aerospace.toml back to its original after removing everything"
echo ""

section "Test 5: Runs under /bin/bash 3.2"
set +e; /bin/bash "$INSTALL" Legacy top --no-icon >/dev/null 2>&1; rc=$?; set -e
assert_eq "$rc" "0" "install under /bin/bash"
set +e; /bin/bash "$REMOVE" Legacy >/dev/null 2>&1; rc=$?; set -e
assert_eq "$rc" "0" "remove under /bin/bash"
echo ""
