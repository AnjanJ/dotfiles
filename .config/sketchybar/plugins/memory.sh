#!/bin/bash

# Memory plugin for SketchyBar.
#
# Reports memory PRESSURE, not "used". On Apple Silicon the OS deliberately
# keeps RAM full of cache, so "used GB" sits near the limit permanently and
# tells you nothing. `memory_pressure` reports the figure the kernel itself
# acts on, which is what actually predicts a stall.
#
# Swap is shown only when non-zero: on 36GB unified memory, running Postgres,
# MySQL, Redis and a local Ollama model together is exactly the situation
# where swap starts and everything gets slow. Seeing it appear is the cue to
# unload a model before the machine begins thrashing.

# Colours are defined here rather than inherited from sketchybarrc: sketchybar
# spawns plugins from the bar daemon's own environment, so `export` in the rc
# does NOT reach them. Keep these in sync with the THEME_COLORS block in
# sketchybarrc (the theme switcher rewrites that block, not this one).
RED=0xffff6767
YELLOW=0xffffca85
WHITE=0xffedecee

FREE_PCT=$(memory_pressure 2>/dev/null | awk '/System-wide memory free percentage/ {gsub(/%/,"",$NF); print $NF}')

# Fall back silently rather than showing a wrong number.
[ -z "$FREE_PCT" ] && exit 0

USED_PCT=$((100 - FREE_PCT))

# Swap in MB, rounded. Format is "used = 1234.50M" or "...G".
SWAP=$(sysctl -n vm.swapusage | awk '{
    for (i = 1; i <= NF; i++) {
        if ($i == "used") {
            v = $(i + 2)
            unit = substr(v, length(v))
            gsub(/[MG]/, "", v)
            if (unit == "G") v = v * 1024
            printf "%.0f", v
            exit
        }
    }
}')
[ -z "$SWAP" ] && SWAP=0

if [ "$USED_PCT" -ge 85 ] || [ "$SWAP" -gt 2048 ]; then
    COLOR=$RED
elif [ "$USED_PCT" -ge 70 ] || [ "$SWAP" -gt 0 ]; then
    COLOR=$YELLOW
else
    COLOR=$WHITE
fi

# Only surface swap once it exists -- an always-visible "0M" is noise.
if [ "$SWAP" -gt 0 ]; then
    LABEL="${USED_PCT}% ⇄${SWAP}M"
else
    LABEL="${USED_PCT}%"
fi

sketchybar --set "$NAME" label="$LABEL" label.color="$COLOR" icon.color="$COLOR"
