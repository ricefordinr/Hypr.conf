#!/usr/bin/env bash

fuzzelConfDir="$HOME/.config/fuzzel/power-options.ini"

#There is no sleep/suspend cause it sucks
actions=(
    " "
    " 󰐥"
    " "
    " 󰍃"
)

chosen=$(printf '%s\n' "${actions[@]}" | fuzzel -d --config="$fuzzelConfDir")

case "$chosen" in
    0)
        pidof hyprlock || hyprlock -q
        ;;
    1)
        systemctl poweroff
        ;;
    2)
        systemctl reboot
        ;;
    3)
        systemctl kill-session $XDG_SESSION_ID
        ;;
esac
