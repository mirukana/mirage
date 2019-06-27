#!/usr/bin/env sh

while true; do
    clear
    qml src/qml/Window.qml -- --debug
    exit_code="$?"
    if [ "$exit_code" != 231 ]; then break; fi
done
