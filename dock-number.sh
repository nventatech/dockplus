#!/bin/sh
omarchy-shell dock activate "$1" 2>/dev/null || hyprctl dispatch "hl.dsp.focus({ workspace = \"$1\" })"
