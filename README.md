# harmonyqml


## Dependencies setup

From your distribution's package manager, install:

Qt 5.12+, including:
- qt5-declarative-devel
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

Install the Python 3 dependencies:

    pip3 install --user -Ur requirements.txt

Optional dependency for performance improvements:

    pip3 install --user -U uvloop==0.13.0


## Building

    git clone --recursive <TODO>
    cd harmonyqml
    qmake harmonyqml.pro && make && sudo make install

After this if no errors happened, run `harmonyqml`.

If you get a version mismatch error related to cffi, try:

    pip3 install --user --upgrade --force-reinstall cffi
