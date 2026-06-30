#!/bin/bash

if [[ -z "$1" || -z "$2" ]]; then
    echo "Usage: $0 [dark/light]"
    exit 1
fi

TYPE="$1"
SOURCE="$2"
MODE="${3:-dark}" # If no 3rd argument is given, default is dark

STATE_DIR="$HOME/.cache/nisfere"

STATE_FILE="$STATE_DIR/theme_state"

echo "Apply theme: $TYPE | $SOURCE | $MODE"

# 1. Apply colors based on type
if [[ "$TYPE" == "dynamic" ]]; then
    if [[ "$MODE" == "light" ]]; then
        wallust run "$SOURCE" --palette light16
    else
        wallust run "$SOURCE"
    fi
    
    # Change the wallpaper ONLY if the theme is dynamic
    echo "Change Wallpaper..."
    awww img "$SOURCE"
    
    elif [[ "$TYPE" == "static" ]]; then
    # Assume that the files in the themes folder are named e.g. "tokyo-night-dark"
    wallust theme "${SOURCE}-${MODE}"
else
    echo "Unknown theme type. Try 'dynamic' or 'static'."
    exit 1
fi

# 2. Saving the State
mkdir -p "$STATE_DIR"
echo "TYPE=\"$TYPE\"" > "$STATE_FILE"
echo "SOURCE=\"$SOURCE\"" >> "$STATE_FILE"
echo "MODE=\"$MODE\"" >> "$STATE_FILE"

echo "Refreshing System..."
# hyprctl reload
# killall quickshell
# quickshell &

echo "Nisfere State Updated!"

