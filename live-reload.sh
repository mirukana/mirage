#!/usr/bin/env sh

# pdb won't be usable with entr,
# use https://pypi.org/project/remote-pdb/ instead

# no_embedded (resources) is used to speed up the compilation

export DISPLAY=${1:-:0}
export QT_QPA_PLATFORM=xcb

CFG='dev no_embedded'

qmake harmonyqml.pro CONFIG+="$CFG" && make

while true; do
    find src harmonyqml.pro -type f |
    entr -cdnr sh -c \
        "qmake harmonyqml.pro CONFIG+='$CFG' && make && ./harmonyqml"
    sleep 0.2
done
