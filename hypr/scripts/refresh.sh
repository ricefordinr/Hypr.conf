file_exists() {
    if [ -e "$1" ]; then
        return 0
    else
        return 1
    fi
}

processes=(waybar rofi swaync)
for process in "${processes[@]}"; do
    if pidof "${process}" > /dev/null; then
        pkill "${process}"
    fi
done

swaync > /dev/null 2>&1 &
waybar &
pkill swaybg
swaybg --image $HOME/.config/hypr/assets/background/wallpaper.png

exit 0
