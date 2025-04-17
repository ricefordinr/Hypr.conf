#!/usr/bin/env bash

#Only support for ZenBrowser from flatpak
#I don't think anyone else beside me use this

zenrun="flatpak run app.zen_browser.zen "
zenpath=~/.var/app/app.zen_browser.zen/.zen/profiles.ini
fuzzelpath=$HOME/.config/fuzzel/zen-browser.ini
profiles="$(cat $zenpath | grep Name= | cut -d'=' -f2)"
echo $profiles
nol="$(echo $profiles | tr ' ' '\n' | grep -c '')"
profile="$(echo $profiles | tr ' ' '\n' | fuzzel -d --config=$fuzzelpath -l$nol)"

[[ "$profile" == "" ]] && exit

echo $profile
$zenrun -P $profile
