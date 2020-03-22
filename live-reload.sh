#!/usr/bin/env sh

# pdb won't be usable with entr,
# use https://pypi.org/project/remote-pdb/ instead.

# An argument can be given to specify which QML file in src/gui to load.
# If no argument is given, the default is "UI.qml".

export QT_QPA_PLATFORM=xcb

make clean
qmake mirage.pro CONFIG+=dev && make

while true; do
    find src mirage.pro -type f |
    # -name affects the first part of the WM_CLASS returned by xprop on Linux
    entr -cdnr sh -c \
        "qmake mirage.pro CONFIG+=dev && make && ./mirage -name dev $*"
    sleep 0.2
done
