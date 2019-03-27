# Copyright 2019 miruka
# This file is part of harmonyqml, licensed under GPLv3.

import sys

from PyQt5.QtGui import QGuiApplication

from .engine import Engine

# logging.basicConfig(level=logging.INFO)


def run() -> None:
    try:
        sys.argv.index("--debug")
        debug = True
    except ValueError:
        debug = False

    app    = QGuiApplication(sys.argv)
    engine = Engine(app, debug=debug)
    engine.show_window()
