# AppImage building

The image must be built on Ubuntu 16.04 Xenial, to ensure compatibility with
older systems.

LXD can be used to setup a suitable container from any distro.

If not done already (all default settings are usually fine):

    lxd init

Initialize a new container named `ubuntu`:

    lxc launch images:ubuntu/xenial/amd64 ubuntu

Now, you can either clone the repo from inside the container...:

    lxc exec ubuntu -- apt install -y git
    lxc exec ubuntu -- git pull https://github.com/mirukana/mirage

...or directly copy a repository from your local filesystem inside:

    lxc exec ubuntu -- /bin/mkdir -p /root/mirage
    lxc file push -vr <path to repo root>/* ubuntu/root/mirage

Run the build script inside the container:

    lxc exec ubuntu -- /root/mirage/packaging/appimage/build.sh

You can also start a shell inside (e.g. if something goes wrong):

    lxc exec ubuntu -- /bin/bash
