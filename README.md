# harmonyqml

## Dependencies setup

Outside of pip/github:

Qt 5.12+, including:
- qt5-declarative
- qt5-quickcontrols2
- qt5-graphicaleffects
- qt5-qmake

[pyotherside](https://github.com/thp/pyotherside):

    git clone https://github.com/thp/pyotherside
    cd pyotherside
    qmake
    make
    sudo make install

After this, verify the permissions of the installed plugin files.

    sudo chmod 644 /usr/lib/qt5/qml/io/thp/pyotherside/*
    sudo chmod 755 /usr/lib/qt5/qml/io/thp/pyotherside/*.so

Dependencies on Pypi:

    pip3 install --user --upgrade \
        Pillow atomicfile dataclasses filetype lxml mistune uvloop

Dependencies on Github (most recent version needed):

[matrix-nio](https://github.com/mirukan/matrix-nio):

    git clone https://github.com/mirukan/matrix-nio
    cd matrix-nio
    pip3 install --user --upgrade -e .

## Building

    git clone <TODO>
    cd harmonyqml
    qmake && make && sudo make install

After this if no errors happened, run `harmonyqml`.
