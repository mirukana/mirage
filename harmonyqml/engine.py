# Copyright 2019 miruka
# This file is part of harmonyqml, licensed under GPLv3.

import logging
import sys
from pathlib import Path
from typing import Optional

from PyQt5.QtCore import QFileSystemWatcher, QObject, QTimer
from PyQt5.QtGui import QGuiApplication
from PyQt5.QtQml import QQmlApplicationEngine

from .__about__ import __doc__
from .backend import DummyBackend

# logging.basicConfig(level=logging.INFO)


class Engine(QQmlApplicationEngine):
    def __init__(self, app: QGuiApplication, parent: Optional[QObject] = None
                ) -> None:
        super().__init__(parent)
        self.app     = app
        self.backend = DummyBackend()
        self.app_dir = Path(sys.argv[0]).resolve().parent

        # Set QML properties
        self.rootContext().setContextProperty("Engine", self)
        self.rootContext().setContextProperty("Backend", self.backend)

        # Connect Qt signals
        self.quit.connect(self.app.quit)

        # Make SIGINT (ctrl-c) work
        self._sigint_timer = QTimer()
        self._sigint_timer.timeout.connect(lambda: None)
        self._sigint_timer.start(100)

        # Setup UI live-reloading when a file is edited
        self.file_watcher = QFileSystemWatcher()
        self.file_watcher.directoryChanged.connect(lambda _: self.reload_qml())
        self.file_watcher.addPath(str(self.app_dir / "components"))

        # Load QML page and show window
        self.load(str(self.app_dir / "components" / "Window.qml"))


    def show_window(self) -> None:
        self.rootObjects()[0].show()
        sys.exit(self.app.exec())


    def reload_qml(self) -> None:
        self.clearComponentCache()
        loader = self.rootObjects()[0].findChild(QObject, "UILoader")
        source = loader.property("source")
        loader.setProperty("source", None)
        loader.setProperty("source", source)
        logging.info("Reloaded: %s", source)
