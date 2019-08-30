# harmonyqml

## Dependencies setup

Outside of pip/github:

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

Make sure the right version of Qt is used:

    export QT_SELECT=5

Install [pyotherside](https://github.com/thp/pyotherside):

    git clone https://github.com/thp/pyotherside
    cd pyotherside
    qmake && make && sudo make install

After this, verify the permissions of the installed plugin files.

    sudo chmod 644 /usr/lib/qt5/qml/io/thp/pyotherside/*
    sudo chmod 755 /usr/lib/qt5/qml/io/thp/pyotherside/*.so

Install the dependencies from Pypi:

    pip3 install --user --upgrade \
        Pillow aiofiles appdirs dataclasses filetype hsluv html_sanitizer \
        lxml mistune uvloop

Install the dependencies from Github:

[matrix-nio](https://github.com/mirukan/matrix-nio):

    git clone https://github.com/mirukan/matrix-nio
    cd matrix-nio
    pip3 install --user --upgrade -e '.[e2e]'

## Building

    git clone <TODO>
    cd harmonyqml
    qmake harmonyqml.pro && make && sudo make install

After this if no errors happened, run `harmonyqml`.
