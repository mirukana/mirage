# Copyright 2019 miruka
# This file is part of harmonyqml, licensed under GPLv3.

from typing import List, Optional

from PyQt5.QtGui import QGuiApplication

from . import __about__


class Application(QGuiApplication):
    def __init__(self, args: Optional[List[str]] = None) -> None:
        try:
            args.index("--debug")  # type: ignore
            debug = True
        except (AttributeError, ValueError):
            debug = False

        super().__init__(args or [])

        self.setApplicationName(__about__.__pkg_name__)
        self.setApplicationDisplayName(__about__.__pretty_name__)

        from .engine import Engine
        engine = Engine(self, debug=debug)
        engine.show_window()
