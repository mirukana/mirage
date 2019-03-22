# Copyright 2019 miruka
# This file is part of harmonyqml, licensed under GPLv3.

"harmonyqml setuptools file"

from setuptools import setup, find_packages

from harmonyqml import __about__


def get_readme():
    with open("README.md", "r") as readme:
        return readme.read()


setup(
    name        = __about__.__pkg_name__,
    version     = __about__.__version__,

    author       = __about__.__author__,
    author_email = __about__.__email__,
    license      = __about__.__license__,

    description                   = __about__.__doc__,
    long_description              = get_readme(),
    long_description_content_type = "text/markdown",

    python_requires  = ">=3.6, <4",
    install_requires = [
        "dataclasses;python_version<'3.7'",
        "docopt",
    ],

    include_package_data = True,
    packages             = find_packages(),
    # package_data         = {__about__.__pkg_name__: ["*.yaml"]},
    entry_points    = {
        "console_scripts": [
            f"{__about__.__pkg_name__}={__about__.__pkg_name__}.cli:main"
        ]
    },

    keywords = "<KEYWORDS>",
    url      = "https://github.com/mirukan/harmonyqml",

    classifiers=[
        "Development Status :: 3 - Alpha",
        # "Development Status :: 4 - Beta",
        # "Development Status :: 5 - Production/Stable",

        "Intended Audience :: Developers",
        "Intended Audience :: End Users/Desktop",

        "Environment :: Console",
        # "Environment :: Console :: Curses",
        # "Environment :: Plugins",
        # "Environment :: X11 Applications",
        # "Environment :: X11 Applications :: Qt",

        # "Topic :: Utilities",
        # grep '^Topic' ~/docs/web/pypi-classifiers.txt

        ("License :: OSI Approved :: "
         "GNU General Public License v3 or later (GPLv3+)"),

        "Programming Language :: Python :: 3",
        "Programming Language :: Python :: 3 :: Only",
        "Programming Language :: Python :: 3.6",
        "Programming Language :: Python :: 3.7",

        "Natural Language :: English",

        "Operating System :: POSIX",
    ]
)
