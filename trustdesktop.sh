#!/usr/bin/env bash

if [ ! -f ~/.config/nimbus-initial-done ]; then

    for i in ~/Desktop/*.desktop; do
        echo $i
        gio set $i "metadata::trusted" yes
    done

    #Launch chrome on initial startup to see NimbusServer details
    /usr/bin/google-chrome-stable --password-store=basic %U --silent-debugger-extension-api

    touch ~/.config/nimbus-initial-done
fi