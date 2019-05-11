# Copyright 2019 miruka
# This file is part of harmonyqml, licensed under GPLv3.

import functools
import logging as log
import sys
import time
import traceback
from concurrent.futures import Executor, Future
from typing import Callable, Deque, Optional, Tuple, Union

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
        state = ("canceled" if self.cancelled else
                 "running"  if self.running   else
                 "finished")

        return "%s(state=%s, value=%r)" % (
            type(self).__name__, state, self.value
        )


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


_Task = Tuple[Executor, Callable, Optional[tuple], Optional[dict]]
_RUNNING: Deque[_Task] = Deque()
_PENDING: Deque[_Task] = Deque()


def futurize(max_running:            Optional[int] = None,
             consider_args:          bool          = False,
             discard_if_max_running: bool          = False,
             pyqt:                   bool          = True) -> Callable:

    def decorator(func: Callable) -> Callable:

        @functools.wraps(func)
        def wrapper(self, *args, **kws) -> Optional[PyQtFuture]:
            task: _Task = (
                self.pool,
                func,
                args if consider_args else None,
                kws  if consider_args else None,
            )

            def can_run_now() -> bool:
                if max_running is not None and \
                    _RUNNING.count(task) >= max_running:
                    log.debug("!! Max %d tasks of this kind running: %r",
                              max_running, task[1:])
                    return False

                if not consider_args or not _PENDING:
                    return True

                log.debug(".. Pending: %r\n  Queue: %r", task[1:],  _PENDING)
                candidate_task = next((
                    pending for pending in _PENDING
                    if pending[0] == self.pool and pending[1] == func
                ), None)

                if candidate_task is None:
                    log.debug(">> No other candidate, starting: %r", task[1:])
                    return True

                if candidate_task[2] == args and candidate_task[3] == kws:
                    log.debug(">> Candidate is us: %r", candidate_task[1:])
                    return True

                log.debug("XX Other candidate: %r", candidate_task[1:])
                return False

            if not can_run_now() and discard_if_max_running:
                log.debug("\\/ Discarding task: %r", task[1:])
                return None

            def run_and_catch_errs():
                if not can_run_now():
                    log.debug("~~ Can't start now: %r", task[1:])
                    _PENDING.append(task)

                    while not can_run_now():
                        time.sleep(0.05)

                _RUNNING.append(task)
                log.debug("Starting: %r", task[1:])

                # Without this, exceptions are silently ignored
                try:
                    return func(self, *args, **kws)
                except Exception:
                    traceback.print_exc()
                    log.error("Exiting thread/process due to exception.")
                    sys.exit(1)
                finally:
                    del _RUNNING[_RUNNING.index(task)]

            future = self.pool.submit(run_and_catch_errs)
            return PyQtFuture(future, self) if pyqt else future

        return wrapper

    return decorator
