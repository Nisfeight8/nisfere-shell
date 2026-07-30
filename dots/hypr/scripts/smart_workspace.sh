#!/bin/bash

KEY=$1
ACTION=$2
PER_MON=${3:-10}

MONITOR_ID=$(hyprctl activeworkspace -j | jq '.monitorID')

if [ -z "$MONITOR_ID" ] || [ "$MONITOR_ID" = "null" ]; then
    MONITOR_ID=0
fi

TARGET=$(( (MONITOR_ID * PER_MON) + KEY ))

if [ "$ACTION" = "movetoworkspace" ]; then
    hyprctl dispatch "hl.dsp.window.move({ workspace = '${TARGET}' })"
else
    hyprctl dispatch "hl.dsp.focus({ workspace = '${TARGET}' })"
fi