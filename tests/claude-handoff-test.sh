#!/usr/bin/env bash
# ============================================
# CLAUDE HANDOFF SUITE — the 45% handoff offer
# ============================================
# Hooks cannot see context usage, only the status line can. So the
# status line records the percentage per session and a Stop hook turns
# it into one offer to write a handoff prompt.
# ============================================
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

require_command jq

STATUSLINE="$ROOT/.config/claude/statusline-command.sh"
HOOK="$ROOT/.config/claude/handoff-check.sh"
STATE="$TMPDIR/claude-handoff"

status() { # session pct
    jq -n --arg s "$1" --argjson p "$2" --arg d "$TEST_TMP" \
        '{session_id:$s,cwd:$d,workspace:{current_dir:$d},model:{display_name:"m"},context_window:{used_percentage:$p}}' \
        | bash "$STATUSLINE"
}
stop() { # session
    jq -n --arg s "$1" '{session_id:$s,hook_event_name:"Stop"}' | bash "$HOOK"
}

section "status line records usage"

out=$(status abc-1 12)
assert_contains "$out" "12% ctx" "status line still prints the percentage"
assert_eq "$(cat "$STATE/abc-1.pct")" "12" "status line records the percentage per session"

jq -n '{session_id:"no-pct",cwd:"/",workspace:{current_dir:"/"},context_window:{used_percentage:null}}' | bash "$STATUSLINE" >/dev/null
assert_file_not_exists "$STATE/no-pct.pct" "nothing is recorded before the first response"

status '../../evil' 50 >/dev/null
assert_file_not_exists "$TEST_TMP/evil.pct" "a session id cannot escape the state directory"

section "offer"

assert_eq "$(stop never-seen)" "" "no recorded usage stays silent"

status s1 44 >/dev/null
assert_eq "$(stop s1)" "" "44% stays silent"

status s1 45 >/dev/null
out=$(stop s1)
assert_eq "$(jq -r '.hookSpecificOutput.hookEventName' <<<"$out")" "Stop" "45% answers as a Stop hook"
ctx=$(jq -r '.hookSpecificOutput.additionalContext' <<<"$out")
assert_contains "$ctx" "45%" "the offer states the usage"
assert_contains "$ctx" "yes or no" "the offer asks for approval first"
assert_contains "$ctx" "paste" "the offer describes a prompt to paste into a new session"
assert_eq "$(stop s1)" "" "the offer is made once"

status s1 80 >/dev/null
assert_eq "$(stop s1)" "" "higher usage does not repeat the offer"

status s1 20 >/dev/null
assert_eq "$(stop s1)" "" "falling below the threshold stays silent"
status s1 46 >/dev/null
assert_contains "$(stop s1)" "46%" "crossing the threshold again after compaction offers again"

printf 'junk' >"$STATE/s2.pct"
assert_eq "$(stop s2)" "" "an unreadable percentage stays silent"

section "wiring"

settings="$ROOT/.config/claude/settings.json"
assert_eq "$(jq -r '.env.CLAUDE_CODE_AUTO_COMPACT_WINDOW // "unset"' "$settings")" "unset" "auto-compact stays on its default"
assert_contains "$(jq -r '.hooks.Stop[].hooks[].command' "$settings")" "handoff-check.sh" "settings run the hook on Stop"
assert_file_contains "$ROOT/scripts/symlink-map.sh" ".config/claude/handoff-check.sh" "the hook is a managed symlink"
assert_file_contains "$ROOT/.github/workflows/test.yml" ".config/claude/handoff-check.sh" "CI lints the hook"
