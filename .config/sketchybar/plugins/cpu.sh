#!/bin/bash

# CPU plugin for SketchyBar.
#
# Uses `ps` rather than `top -l 2` or `iostat -c 2`: both of those block for a
# full sampling interval (~0.7-1.0s), which is a long time to stall a bar that
# refreshes every few seconds. macOS reports %cpu as a decayed recent average,
# not a lifetime one, so summing it tracks load and settles back down when the
# load stops -- verified against synthetic load. Cost is ~0.02s.
#
# The sum counts one core as 100%, so divide by core count for a 0-100 figure.

# Colours are defined here rather than inherited from sketchybarrc: sketchybar
# spawns plugins from the bar daemon's own environment, so `export` in the rc
# does NOT reach them. Keep these in sync with the THEME_COLORS block in
# sketchybarrc (the theme switcher rewrites that block, not this one).
RED=0xffff6767
YELLOW=0xffffca85
WHITE=0xffedecee

CORES=$(sysctl -n hw.ncpu)
CPU=$(ps -A -o %cpu= | awk -v n="$CORES" '{s += $1} END {printf "%.0f", s / n}')

# Clamp: a burst can briefly push the decayed sum past the core count.
[ "$CPU" -gt 100 ] && CPU=100

# Colour is the whole point of the item -- a number you have to read defeats
# the purpose of glanceable. Thresholds are tuned for a machine that idles
# around 10-20% with services running.
if [ "$CPU" -ge 85 ]; then
    COLOR=$RED
elif [ "$CPU" -ge 60 ]; then
    COLOR=$YELLOW
else
    COLOR=$WHITE
fi

sketchybar --set "$NAME" label="${CPU}%" label.color="$COLOR" icon.color="$COLOR"
