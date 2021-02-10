#!/usr/bin/env bash

if [ ! -f ~/.config/nimbus-initial-done ]; then
    # Trust desktop icons
    for i in ~/Desktop/*.desktop; do
        echo $i
        gio set $i "metadata::trusted" true
    done

    #Launch chrome on initial startup to see NimbusServer details
    gtk-launch google-chrome.desktop

    touch ~/.config/nimbus-initial-done
fi
