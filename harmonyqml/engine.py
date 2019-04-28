# Copyright 2019 miruka
# This file is part of harmonyqml, licensed under GPLv3.

import logging
import sys
from pathlib import Path
from typing import Generator

from PyQt5.QtCore import QFileSystemWatcher, QObject, QTimer
from PyQt5.QtQml import QQmlApplicationEngine

from .app import Application
from .backend.backend import Backend

# logging.basicConfig(level=logging.INFO)


class Engine(QQmlApplicationEngine):
    def __init__(self,
                 app:    Application,
                 debug:  bool = False) -> None:
        super().__init__(app)
        self.app     = app
        self.backend = Backend(self)
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
        if debug:
            self._watcher = QFileSystemWatcher()
            self._watcher.directoryChanged.connect(lambda _: self.reload_qml())
            self._watcher.addPath(str(self.app_dir))

            for _dir in list(self._recursive_dirs_in(self.app_dir)):
                self._watcher.addPath(str(_dir))

        # Load QML page and show window
        self.load(str(self.app_dir / "components" / "Window.qml"))


    def show_window(self) -> None:
        self.rootObjects()[0].show()
        sys.exit(self.app.exec())


    def _recursive_dirs_in(self, path: Path) -> Generator[Path, None, None]:
        for item in path.iterdir():
            if item.is_dir() and item.name != "__pycache__":
                yield item
                yield from self._recursive_dirs_in(item)


    def reload_qml(self) -> None:
        loader = self.rootObjects()[0].findChild(QObject, "UILoader")
        source = loader.property("source")
        loader.setProperty("source", None)
        self.clearComponentCache()
        loader.setProperty("source", source)
        logging.info("Reloaded: %s", source)
