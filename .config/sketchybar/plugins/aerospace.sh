#!/bin/bash

# Get focused workspace from environment variable
FOCUSED_WORKSPACE=$FOCUSED_WORKSPACE

# If not set, query aerospace directly
if [ -z "$FOCUSED_WORKSPACE" ]; then
    FOCUSED_WORKSPACE=$(aerospace list-workspaces --focused)
fi

# Get list of all workspaces with windows
WORKSPACES=$(aerospace list-workspaces --all)

# Build the label showing all workspaces with the focused one highlighted
LABEL=""
for ws in 1 2 3 4 5 6 7 8 9; do
    # Check if workspace has windows
    if echo "$WORKSPACES" | grep -q "^$ws$"; then
        # Workspace has windows
        if [ "$ws" = "$FOCUSED_WORKSPACE" ]; then
            # Focused workspace with windows - highlighted
            LABEL="$LABEL <b>[$ws]</b>"
        else
            # Non-focused workspace with windows
            LABEL="$LABEL $ws"
        fi
    fi
done

# Update sketchybar
sketchybar --set $NAME label="$LABEL"
