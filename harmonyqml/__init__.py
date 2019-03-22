# Copyright 2019 miruka
# This file is part of harmonyqml, licensed under GPLv3.

import logging
import os
import sys
from typing import Optional

from PyQt5.QtCore import (
    QFileSystemWatcher, QMetaObject, QObject, QTimer, pyqtSlot
)
from PyQt5.QtGui import QGuiApplication
from PyQt5.QtQml import QQmlApplicationEngine, qmlRegisterType

from .__about__ import __doc__
from .backend import DummyBackend

# logging.basicConfig(level=logging.INFO)


class Engine(QQmlApplicationEngine):
    def __init__(self, app: QGuiApplication, parent: Optional[QObject] = None
                ) -> None:
        super().__init__(parent)
        self.app         = app
        self.backend     = DummyBackend()
        self.program_dir = os.path.dirname(os.path.realpath(sys.argv[0]))

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
        self.file_watcher.addPath(self.program_dir)

        # Load QML page and show window
        self.load(os.path.join(self.program_dir, "Window.qml"))
        self.rootObjects()[0].show()
        sys.exit(self.app.exec())


    def reload_qml(self) -> None:
        self.clearComponentCache()
        loader = self.rootObjects()[0].findChild(QObject, "UILoader")
        source = loader.property("source")
        loader.setProperty("source", None)
        loader.setProperty("source", source)
        logging.info("Reloaded: %s", source)


def run() -> None:
    app = QGuiApplication(sys.argv)
    _   = Engine(app)  # need to keep a reference
