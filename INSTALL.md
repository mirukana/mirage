# Installation

Instructions and releases are currently only available for Linux,
but compiling on Windows and macOS should be possible with the right tools.

- [Packages](#packages)
  - [Linux](#linux)
    - [AppImage](#appimage)
    - [Flatpak](#flatpak)
    - [Arch Linux](#arch-linux)
- [Manual installation](#manual-installation)
  - [Environment variables](#environment-variables)
  - [Package manager dependencies](#package-manager-dependencies)
    - [Alpine Linux 3.9+ / apk](#alpine-linux-39--apk)
    - [Arch Linux / pacman & AUR](#arch-linux--pacman--aur)
    - [Fedora 30+ / dnf](#fedora-30--dnf)
    - [Gentoo / emerge](#gentoo--emerge)
    - [Ubuntu 19.04 / apt](#ubuntu-1904--apt)
    - [Ubuntu 19.10+, Debian bullseye / apt](#ubuntu-1910-debian-bullseye--apt)
    - [Void Linux / xbps](#void-linux--xbps)
  - [Installing PyOtherSide manually](#installing-pyotherside-manually)
  - [Installing libolm manually](#installing-libolm-manually)
  - [Installing or updating Mirage](#installing-or-updating-mirage)
  - [Common issues](#common-issues)
    - [cffi version mismatch](#cffi-version-mismatch)
    - [Component is not ready](#component-is-not-ready)


## Packages

### Linux

For developement, or if none of the package options are satisfying, 
see [manual installation](#manual-installation).

#### AppImage

For **x86 64bit glibc-based systems**, Mirage is available as an AppImage
on the [release page](https://github.com/mirukana/mirage/releases).

AppImages are single executable files that contain the app and all 
its dependencies.  
Mirage images are built in Ubuntu 16.04, and should therefore run on any distro
released in April 2016 or later.

[How to start AppImages](https://docs.appimage.org/introduction/quickstart.html#how-to-run-an-appimage)
(TL;DR: `chmod +x Mirage-*.AppImage && ./Mirage-*.AppImage`)

#### Flatpak

Mirage is also available as a Flatpak
on the [release page](https://github.com/mirukana/mirage/releases).  
Follow [these instructions](https://flatpak.org/setup/) to install the flatpak
command on your system.

To then install and run the downloaded `.flatpak` file:

```sh
    flatpak remote-add --user --if-not-exists \
        flathub https://flathub.org/repo/flathub.flatpakrepo

    flatpak install --user flathub org.kde.Platform//5.14
    flatpak install --user mirage-*.flatpak

    flatpak run io.github.mirukana.mirage
```

If downloading the dependencies fail due to e.g. connection error,
run `flatpak repair` before retrying.

If your architecture is not listed on the release page, clone the repository
and see [packaging/flatpak/README.md](packaging/flatpak/README.md) to build the
package on your machine.

#### Arch Linux

Available on the AUR:
- [release](https://aur.archlinux.org/packages/matrix-mirage-git/)
- [git master](https://aur.archlinux.org/packages/matrix-mirage/)

Using a AUR helper to install it,
in this example [yay](https://github.com/Jguer/yay) for the release version:

    yay -S matrix-mirage


## Manual Installation

**Qt 5.12+**, **Python 3.6+** (with **pip** to install packages from the
[requirements.txt](requirements.txt)), **PyOtherSide 1.5+** and
**libolm 3+** are required.  
The equivalent `-dev` or `-devel` packages are needed, if your distro
splits development headers into their own packages.

To enable X11-specific features on Linux,
**libX11** and **libXScrnSaver** / **libXss** are needed.
The requirements can be disabled by adding `CONFIG+=no-x11` to the
`qmake mirage.pro` command.

For the Pillow Python package, these dependencies are recommended to support 
all common image formats:

- **libjpeg-turbo**
- **zlib**
- **libtiff**
- **libwebp**
- **openjpeg2**

**libmediainfo** is also required for the pymediainfo package.

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
             libx11-dev libxscrnsaver-dev \
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
         libx11 libxss \
         python python-pip \
         python-pyotherside \
         libolm \
         base-devel git cmake \
         libjpeg-turbo zlib libtiff libwebp openjpeg2 libmediainfo
```

#### Fedora 30+ / dnf

```sh
sudo dnf groupinstall 'Development Tools'
sudo dnf install qt5-devel qt5-qtbase-devel qt5-qtdeclarative-devel \
                 qt5-qtquickcontrols2-devel qt5-qtsvg-devel \
                 qt5-qtgraphicaleffects qt5-qtimageformats \
                 python3-devel python3-pip pyotherside \
                 libX11-devel libXScrnSaver-devel \
                 git cmake \
                 libolm-devel \
                 libjpeg-turbo-devel zlib-devel libtiff-devel libwebp-devel \
                 openjpeg2-devel libmediainfo-devel

sudo ln -s /usr/bin/qmake-qt5 /usr/bin/qmake
```

#### Gentoo / emerge

[libolm](#installing-libolm-manually) must be manually installed.

You might need to prepend the `emerge` command with `USE=bindist`,
if `emerge` says so.

```sh
sudo emerge -av qtcore qtdeclarative qtquickcontrols2 \
                qtsvg qtgraphicaleffects qtimageformats \
                libX11 libXScrnSaver \
                dev-python/pip pyotherside \
                dev-vcs/git cmake \
                libjpeg-turbo zlib tiff libwebp openjpeg libmediainfo
```

#### Ubuntu 19.04 / apt

[libolm](#installing-libolm-manually) must be manually installed.


```sh
sudo apt update
sudo apt install qt5-default qt5-qmake qt5-image-formats-plugins \
                 qml-module-qtquick2 qml-module-qtquick-window2 \
                 qml-module-qtquick-layouts qml-module-qtquick-dialogs \
                 qml-module-qt-labs-platform \
                 qml-module-qtquick-shapes \
                 qtdeclarative5-dev \
                 qtquickcontrols2-5-dev \
                 libx11-dev libxss-dev \
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
                      libx11-devel libXScrnSaver-devel \
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


### Installing or updating Mirage

After following the above sections instructions depending on your system;
clone the repository, initalize the submodules,
install the python dependencies, compile and install:

```sh
git clone https://github.com/mirukana/mirage
cd mirage

git pull
git submodule update --init submodules/*
pip3 install --user -Ur requirements.txt

qmake mirage.pro
make
sudo make install
```

To compile without the X11-specific dependencies and features on Linux,
run `qmake mirage.pro CONFIG+=no-x11` instead of `qmake mirage.pro`.

If everything went fine, run `mirage` to start.


### Common Issues

#### cffi version mismatch

When installing the python dependencies, if you get a version mismatch error
related to `cffi`, try:

```sh
pip3 install --user --upgrade --force-reinstall cffi
```

#### Component is not ready

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
