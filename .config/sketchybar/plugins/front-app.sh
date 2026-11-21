#!/bin/bash

# Focused-app plugin for SketchyBar.
#
# Sketchybar's own front_app_switched event carries the app name in $INFO,
# so the label changes the moment focus does, with no polling. The bar's
# first paint (and `sketchybar --update`) has no event and no $INFO, so the
# name then comes from lsappinfo, which ships with macOS; osascript would
# need an Automation permission and can hang on its prompt.

APP="${INFO:-}"
if [ "${SENDER:-}" != "front_app_switched" ] || [ -z "$APP" ]; then
    # First line reads '"Ghostty" ASN:0x0-0x1234: (in front)'.
    APP=$(lsappinfo info -only name "$(lsappinfo front)" 2>/dev/null | head -1 | sed -n 's/^"\([^"]*\)".*/\1/p')
fi

if [ -z "$APP" ]; then
    sketchybar --set "$NAME" drawing=off
    exit 0
fi

sketchybar --set "$NAME" drawing=on label="$APP"
