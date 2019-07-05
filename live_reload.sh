#!/usr/bin/env sh

# pdb won't be usable with entr,
# use https://pypi.org/project/remote-pdb/ instead

# no_embedded (resources) is used to speed up the compilation

find src harmonyqml.pro -type f |
entr -cdnr sh -c \
    'qmake CONFIG+="dev no_embedded" && make && ./harmonyqml --debug'
