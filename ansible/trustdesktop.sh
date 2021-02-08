#!/usr/bin/env bash

if [ ! -f ~/.config/nimbus-initial-done ]; then
    # Disable animations and enable the desktop icons extension
    gsettings set org.gnome.desktop.interface enable-animations false
    gsettings set org.gnome.shell disable-user-extensions false
    gsettings set org.gnome.shell enabled-extensions "['desktop-icons@gnome-shell-extensions.gcampax.github.com']"

    # Trust desktop icons
    for i in ~/Desktop/*.desktop; do
        echo $i
        gio set $i "metadata::trusted" true
    done

    #Launch chrome on initial startup to see NimbusServer details
    gtk-launch google-chrome.desktop

    touch ~/.config/nimbus-initial-done
fi
