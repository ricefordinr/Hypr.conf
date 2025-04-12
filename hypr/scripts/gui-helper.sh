#!/bin/bash

deps=(
    fuzzel
)

scriptDir=$HOME/.config/hypr/scripts

actions=(
    "Set accent"
    "Color picker"
    "Clipboard"
)

set-accent() {
    local newAccent="$(bash $scriptDir/colors.sh -n | fuzzel -d)"
    [[ "$newAccent" == "" ]] && exit
    bash $scriptDir/colors.sh -s $newAccent
    bash $scriptDir/refresh.sh > /dev/null
}

color-picker() {
    pkill fuzzel
    sleep 0.2
    local color="$(hyprpicker)"
    [[ "$color" == "" ]] && exit
    local toCopy="$(echo $color "(Hit Enter to copy)" | fuzzel -d -s"$(echo $color)FF" -l1)"
    [[ "$toCopy" != "" ]] && wl-copy "$color"
}

clipboard() {
    wl-paste | fuzzel -d
}

fuzzelConfDir="$HOME/.config/fuzzel/gui-helper.ini"
action=$(printf '%s\n' "${actions[@]}" | fuzzel -d --config="$fuzzelConfDir")
echo $action

case "$action" in 
    "Set accent")
        set-accent
        ;;
    "Color picker")
        color-picker
        ;;
    "Clipboard")
        clipboard
        ;;
    *)
        echo "Other utils is in construction"
        ;;
esac
