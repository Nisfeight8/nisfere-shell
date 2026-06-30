#!/bin/bash

STATE_FILE="$HOME/.cache/nisfere/theme_state"

SET_THEME_SCRIPT="$HOME/.config/nisfere/set-theme.sh"

# If there is no state, we set a default dynamic dark
if [[ ! -f "$STATE_FILE" ]]; then
    echo "No state found. Starting with default settings..."
    # Put the path of your default wallpaper here
    "$SET_THEME_SCRIPT" dynamic "$HOME/Pictures/Wallpapers/default.jpg" dark
    exit 0
fi

# Load the variables (TYPE, SOURCE, MODE) from the file
source "$STATE_FILE"

# Invert the Mode
if [[ "$MODE" == "dark" ]]; then
    NEW_MODE="light"
else
    NEW_MODE="dark"
fi
echo "Switching to $NEW_MODE mode..."

# Call the main script again with the new mode
"$SET_THEME_SCRIPT" "$TYPE" "$SOURCE" "$NEW_MODE"