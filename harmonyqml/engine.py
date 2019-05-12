# Copyright 2019 miruka
# This file is part of harmonyqml, licensed under GPLv3.

import signal
from pathlib import Path
from typing import Any, Dict, Generator

from PyQt5.QtCore import QObject, QTimer
from PyQt5.QtQml import QQmlApplicationEngine


class Engine(QQmlApplicationEngine):
    def __init__(self, debug:  bool = False) -> None:
        # Connect UNXI signals to properly exit program
        self._original_signal_handlers: Dict[int, Any] = {}

        for signame in ("INT" , "HUP", "QUIT", "TERM"):
            sig = signal.Signals[f"SIG{signame}"]  # pylint: disable=no-member
            self._original_signal_handlers[sig] = signal.getsignal(sig)
            signal.signal(sig, self.onExitSignal)

        # Make SIGINT (ctrl-c) work
        self._sigint_timer = QTimer()
        self._sigint_timer.timeout.connect(lambda: None)
        self._sigint_timer.start(100)

        super().__init__()
        self.app_dir = Path(__file__).resolve().parent

        from .backend.backend import Backend
        self.backend = Backend(self)
        self.rootContext().setContextProperty("Backend", self.backend)

        # Setup UI live-reloading when a file is edited
        if debug:
            from PyQt5.QtCore import QFileSystemWatcher
            self._watcher = QFileSystemWatcher()
            self._watcher.directoryChanged.connect(lambda _: self.reloadQml())
            self._watcher.addPath(str(self.app_dir))

            for _dir in list(self._recursive_dirs_in(self.app_dir)):
                self._watcher.addPath(str(_dir))


    def onExitSignal(self, *_) -> None:
        for sig, handler in self._original_signal_handlers.items():
            signal.signal(sig, handler)

        self._original_signal_handlers.clear()
        self.closeWindow()


    def _recursive_dirs_in(self, path: Path) -> Generator[Path, None, None]:
        for item in path.iterdir():
            if item.is_dir() and item.name != "__pycache__":
                yield item
                yield from self._recursive_dirs_in(item)


    def showWindow(self) -> None:
        self.load(str(self.app_dir / "components" / "Window.qml"))


    def closeWindow(self) -> None:
        try:
            self.rootObjects()[0].close()
        except IndexError:
            pass


    def reloadQml(self) -> None:
        loader = self.rootObjects()[0].findChild(QObject, "UILoader")
        source = loader.property("source")
        loader.setProperty("source", None)
        self.clearComponentCache()

        window         = self.rootObjects()[0]
        reloaded_times = window.property("reloadedTimes")
        window.setProperty("reloadedTimes", reloaded_times + 1)

        loader.setProperty("source", source)
