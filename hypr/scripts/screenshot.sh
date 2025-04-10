scriptDir="$HOME/.config/hypr/scripts"

timeNow=$(date "+%d-%b_%H-%M-%S")
dir="$HOME/Pictures/Screenshots"
file="Screenshot_${timeNow}.png"
notifyCmd="notify-send -t 10000 -A action1=Copy -A action2=Open -A action3=Delete -h string:x-canonical-private-synchronous:shot-notify"

notify() {
    local checkFile="${dir}/${file}"
    if [[ -e "$checkFile" ]]; then
        resp=$(timeout 5 ${notifyCmd} " Screenshot" " taken")
        case "$resp" in
            action1)
                wl-copy < "${checkFile}"
                ;;
            action2)
                xdg-open "${checkFile}" &
                ;;
            action3)
                rm "${checkFile}" &
                ;;
        esac
    else
        ${notifyCmd} " Screenshot" " Error"
    fi
}

areaShot() {
    tempfile=$(mktemp)
    grim -g "$(slurp)" - >"$tempfile"
    if [[ -s "$tempfile" ]]; then
        mv "$tempfile" "$dir/$file"
    fi
    notify
}

# So far, i only use area screenshot. Therefore, I'm lazy to implement others
areaShot
exit 0
