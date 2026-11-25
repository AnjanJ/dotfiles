#!/usr/bin/env bash
#
# Keep macOS authentication prompts on the workspace you are looking at.
#
# The system Touch ID / password prompt (coreautha, bundle id
# com.apple.LocalAuthentication.UIAgent) is an ordinary floating window to
# AeroSpace, so it belongs to whichever workspace was focused when it
# appeared. Switch away and AeroSpace parks it in the screen corner with the
# rest of that workspace: the prompt is still waiting, and nothing on screen
# says so. At login this happened every time: startup-apps.sh opens
# Ente Auth, whose lock asks for Touch ID at once, then switches to
# workspace 1 and leaves the prompt behind.
#
# AeroSpace has no sticky windows, so exec-on-workspace-change in
# aerospace.toml runs this on every switch, and it moves any open prompt to
# the workspace just switched to. Moving a window does not change focus, so
# this cannot re-trigger the callback.
#
# Usage: follow-auth-prompts.sh [workspace]   (default: $AEROSPACE_FOCUSED_WORKSPACE)
# Bash 3.2 compatible.

set -uo pipefail

# Bundle ids of the prompts to carry along, space separated.
PROMPT_APPS="com.apple.LocalAuthentication.UIAgent"

target="${1:-${AEROSPACE_FOCUSED_WORKSPACE:-}}"
[[ -n "$target" ]] || exit 0

windows=$(aerospace list-windows --all --format '%{window-id}|%{workspace}|%{app-bundle-id}' 2>/dev/null) || exit 0

while IFS='|' read -r id workspace bundle; do
    [[ -n "$id" ]] || continue
    case " $PROMPT_APPS " in
        *" $bundle "*) ;;
        *) continue ;;
    esac
    [[ "$workspace" == "$target" ]] && continue
    aerospace move-node-to-workspace --window-id "$id" "$target" || continue
    # A moved window can arrive tiled (seen when 1Password was moved by
    # hand), which would stretch the prompt across half the screen.
    aerospace layout --window-id "$id" floating || true
done <<< "$windows"
