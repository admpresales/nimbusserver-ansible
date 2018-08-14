#!/usr/bin/env bash

for i in ~/Desktop/*.desktop; do
    echo $i
    gio set $i "metadata::trusted" yes
done