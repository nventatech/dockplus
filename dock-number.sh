#!/bin/sh
omarchy-shell dockplus activate "$1" 2>/dev/null || hyprctl dispatch "hl.dsp.focus({ workspace = \"$1\" })"
