#!/bin/bash

# FOCUSED_WORKSPACE is exported by the trigger in aerospace.toml.
# If it is absent -- e.g. the item's own periodic refresh rather than a
# workspace-change event -- fall back to asking aerospace directly.
if [ -z "$FOCUSED_WORKSPACE" ]; then
    FOCUSED_WORKSPACE=$(aerospace list-workspaces --focused)
fi

# Workspaces that actually contain windows. `--all` returns all nine
# regardless of contents, which defeats the emptiness check below and
# permanently shows the unassigned scratch workspaces.
WORKSPACES=$(aerospace list-workspaces --monitor all --empty no)

# The focused workspace must always be shown, even when empty -- otherwise
# switching to an empty scratch workspace makes the indicator vanish.
# -V (version sort) not -u alone: a plain lexical sort orders these as
# 1, 10, 11, 2 once workspaces above 9 exist.
WORKSPACES=$(printf '%s\n%s\n' "$WORKSPACES" "$FOCUSED_WORKSPACE" | sort -V -u)

# Build the label from the workspace list itself rather than a hardcoded
# 1..9 range -- overflow workspaces (10, 11, ...) exist and a fixed range
# silently drops them, leaving no highlight at all while focused there.
LABEL=""
while IFS= read -r ws; do
    [ -z "$ws" ] && continue
    if [ "$ws" = "$FOCUSED_WORKSPACE" ]; then
        # Sketchybar labels are PLAIN TEXT -- markup like <b> renders
        # literally as "<b>[1]</b>", so the brackets do the emphasising.
        LABEL="$LABEL [$ws]"
    else
        LABEL="$LABEL $ws"
    fi
done <<< "$WORKSPACES"

# Update sketchybar
sketchybar --set "$NAME" label="$LABEL"
