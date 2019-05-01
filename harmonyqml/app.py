# Copyright 2019 miruka
# This file is part of harmonyqml, licensed under GPLv3.

from typing import List, Optional

from PyQt5.QtGui import QGuiApplication

from . import __about__


class Application(QGuiApplication):
    def __init__(self, args: Optional[List[str]] = None) -> None:
        self.debug = False

        if args and "--debug" in args:
            del args[args.index("--debug")]
            self.debug = True

        super().__init__(args or [])

        self.setApplicationName(__about__.__pkg_name__)
        self.setApplicationDisplayName(__about__.__pretty_name__)
