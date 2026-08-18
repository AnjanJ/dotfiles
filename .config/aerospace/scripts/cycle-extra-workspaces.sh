#!/usr/bin/env bash
#
# Cycle through the "extra" workspaces -- the ones beyond the 1-9 that the
# number-row bindings can reach directly.
#
# AeroSpace's own `workspace next` walks EVERY persistent workspace and wraps
# 9 -> 1, so it cannot be scoped to just the overflow. This walks the list in
# EXTRA_WORKSPACES instead.
#
# Usage: cycle-extra-workspaces.sh [next|prev]

set -uo pipefail

# Workspaces reachable only through this script. Keep in sync with
# `persistent-workspaces` in aerospace.toml -- a workspace missing from
# there disappears whenever it is empty.
EXTRA_WORKSPACES=(10 11 12)

DIRECTION="${1:-next}"
CURRENT=$(aerospace list-workspaces --focused)

# Index of the current workspace within the extra list, or -1 if we are
# somewhere in 1-9.
idx=-1
for i in "${!EXTRA_WORKSPACES[@]}"; do
    if [[ "${EXTRA_WORKSPACES[$i]}" == "$CURRENT" ]]; then
        idx=$i
        break
    fi
done

count=${#EXTRA_WORKSPACES[@]}

if [[ $idx -eq -1 ]]; then
    # Coming from the numbered range: enter at the first extra workspace
    # going forward, or the last one going backward.
    [[ "$DIRECTION" == "prev" ]] && target=$((count - 1)) || target=0
elif [[ "$DIRECTION" == "prev" ]]; then
    target=$(( (idx - 1 + count) % count ))
else
    target=$(( (idx + 1) % count ))
fi

aerospace workspace "${EXTRA_WORKSPACES[$target]}"
