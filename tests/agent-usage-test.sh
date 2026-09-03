#!/usr/bin/env bash

# ============================================
# AGENT USAGE TEST SUITE
# ============================================
# Tests bin/dotfiles-agent-usage against a fake curl and a credentials
# file (never the keychain or the real endpoint): sign-in detection,
# fetch, cache and --refresh, --json, --bar levels, stale and expired-
# token paths, --notify through a fake osascript, bash 3.2, and the
# sketchybar plugin painting through a fake sketchybar.
# Usage: tests/run agent-usage   (or /opt/homebrew/bin/bash tests/agent-usage-test.sh)
# ============================================

set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

REAL_DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
T="$REAL_DOTFILES_DIR/bin/dotfiles-agent-usage"
PLUGIN="$REAL_DOTFILES_DIR/.config/sketchybar/plugins/agent-usage.sh"

command -v jq >/dev/null 2>&1 || { echo "jq is required for this suite" >&2; exit 1; }

FAKEBIN="$HOME/fakebin"
mkdir -p "$FAKEBIN" "$HOME/bin"
export FAKE_CURL_LOG="$HOME/curl.log"
export FAKE_CURL_BODY="$HOME/body.json"
export FAKE_OSASCRIPT_LOG="$HOME/osascript.log"
export FAKE_SKETCHYBAR_LOG="$HOME/sketchybar.log"

cat > "$FAKEBIN/curl" <<'F'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$FAKE_CURL_LOG"
[[ -f "$FAKE_CURL_BODY.down" ]] && exit 7
cat "$FAKE_CURL_BODY"
F
cat > "$FAKEBIN/osascript" <<'F'
#!/usr/bin/env bash
printf '%s|%s\n' "$*" "${DOTFILES_AGENT_USAGE_MSG:-}" >> "$FAKE_OSASCRIPT_LOG"
F
cat > "$FAKEBIN/sketchybar" <<'F'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$FAKE_SKETCHYBAR_LOG"
F
chmod +x "$FAKEBIN"/*
export PATH="$FAKEBIN:$PATH"
export DOTFILES_CACHE_DIR="$HOME/cache"
export DOTFILES_AGENT_USAGE_CREDENTIALS="$HOME/creds.json"
export DOTFILES_AGENT_USAGE_URL="https://usage.example.test/oauth/usage"
export TZ=UTC
unset DOTFILES_AGENT_USAGE_NOW

REAL_NOW=$(date +%s)
FUTURE_MS=$(( (REAL_NOW + 3600) * 1000 ))
SESSION_RESET=1788430799   # 2026-09-03T10:19:59Z, a Thursday

write_creds() {
    cat > "$HOME/creds.json" <<J
{"claudeAiOauth":{"accessToken":"tok-abc","refreshToken":"r","expiresAt":$1,"subscriptionType":"max","rateLimitTier":"default_claude_max_5x"}}
J
}

# $1 session %, $2 weekly all-models %, $3 weekly Fable %
write_body() {
    cat > "$FAKE_CURL_BODY" <<J
{"five_hour":{"utilization":$1.0,"resets_at":"2026-09-03T10:19:59.573056+00:00"},
 "seven_day":{"utilization":$2.0,"resets_at":"2026-09-09T23:59:59.573075+00:00"},
 "limits":[
  {"kind":"session","group":"session","percent":$1,"severity":"warning","resets_at":"2026-09-03T10:19:59.573056+00:00","scope":null,"is_active":true},
  {"kind":"weekly_all","group":"weekly","percent":$2,"severity":"normal","resets_at":"2026-09-09T23:59:59.573075+00:00","scope":null,"is_active":false},
  {"kind":"weekly_scoped","group":"weekly","percent":$3,"severity":"normal","resets_at":"2026-09-09T23:59:59.573223+00:00","scope":{"model":{"id":null,"display_name":"Fable"},"surface":null},"is_active":false}]}
J
}

curl_calls() {
    if [[ -f "$FAKE_CURL_LOG" ]]; then wc -l < "$FAKE_CURL_LOG" | tr -d ' '; else echo 0; fi
}

echo ""
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║   Agent Usage Tests                                       ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""

section "Test 1: No login"
rm -f "$HOME/creds.json"
set +e; err=$("$T" 2>&1 >/dev/null); rc=$?; set -e
assert_eq "$rc" "2" "exits 2 without credentials"
assert_contains "$err" "No Claude Code login" "says there is no login"
set +e; out=$("$T" --bar 2>/dev/null); rc=$?; set -e
assert_eq "$rc" "2" "--bar exits 2 without credentials"
assert_eq "$out" "" "--bar prints nothing without credentials"
assert_eq "$(curl_calls)" "0" "the endpoint is not called without a token"
echo ""

section "Test 2: First fetch"
write_creds "$FUTURE_MS"
write_body 86 13 25
out=$("$T")
assert_contains "$out" "Plan: max, default_claude_max_5x" "plan from the credentials"
assert_contains "$out" "Session (5h)  86%  resets" "session line"
assert_contains "$out" "Week (7d)     13%  resets" "all-models weekly line"
assert_contains "$out" "Week, Fable   25%  resets" "per-model weekly line"
assert_contains "$out" "Fetched just now" "fresh fetch"
assert_eq "$(curl_calls)" "1" "one call to the endpoint"
call=$(cat "$FAKE_CURL_LOG")
assert_contains "$call" "$DOTFILES_AGENT_USAGE_URL" "the configured URL is called"
assert_contains "$call" "Authorization: Bearer tok-abc" "the token goes as a bearer header"
assert_contains "$call" "anthropic-beta: oauth-2025-04-20" "the OAuth beta header is sent"
assert_file_exists "$HOME/cache/agent-usage.json" "reply cached"
echo ""

section "Test 3: Cache, --refresh and --max-age"
"$T" >/dev/null
assert_eq "$(curl_calls)" "1" "a second run within 60s reads the cache"
"$T" --refresh >/dev/null
assert_eq "$(curl_calls)" "2" "--refresh fetches again"
DOTFILES_AGENT_USAGE_NOW=$((REAL_NOW + 120)) "$T" >/dev/null
assert_eq "$(curl_calls)" "3" "a cache older than 60s is refetched"
DOTFILES_AGENT_USAGE_NOW=$((REAL_NOW + 120)) "$T" --max-age 600 >/dev/null
assert_eq "$(curl_calls)" "3" "--max-age accepts an older cache"
echo ""

section "Test 4: --json"
json=$("$T" --json)
assert_eq "$(echo "$json" | jq -r .session.percent)" "86" "session percent"
assert_eq "$(echo "$json" | jq -r .session.resets_at)" "$SESSION_RESET" "session reset as epoch seconds"
assert_eq "$(echo "$json" | jq -r .week.percent)" "25" "week is the fullest weekly limit"
assert_eq "$(echo "$json" | jq -r .week.scope)" "Fable" "and names its scope"
assert_eq "$(echo "$json" | jq -r '.weekly | length')" "2" "every weekly limit listed"
assert_eq "$(echo "$json" | jq -r .stale)" "false" "not stale"
assert_eq "$(echo "$json" | jq -r .level)" "warning" "86% is warning"
echo ""

section "Test 5: --bar levels"
assert_eq "$("$T" --bar)" "$(printf '5h 86%% · 7d 25%%\twarning')" "label<TAB>level"
write_body 91 13 25
assert_eq "$("$T" --bar --refresh)" "$(printf '5h 91%% · 7d 25%%\tcritical')" "90% and over is critical"
write_body 50 10 20
assert_eq "$("$T" --bar --refresh)" "$(printf '5h 50%% · 7d 20%%\tnormal')" "under 70% is normal"
write_body 10 72 20
assert_eq "$("$T" --bar --refresh)" "$(printf '5h 10%% · 7d 72%%\twarning')" "the weekly figure sets the level too"
assert_eq "$(/bin/bash "$T" --bar)" "$(printf '5h 10%% · 7d 72%%\twarning')" "same under /bin/bash 3.2"
echo ""

section "Test 6: Endpoint down"
write_body 86 13 25
"$T" --refresh >/dev/null
touch "$FAKE_CURL_BODY.down"
set +e; json=$("$T" --json --refresh); rc=$?; set -e
assert_eq "$rc" "0" "a failed refresh with a cache still succeeds"
assert_eq "$(echo "$json" | jq -r .stale)" "true" "marked stale"
assert_eq "$(echo "$json" | jq -r .level)" "stale" "level is stale"
assert_eq "$(echo "$json" | jq -r .session.percent)" "86" "cached figures shown"
assert_contains "$("$T" --refresh)" "stale: the last refresh failed" "human output says so"
rm -rf "$HOME/cache"
set +e; err=$("$T" 2>&1 >/dev/null); rc=$?; set -e
assert_eq "$rc" "3" "exits 3 with no cache and no endpoint"
assert_contains "$err" "nothing is cached" "explains why"
set +e; out=$("$T" --bar 2>/dev/null); rc=$?; set -e
assert_eq "$rc" "3" "--bar exits 3 too"
assert_eq "$out" "" "--bar prints nothing"
rm -f "$FAKE_CURL_BODY.down"
echo ""

section "Test 7: Expired token"
"$T" >/dev/null
calls_before=$(curl_calls)
write_creds 1000
json=$(DOTFILES_AGENT_USAGE_NOW=$((REAL_NOW + 120)) "$T" --json)
assert_eq "$(curl_calls)" "$calls_before" "an expired token is never sent"
assert_eq "$(echo "$json" | jq -r .stale)" "true" "cache shown as stale instead"
rm -rf "$HOME/cache"
set +e; err=$("$T" 2>&1 >/dev/null); rc=$?; set -e
assert_eq "$rc" "2" "expired and nothing cached exits 2"
assert_contains "$err" "token has expired" "names the cause"
write_creds "$FUTURE_MS"
echo ""

section "Test 8: Reset times"
out=$(DOTFILES_AGENT_USAGE_NOW=$((SESSION_RESET - 4320)) "$T")
assert_contains "$out" "resets 10:19 (in 1h 12m)" "session reset clock and countdown"
assert_contains "$out" "resets Wed 23:59 (in 6d 14h)" "weekly reset with the weekday"
echo ""

section "Test 9: --notify"
"$T" --notify
assert_file_exists "$FAKE_OSASCRIPT_LOG" "osascript called"
line=$(tail -1 "$FAKE_OSASCRIPT_LOG")
assert_contains "$line" 'with title "Claude usage"' "notification title"
assert_contains "$line" "Session (5h) 86% resets" "message carries the session figure"
assert_contains "$line" "Week, Fable 25%" "and the weekly ones"
assert_not_contains "$line" "tell app" "no application is targeted"
echo ""

section "Test 10: Sketchybar plugin"
ln -sf "$T" "$HOME/bin/dotfiles-agent-usage"
NAME=agent_usage "$PLUGIN"
line=$(tail -1 "$FAKE_SKETCHYBAR_LOG")
assert_contains "$line" "--set agent_usage drawing=on" "item drawn"
assert_contains "$line" "label=5h 86% · 7d 25%" "label painted"
assert_contains "$line" "label.color=0xffffca85" "warning uses the yellow fallback"
write_body 95 13 25
NAME=agent_usage "$PLUGIN"
"$T" --refresh >/dev/null
NAME=agent_usage "$PLUGIN"
assert_contains "$(tail -1 "$FAKE_SKETCHYBAR_LOG")" "label.color=0xffff6767" "critical uses red"
before=$(wc -l < "$FAKE_OSASCRIPT_LOG")
NAME=agent_usage "$PLUGIN" notify
assert_eq "$(wc -l < "$FAKE_OSASCRIPT_LOG" | tr -d ' ')" "$((before + 1))" "a click posts the notification"
rm -f "$HOME/creds.json"; rm -rf "$HOME/cache"
NAME=agent_usage "$PLUGIN"
assert_contains "$(tail -1 "$FAKE_SKETCHYBAR_LOG")" "--set agent_usage drawing=off" "no login hides the item"
echo ""

section "Test 11: Config and usage"
assert_succeeds "plugin parses under /bin/bash 3.2" /bin/bash -n "$PLUGIN"
assert_succeeds "sketchybarrc parses under /bin/bash 3.2" /bin/bash -n "$REAL_DOTFILES_DIR/.config/sketchybar/sketchybarrc"
assert_file_contains "$REAL_DOTFILES_DIR/.config/sketchybar/sketchybarrc" "dotfiles-toggle\" --enabled agent-usage" "sketchybarrc honours the agent-usage toggle"
assert_file_contains "$REAL_DOTFILES_DIR/.config/sketchybar/sketchybarrc" "plugins/agent-usage.sh notify" "clicking the item notifies"
assert_file_contains "$REAL_DOTFILES_DIR/bin/dotfiles-toggle" "agent-usage" "the toggle is documented"
set +e; out=$("$T" --help); rc=$?; set -e
assert_eq "$rc" "0" "--help exits 0"
assert_contains "$out" "--bar" "--help mentions --bar"
set +e; "$T" --bogus >/dev/null 2>&1; rc=$?; set -e
assert_eq "$rc" "1" "unknown option exits 1"
set +e; "$T" --max-age abc >/dev/null 2>&1; rc=$?; set -e
assert_eq "$rc" "1" "--max-age wants a number"
echo ""

