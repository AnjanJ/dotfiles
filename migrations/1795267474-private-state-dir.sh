#!/usr/bin/env bash
# Migration: make ~/.local/state/dotfiles private
#
# The state dir holds update transcripts, debug logs, the recorded Claude
# model and the last rendered Claude settings: paths, package lists and
# host names. It was created 755 with files 644, readable by every account
# on the Mac. A 700 directory closes all of it at once, whatever mode each
# file inside was written with; update.sh re-applies it every run.
set -euo pipefail

dir="${DOTFILES_STATE_DIR:-$HOME/.local/state/dotfiles}"
if [[ -d "$dir" ]]; then
    chmod 700 "$dir"
    echo "    $dir is now private (700)"
fi
