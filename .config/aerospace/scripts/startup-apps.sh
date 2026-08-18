#!/usr/bin/env bash
#
# startup-apps.sh — restore the standard workspace session.
#
# Launches every app in the daily layout. Placement is NOT done here:
# the [[on-window-detected]] rules in aerospace.toml route each window to
# its home workspace the moment it appears, so launch order is irrelevant.
#
# Run automatically from `after-startup-command` in aerospace.toml, or by
# hand any time with:  restore-session
#
# Apps already running are left alone (`open -a` focuses rather than
# duplicating), so re-running this is safe.

set -uo pipefail

# Seconds to wait between launches. Cold boot needs breathing room —
# ten apps starting at once makes AeroSpace miss window-detected events.
STAGGER="${AEROSPACE_STARTUP_STAGGER:-1.5}"

# Give AeroSpace time to finish coming up before the first window lands.
sleep "${AEROSPACE_STARTUP_DELAY:-2}"

# Workspace assignments live in aerospace.toml. Listed here in workspace
# order purely so the screen fills in a predictable sequence.
APPS=(
  "Warp"          # ws 1 — terminal
  "Zen"           # ws 2 — personal browser
  "Google Chrome" # ws 3 — work browser
  "Zed"           # ws 4 — editor
  "Proton Mail"   # ws 5 — mail
  "Obsidian"      # ws 6 — notes
  "Slack"         # ws 6 — chat (floating)
  "1Password"     # no home ws — floats where opened, so its Touch ID
                  # prompt follows you (see aerospace.toml)
  "Ente Auth"     # ws 6 — 2FA (floating)
  "Claude"        # ws 7 — AI (floating)
  "ChatGPT"       # ws 7 — AI (floating)
)

for app in "${APPS[@]}"; do
  if open -a "$app" 2>/dev/null; then
    echo "launched: $app"
  else
    echo "skipped (not found): $app" >&2
  fi
  sleep "$STAGGER"
done

# Land on the terminal, the way a fresh session should start.
aerospace workspace 1 2>/dev/null || true

echo "session restored"
