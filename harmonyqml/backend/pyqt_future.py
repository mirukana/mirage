# Copyright 2019 miruka
# This file is part of harmonyqml, licensed under GPLv3.

import functools
import logging
import sys
import traceback
from concurrent.futures import Executor, Future
from typing import Callable, List, Optional, Tuple, Union

from PyQt5.QtCore import QObject, pyqtProperty, pyqtSignal, pyqtSlot


class PyQtFuture(QObject):
    gotResult = pyqtSignal("QVariant")

    def __init__(self, future: Future, parent: QObject) -> None:
        super().__init__(parent)
        self.future  = future
        self._result = None

        self.future.add_done_callback(
            lambda future: self.gotResult.emit(future.result())
        )


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


_RUNNING: List[Tuple[Executor, Callable, tuple, dict]] = []


def futurize(max_instances: Optional[int] = None, pyqt: bool = True
            ) -> Callable:

    def decorator(func: Callable) -> Callable:

        @functools.wraps(func)
        def wrapper(self, *args, **kws) -> Optional[PyQtFuture]:
            def run_and_catch_errs():
                # Without this, exceptions are silently ignored
                try:
                    return func(self, *args, **kws)
                except Exception:
                    traceback.print_exc()
                    logging.error("Exiting thread due to exception.")
                    sys.exit(1)
                finally:
                    del _RUNNING[_RUNNING.index((self.pool, func, args, kws))]

            if max_instances is not None and \
               _RUNNING.count((self.pool, func, args, kws)) >= max_instances:
                return None

            _RUNNING.append((self.pool, func, args, kws))
            future = self.pool.submit(run_and_catch_errs)
            return PyQtFuture(future, self) if pyqt else future

        return wrapper

    return decorator
