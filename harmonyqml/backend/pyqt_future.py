# Copyright 2019 miruka
# This file is part of harmonyqml, licensed under GPLv3.

import functools
import logging
import sys
import traceback
from concurrent.futures import Future
from threading import currentThread
from typing import Callable, Optional, Union

from PyQt5.QtCore import QObject, pyqtProperty, pyqtSignal, pyqtSlot


class PyQtFuture(QObject):
    gotResult = pyqtSignal()

    def __init__(self, future: Future, parent: QObject) -> None:
        super().__init__(parent)
        self.future  = future
        self._result = None

        self.future.add_done_callback(lambda _: self.gotResult.emit())


    def __repr__(self) -> str:
        return "%s(%s)" % (type(self).__name__, repr(self.future))


    @pyqtSlot()
    def cancel(self):
        self.future.cancel()


    @pyqtProperty(bool)
    def cancelled(self):
        return self.future.cancelled()


    @pyqtProperty(bool)
    def running(self):
        return self.future.running()


    @pyqtProperty(bool)
    def done(self):
        return self.future.done()


    @pyqtSlot(result="QVariant")
    @pyqtSlot(int, result="QVariant")
    @pyqtSlot(float, result="QVariant")
    def result(self, timeout: Optional[Union[int, float]] = None):
        return self.future.result(timeout)


    @pyqtProperty("QVariant", notify=gotResult)
    def value(self):
        return self.future.result() if self.done else None


    def add_done_callback(self, fn: Callable[[Future], None]) -> None:
        self.future.add_done_callback(fn)


def futurize(func: Callable) -> Callable:
    @functools.wraps(func)
    def wrapper(self, *args, **kwargs) -> PyQtFuture:
        def run_and_catch_errs():
            # Without this, exceptions are silently ignored
            try:
                return func(self, *args, **kwargs)
            except Exception:
                traceback.print_exc()
                logging.error("Exiting %s due to exception.", currentThread())
                sys.exit(1)

        return PyQtFuture(self.pool.submit(run_and_catch_errs), self)
    return wrapper
