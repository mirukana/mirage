# harmonyqml

## Dependencies setup

From your distribution's package manager, install:

Qt 5.12+, including:
- qt5-declarative-devel
- qt5-quickcontrols
- qt5-quickcontrols2-devel
- qt5-svg-devel
- qt5-graphicaleffects
- qt5-qmake
- qt5-devel

- python3
- python3-devel
- olm-python3 >= 3.1

Make sure that the right version of Qt is selected and compiler flags are
correctly set:

    export QT_SELECT=5
    export CFLAGS="-march=native -O2 -pipe"
    export CXXFLAGS="$CFLAGS"
    export MAKEFLAGS="$(nproc)"

Install [pyotherside](https://github.com/thp/pyotherside):

    git clone https://github.com/thp/pyotherside
    cd pyotherside
    qmake && make && sudo make install

After this, verify the permissions of the installed plugin files.
To ensure that they're correctly set:

    sudo chmod -R 755 /usr/lib/qt5/qml/io
    sudo chmod 644 /usr/lib/qt5/qml/io/thp/pyotherside/*
    sudo chmod 755 /usr/lib/qt5/qml/io/thp/pyotherside/*.so

Install the Python 3 dependencies from Pypi:

    pip3 install --user --upgrade \
        Pillow aiofiles appdirs dataclasses filetype hsluv html_sanitizer \
        lxml mistune uvloop

Install the Python 3 dependencies from Github:

[matrix-nio](https://github.com/mirukan/matrix-nio):

    git clone https://github.com/mirukan/matrix-nio
    cd matrix-nio
    pip3 install --user --upgrade -e '.[e2e]'

## Building

    git clone <TODO>
    cd harmonyqml
    qmake harmonyqml.pro && make && sudo make install

After this if no errors happened, run `harmonyqml`.

If you get a version mismatch error related to cffi, try:

    pip3 install --user --upgrade --force-reinstall cffi
