#!/usr/bin/env bash

# Script to cycle through windows of a specific app across all workspaces
# Usage: cycle-app-windows.sh <app> <direction>
# Example: cycle-app-windows.sh chrome next

APP="$1"
DIRECTION="$2"

# Map app names to app IDs
case "$APP" in
    chrome)
        APP_ID="com.google.Chrome"
        ;;
    firefox)
        APP_ID="org.mozilla.firefox"
        ;;
    safari)
        APP_ID="com.apple.Safari"
        ;;
    *)
        echo "Unknown app: $APP"
        exit 1
        ;;
esac

# Get all windows of the app (window IDs)
ALL_WINDOWS=$(aerospace list-windows --all --format "%{window-id}" | while read -r window_id; do
    app_id=$(aerospace list-windows --all --format "%{app-bundle-id}" --window-id "$window_id" 2>/dev/null)
    if [[ "$app_id" == "$APP_ID" ]]; then
        echo "$window_id"
    fi
done)

# If no windows found, exit
if [[ -z "$ALL_WINDOWS" ]]; then
    exit 0
fi

# Convert to array
WINDOWS=($ALL_WINDOWS)
WINDOW_COUNT=${#WINDOWS[@]}

# If only one window, just focus it
if [[ $WINDOW_COUNT -eq 1 ]]; then
    aerospace focus --window-id "${WINDOWS[0]}"
    exit 0
fi

# Get currently focused window
FOCUSED=$(aerospace list-windows --focused --format "%{window-id}")

# Find index of focused window
CURRENT_INDEX=-1
for i in "${!WINDOWS[@]}"; do
    if [[ "${WINDOWS[$i]}" == "$FOCUSED" ]]; then
        CURRENT_INDEX=$i
        break
    fi
done

# Calculate next index
if [[ "$DIRECTION" == "next" ]]; then
    if [[ $CURRENT_INDEX -eq -1 ]]; then
        NEXT_INDEX=0
    else
        NEXT_INDEX=$(( (CURRENT_INDEX + 1) % WINDOW_COUNT ))
    fi
else
    if [[ $CURRENT_INDEX -eq -1 ]]; then
        NEXT_INDEX=$(( WINDOW_COUNT - 1 ))
    elif [[ $CURRENT_INDEX -eq 0 ]]; then
        NEXT_INDEX=$(( WINDOW_COUNT - 1 ))
    else
        NEXT_INDEX=$(( CURRENT_INDEX - 1 ))
    fi
fi

# Focus the next window
aerospace focus --window-id "${WINDOWS[$NEXT_INDEX]}"
