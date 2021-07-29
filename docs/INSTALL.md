# Installation

Instructions and releases are currently only available for Linux,
but compiling on Windows and macOS [should be possible](https://github.com/mirukana/mirage/issues/24) with the right tools.

- [Packages](#packages)
  - [Linux](#linux)
    - [AppImage](#appimage)
    - [Flatpak](#flatpak)
    - [Alpine Linux / postmarketOS](#alpine-linux--postmarketOS)
    - [Arch Linux](#arch-linux)
    - [Debian](#debian)
    - [Gentoo](#gentoo)
    - [Nix](#nix)
    - [OpenMandriva Lx](#openmandriva-lx)
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
    - [Type XYZ unavailable](#type-xyz-unavailable)


## Packages

### Linux

For developement, or if none of the package options are satisfying, 
see [manual installation](#manual-installation).  
Packages other than the AppImage and Flatpak are not maintained by the Mirage 
authors, and thus might be outdated.

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

Mirage is also available as a Flatpak.

1. Download the Mirage Flatpak from the
[release page](https://github.com/mirukana/mirage/releases).

2. If your operating system doesn't already have built-in support for Flatpaks,
follow [these instructions](https://flatpak.org/setup/) to install Flatpak
support on your system.

3. To actually install and run Mirage, it should be enough to double-click the 
downloaded `.flatpak` file, which will open your software manager.
Alternatively, you can issue the following commands in a terminal:

```sh
flatpak remote-add --user --if-not-exists \
    flathub https://flathub.org/repo/flathub.flatpakrepo

flatpak install --user flathub org.kde.Platform//5.14
flatpak install --user /path/to/downloaded/mirage-*.flatpak

flatpak run io.github.mirukana.mirage
```

If downloading the dependencies fail due to e.g. a connection error,
run `flatpak repair` before retrying.

If your architecture is not listed on the release page, clone the repository
and see [packaging/flatpak/README.md](packaging/flatpak/README.md) to build the
package on your machine.

#### Alpine Linux / postmarketOS

If you are on the Edge channel of Alpine Linux or postmarketOS, Mirage can be
installed right from the testing repositry:

```sh
apk add mirage
```

If you are unsure about what Edge is and want to read more about it, you can do
so on the [Alpine Wiki](https://wiki.alpinelinux.org/wiki/Edge).

#### Arch Linux

AUR packages for the
[latest stable release](https://aur.archlinux.org/packages/matrix-mirage/) and
[git `dev` branch](https://aur.archlinux.org/packages/matrix-mirage-git/) are
available.

Installing the release version with a AUR helper, e.g. 
[yay](https://github.com/Jguer/yay):

```sh
yay -S matrix-mirage
```

#### Debian

Requires [Debian Testing](https://wiki.debian.org/DebianTesting). 
To install the package:

```sh
apt update
apt install matrix-mirage
```

#### Gentoo

Available in the [src_prepare overlay](https://gitlab.com/src_prepare/src_prepare-overlay)
- [releases](https://gitlab.com/src_prepare/src_prepare-overlay/-/tree/master/net-im/mirage)
- [git dev](https://gitlab.com/src_prepare/src_prepare-overlay/-/blob/master/net-im/mirage/mirage-9999.ebuild)

Installing Mirage:

1. [Add the overlay](https://gitlab.com/src_prepare/src_prepare-overlay#adding-the-overlay)
2. [Unmask](https://wiki.gentoo.org/wiki/Knowledge_Base:Unmasking_a_package) `net-im/mirage`
3. Run `emerge net-im/mirage`

#### Nix

Requires the unstable channel, to add it:

```sh
nix-channel --add https://nixos.org/channels/nixpkgs-unstable
nix-channel --update
```

To install the package:

```sh
nix-env -iA nixpkgs.mirage-im
```

#### OpenMandriva Lx

Requires [Unstable or Rolling][1]. To install the package:

```sh
sudo dnf install matrix-mirage
```

[1]: https://openmandriva.net/wiki/en/index.php?title=OpenMandriva_Release_Plan_and_Repositories#Release_Plan

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
             libx11-dev libxscrnsaver-dev alsa-lib-dev \
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
         libx11 libxss alsa-lib \
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
                 libX11-devel libXScrnSaver-devel alsa-lib-devel \
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
                libX11 libXScrnSaver alsa-lib \
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
                 libx11-dev libxss-dev libasound2-dev \
                 python3-dev python3-pip \
                 qml-module-io-thp-pyotherside \
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
                      libx11-devel libXScrnSaver-devel alsa-lib-devel \
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

#### Type XYZ unavailable

If the application exits without showing any window and you get a terminal
message like this:

    file:///.../src/gui/Window.qml:83:5: Type PythonRootBridge unavailable

then a QML component/type failed to import due to either a missing 
dependency or a programming error.  
If the type has `Python` in its name, ensure PyOtherSide is correctly
installed. You should see a similar message:

    Got library name:  "/usr/lib/qt5/qml/io/thp/pyotherside/libpyothersideplugin.so"

To ensure the correct permissions are set for the PyOtherSide plugin files:

```sh
sudo chmod -R 755 /usr/lib/qt5/qml/io
sudo chmod 644 /usr/lib/qt5/qml/io/thp/pyotherside/*
sudo chmod 755 /usr/lib/qt5/qml/io/thp/pyotherside/*.so
```

Note that the Qt lib path might be `/usr/lib/qt/` instead of `/usr/lib/qt5/`,
depending on the distro.
