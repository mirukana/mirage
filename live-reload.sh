#!/usr/bin/env sh

# pdb won't be usable with entr,
# use https://pypi.org/project/remote-pdb/ instead.

# An argument can be given to specify which QML file in src/qml to load.
# If no argument is given, the default is "UI.qml".

export QT_QPA_PLATFORM=xcb

make clean
qmake harmonyqml.pro CONFIG+=dev && make

while true; do
    killall -9 harmonyqml

    find src harmonyqml.pro -type f |
    entr -cdnr sh -c \
        "qmake harmonyqml.pro CONFIG+=dev && make && ./harmonyqml $*"
    sleep 0.2
done
