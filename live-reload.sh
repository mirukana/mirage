#!/usr/bin/env sh

# Dependencies: findutils, entr
#
# This script will watch for source file changes and recompile-restart Mirage
# when needed. If it gets stuck restarting in loop, press CTRL-C a bunch of
# times and try again.
#
# pdb won't be usable due to entr, use https://pypi.org/project/remote-pdb/
# instead (should be present if you install requirements-dev.txt).
#
# An argument can be given to specify which QML file in src/gui to load,
# for example "Test.qml" would load "src/gui/Test.qml".
# If no argument is given, the default is "UI.qml".

make clean
qmake mirage.pro CONFIG+=dev && make

while true; do
    # app already handles reloading config and theme files
    find src mirage.pro \
        -type f -not -path 'src/themes/*' -not -path 'src/config/*' |

    # -name affects the first part of the WM_CLASS returned by xprop on Linux
    entr -cdnr sh -c \
        "qmake mirage.pro CONFIG+=dev && make && ./mirage -name dev $*"

    sleep 0.2
done
