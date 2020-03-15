#!/usr/bin/env bash

# The image must be built on Ubuntu 16.04 Xenial, to ensure compatibility with
# older systems.
#
# LXD/LXC can be used to setup a suitable container from any distro.
#
# If using LXD and not done already (all default settings are fine):
#
#     lxd init
#
# To restart from scratch if you already had a container:
#
#     lxc stop ubuntu; lxc delete ubuntu  # if needed
#
# Initialize the container:
#
#     lxc launch images:ubuntu/xenial/amd64 ubuntu
#
# Copy the mirage repository inside the container
# (assuming you are currently in its root, else change the './*'):
#
#     lxc exec ubuntu -- /bin/mkdir -p /root/mirage
#     lxc file push -vr ./* ubuntu/root/mirage
#
# Run this script inside the container:
#
#     lxc exec ubuntu -- /root/mirage/build-appimage.sh
#
# You can also start a shell inside (e.g. if something goes wrong):
#
#     lxc exec ubuntu -- /bin/bash

set -eo pipefail


check_distro() {
    if grep -q '^\s*Ubuntu\s*16.04' /etc/issue; then return; fi

    echo "Not running on expected distribution or version, aborting!" >&2
    echo "Read the instructions inside this script for more info." >&2
    exit 99
}


parse_cli_arguments() {
    if [ "$1" = --skip-install-prerequisites ] || [ "$1" = -s ]; then
        skip_pre=true
    else
        skip_pre=false
    fi
}


setup_dns() {
    if ! grep -q 'dns-nameservers 9.9.9.9' /etc/network/interfaces; then
        sed -i '/iface eth0 inet dhcp/a dns-nameservers 9.9.9.9' \
            /etc/network/interfaces

        invoke-rc.d networking restart
    fi
}


install_apt_packages() {
    apt install -y software-properties-common
    add-apt-repository -y ppa:beineri/opt-qt-5.12.7-xenial
    apt update -y

    apt install -y qt512base qt512declarative qt512graphicaleffects \
        qt512imageformats qt512quickcontrols2 qt512svg \
        zip git wget cmake ccache \
        build-essential mesa-common-dev libglu1-mesa-dev freeglut3-dev \
        libglfw3-dev libgles2-mesa-dev libjpeg-turbo8-dev zlib1g-dev \
        libtiff5-dev liblcms2-dev libwebp-dev  libopenjp2-7-dev libssl-dev \
        python3-dev python3-setuptools python3-pip libgdbm-dev libc6-dev \
        zlib1g-dev libsqlite3-dev libffi-dev openssl

    /usr/sbin/update-ccache-symlinks
}


setup_env() {
    set +euo pipefail
    # shellcheck disable=SC1091
    source /opt/qt512/bin/qt512-env.sh
    set -euo pipefail

    export PATH="/usr/lib/ccache:$PATH"
    export LD_LIBRARY_PATH="$HOME/.local/lib/python3.8/site-packages/.libs_cffi_backend/:/usr/lib/x86_64-linux-gnu/:/usr/lib:$LD_LIBRARY_PATH"
    export PREFIX=/usr

    export CFLAGS="-march=x86-64 -O2 -pipe -fPIC"
    export CXXFLAGS="$CFLAGS"
    export MAKEFLAGS="-j$(($(nproc) + 1))"
}


install_python() {
    cd ~

    if ! [ -d ~/.pyenv ]; then
        wget -O - https://github.com/pyenv/pyenv-installer/raw/master/bin/pyenv-installer | bash
    fi

    export PATH="$HOME/.pyenv/bin:$PATH"

    set +euo pipefail
    eval "$(pyenv init -)"
    eval "$(pyenv virtualenv-init -)"
    set -euo pipefail

    export PYTHON_CFLAGS="$CFLAGS"
    export PYTHON_CONFIGURE_OPTS='--enable-shared  --enable-optimizations --with-lto'

    pyenv update
    pyenv install --verbose --skip-existing 3.8.2
    pyenv global 3.8.2
}


install_olm() {
    cd ~

    if ! [ -f olm-master.tar.gz ]; then
        wget 'https://gitlab.matrix.org/matrix-org/olm/-/archive/master/olm-master.tar.gz'
    fi

    tar xf olm-master.tar.gz

    cd olm-master
    cmake . -Bbuild
    cmake --build build

    cd python
    make olm-python3
    cd ..
    make install
}


install_pyotherside() {
    cd ~

    if ! [ -f 1.5.9.tar.gz ]; then
        wget 'https://github.com/thp/pyotherside/archive/1.5.9.tar.gz'
    fi

    tar xf 1.5.9.tar.gz

    cd pyotherside-1.5.9
    qmake
    make install
}


get_app_and_pip_dependencies() {
    cd ~

    if ! [ -d mirage ]; then
        git clone --recursive https://github.com/mirukan/mirage
    fi

    cd mirage
    pip3 install --user -Ur requirements.txt
    pip3 install --user -U uvloop==0.14.0 certifi
}


initialize_appdir() {
    cd ~/mirage
    qmake mirage.pro
    make install INSTALL_ROOT=build/appdir
}


complete_appdir() {
    cd ~/mirage/build

    cp -r ~/.pyenv/versions/3.8.2/* appdir/usr
    cp -r ~/.local/lib/python3.8/site-packages/* \
          appdir/usr/lib/python3.8/site-packages

    if ! [ -f linuxdeployqt-continuous-x86_64.AppImage ]; then
        wget 'https://github.com/probonopd/linuxdeployqt/releases/download/continuous/linuxdeployqt-continuous-x86_64.AppImage'
    fi
    chmod +x linuxdeployqt-continuous-x86_64.AppImage

    ./linuxdeployqt-continuous-x86_64.AppImage \
        appdir/usr/share/applications/mirage.desktop \
        -bundle-non-qt-libs \
        -qmldir=../src/gui

    cp /opt/qt512/qml/io/thp/pyotherside/qmldir appdir/usr/qml/io/thp/pyotherside

    # Remove useless heavy test data
    rm -rf appdir/usr/lib/python3.8/test
    rm -rf appdir/usr/lib/python3.8/site-packages/Crypto/SelfTest/

    # Remove python cache files
    find appdir -name '*.pyc' -delete
}


fix_apprun_launcher() {
    cd ~/mirage/build/appdir
    rm -f AppRun

    cat << 'EOF' > AppRun
#!/usr/bin/env sh
set -e
here="$(dirname "$(readlink -f "$0")")"
export SSL_CERT_FILE="$here/usr/lib/python3.8/site-packages/certifi/cacert.pem"
export LD_LIBRARY_PATH="$here/usr/lib:$LD_LIBRARY_PATH"
export PYTHONHOME=$here/usr
export PYTHONUSERBASE=$here/usr
cd "$here"
exec "$here/usr/bin/mirage" "$@"
EOF

    chmod +x AppRun
}


generate_appimage() {
    cd ~/mirage/build

    if ! [ -f appimagetool-x86_64.AppImage ]; then
        wget "https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage"
    fi

    chmod +x appimagetool-x86_64.AppImage
    ./appimagetool-x86_64.AppImage appdir
}


check_distro
parse_cli_arguments "$@"
setup_dns

if [ "$skip_pre" = false ]; then install_apt_packages; fi

setup_env

if [ "$skip_pre" = false ]; then
    install_python
    install_olm
    install_pyotherside
    get_app_and_pip_dependencies
fi

initialize_appdir
complete_appdir
fix_apprun_launcher
generate_appimage
