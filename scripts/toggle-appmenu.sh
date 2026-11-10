#!/bin/bash

if pgrep -f 'rofi -show drun -click-to-exit' >/dev/null; then
    pkill -f 'rofi -show drun -click-to-exit'
else
    rofi -show drun -click-to-exit
fi
