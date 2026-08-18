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
WORKSPACES=$(printf '%s\n%s\n' "$WORKSPACES" "$FOCUSED_WORKSPACE" | sort -u)

# Build the label showing all workspaces with the focused one highlighted
LABEL=""
for ws in 1 2 3 4 5 6 7 8 9; do
    # Check if workspace has windows
    if echo "$WORKSPACES" | grep -q "^$ws$"; then
        # Workspace has windows
        if [ "$ws" = "$FOCUSED_WORKSPACE" ]; then
            # Focused workspace. Sketchybar labels are PLAIN TEXT -- markup
            # like <b> renders literally as "<b>[1]</b>", so the brackets do
            # the emphasising on their own.
            LABEL="$LABEL [$ws]"
        else
            # Non-focused workspace with windows
            LABEL="$LABEL $ws"
        fi
    fi
done

# Update sketchybar
sketchybar --set "$NAME" label="$LABEL"
