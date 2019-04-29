# Copyright 2019 miruka
# This file is part of harmonyqml, licensed under GPLv3.

import os
import sys

# logging.basicConfig(level=logging.INFO)

# The disk cache is responsible for multiple display bugs when running
# the app for the first time/when cache needs to be recompiled, on top
# of litering the source folders with .qmlc files.
os.environ["QML_DISABLE_DISK_CACHE"] = "1"


def run() -> None:
    from . import app
    _ = app.Application(sys.argv)
