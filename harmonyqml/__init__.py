# Copyright 2019 miruka
# This file is part of harmonyqml, licensed under GPLv3.

import sys

from . import app

# logging.basicConfig(level=logging.INFO)


def run() -> None:
    _ = app.Application(sys.argv)
