# Installation

Instructions and releases are currently only available for Linux,
but compiling on Windows and macOS should be possible with the right tools.

- [Releases](#releases)
  - [Linux](#linux)
- [Manual installation](#manual-installation)
  - [Environment variables](#environment-variables)
  - [Package manager dependencies](#package-manager-dependencies)
    - [Alpine Linux 3.9+ / apk](#alpine-linux-39--apk)
    - [Arch Linux / pacman & AUR](#arch-linux--pacman--aur)
    - [Fedora 30+ / dnf](#fedora-30--dnf)
    - [Ubuntu 19.04 / apt](#ubuntu-1904--apt)
    - [Ubuntu 19.10+, Debian bullseye / apt](#ubuntu-1910-debian-bullseye--apt)
    - [Void Linux / xbps](#void-linux--xbps)
  - [Installing PyOtherSide manually](#installing-pyotherside-manually)
  - [Installing libolm manually](#installing-libolm-manually)
  - [Installing Mirage](#installing-mirage)
- [Common issues](#common-issues)
  - [cffi version mismatch](#cffi-version-mismatch)
  - [Component is not ready](#component-is-not-ready)


## Releases

### Linux

For **x86 64bit glibc-based systems**, Mirage is available as an **AppImage**
on the [release page](releases).  
For other architectures and musl-based distros, see the 
[manual installation section](#manual-installation).

AppImages are single executable files that contain the app and all 
its dependencies.  
Mirage images are built in Ubuntu 16.04, and should therefore run on any distro
released in 2016 or later.

To run from a terminal:

```sh
chmod +x Mirage-x86_64.AppImage
./Mirage-x86_64.AppImage
```

To run from a file manager, give executable permission in the file's
properties and double-click to launch.  
[More detailed instructions](https://docs.appimage.org/introduction/quickstart.html#ref-quickstart)


## Manual Installation

Qt 5.12+, Python 3.6+ (with development headers and pip),
PyOtherSide 1.5+ and libolm 3+ are required.

### Environment Variables

To ensure Qt **5** will be used by default, compile using all CPU cores and 
optimize the build for your machine:

```sh
export QT_SELECT=5
export MAKEFLAGS="-j$(nproc)"
export CFLAGS="-march=native -O2 -pipe"
```

### Package Manager Dependencies

#### Alpine Linux 3.9+ / apk

[PyOtherSide](#installing-pyotherside-manually) and 
[libolm](#installing-libolm-manually) must be manually installed.

```sh
sudo apk add qt5-qtquickcontrols2-dev qt5-qtsvg-dev qt5-qtimageformats \
             python3-dev py3-setuptools \
             build-base git cmake \
             libjpeg-turbo-dev zlib-dev tiff-dev libwebp-dev openjpeg-dev \
             libmediainfo-dev
export PATH="/usr/lib/qt5/bin:$PATH"
```

#### Arch Linux / pacman & AUR

**libolm** is from the AUR, this example uses
[yay](https://github.com/Jguer/yay) to install it like other packages.  
Alternatively, you can just use `pacman` and
[install libolm manually](#installing-libolm-manually).

```sh
yay -Syu qt5-base qt5-declarative qt5-quickcontrols2 qt5-svg \
         qt5-graphicaleffects qt5-imageformats \
         python python-pip \
         python-pyotherside \
         libolm \
         base-devel git cmake \
         libjpeg-turbo zlib libtiff libwebp openjpeg2 libmediainfo
```

#### Fedora 30+ / dnf

[PyOtherSide](#installing-pyotherside-manually) and 
[libolm](#installing-libolm-manually) must be manually installed.

```sh
sudo dnf groupinstall 'Development Tools'
sudo dnf install qt5-devel qt5-qtbase qt5-qtdeclarative qt5-qtquickcontrols2 \
                 qt5-qtsvg qt5-qtgraphicaleffects qt5-qtimageformats \
                 python3-devel python3-pip \
                 git cmake \
                 libjpeg-turbo-devel zlib-devel libtiff-devel libwebp-devel	\
                 openjpeg2-devel libmediainfo-devel
sudo ln -s /usr/bin/qmake-qt5 /usr/bin/qmake
```

#### Ubuntu 19.04 / apt

[libolm](#installing-libolm-manually) must be manually installed.


```sh
sudo apt update
sudo apt install qt5-default qt5-qmake qt5-image-formats-plugins \
                 qml-module-qtquick2 qml-module-qtquick-window2 \
                 qml-module-qtquick-layouts qml-module-qtquick-dialogs \
                 qml-module-qt-labs-platform \
                 qtdeclarative5-dev \
                 qtquickcontrols2-5-dev \
                 python3-dev python3-pip \
                 qml-module:io-thp-pyotherside \
                 build-essential git cmake \
                 libjpeg-turbo8-dev zlib1g-dev libtiff5-dev libwebp-dev \
                 libopenjp2-7-dev libmediainfo-dev
```

#### Ubuntu 19.10+, Debian bullseye / apt

Follow the steps for [Ubuntu 19.04](#ubuntu-1904--apt), but instead of
installing libolm manually:

```sh
sudo apt install libolm-dev
```

#### Void Linux / xbps

[PyOtherSide](#installing-pyotherside-manually) must be manually installed.

```sh
sudo xbps-install -Su qt5-devel qt5-declarative-devel \
                      qt5-quickcontrols2-devel \
                      qt5-svg-devel qt5-graphicaleffects qt5-imageformats \
                      python3-devel python3-pip \
                      olm-devel \
                      base-devel git cmake \
                      libjpeg-turbo-devel zlib-devel tiff-devel libwebp-devel \
                      libopenjpeg2-devel libmediainfo-devel
```

### Installing PyOtherSide Manually

Skip this section if you already installed it from your
distro's package manager.

```sh
git clone https://github.com/thp/pyotherside
cd pyotherside
make clean
qmake
make
sudo make install
```

### Installing libolm Manually

Skip this section if you already installed it from your
distro's package manager.

```sh
git clone https://gitlab.matrix.org/matrix-org/olm/
cd olm
cmake . -Bbuild
cmake --build build
sudo make install
```


## Installing Mirage

After following the above sections instructions depending on your system,
clone the repository, install the python dependencies, compile and install:

```sh
git clone --recursive https://github.com/mirukan/mirage
cd mirage
pip3 install --user -Ur requirements.txt
pip3 install --user -U uvloop==0.14.0

qmake mirage.pro
make
sudo make install
```

`uvloop` brings performance improvements, but can be skipped 
if you have trouble installing it.

If everything went fine, run `mirage` to start.


## Common Issues

### cffi version mismatch

When installing the python dependencies, if you get a version mismatch error
related to `cffi`, try:

```sh
pip3 install --user --upgrade --force-reinstall cffi
```

### Component is not ready

If the application doesn't start when you run `mirage` and shows a 
`QQmlComponent: Component is not ready` message in the terminal,
a QML component failed to import due to either missing dependencies
or a programming error.

If PyOtherSide is correctly installed, you should see a similar message:

    Got library name:  "/usr/lib/qt5/qml/io/thp/pyotherside/libpyothersideplugin.so"

If not, verify the installed files and their permissions. 
To ensure the correct permissions are set for the PyOtherSide plugin files:

    sudo chmod -R 755 /usr/lib/qt5/qml/io
    sudo chmod 644 /usr/lib/qt5/qml/io/thp/pyotherside/*
    sudo chmod 755 /usr/lib/qt5/qml/io/thp/pyotherside/*.so

Note that the Qt lib path might be `/usr/lib/qt/` instead of `/usr/lib/qt5/`,
depending on the distro.
