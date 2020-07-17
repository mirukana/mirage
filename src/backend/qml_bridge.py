# SPDX-License-Identifier: LGPL-3.0-or-later

# WARNING: make sure to not top-level import the media_cache module here,
# directly or indirectly via another module import (e.g. backend).
# See https://stackoverflow.com/a/55918049

"""Provide `BRIDGE`, main object accessed by QML to interact with Python.

PyOtherSide, the library that handles interaction between our Python backend
and QML UI, will access the `BRIDGE` object and call its methods directly.

The `BRIDGE` object should be the only existing instance of the `QMLBridge`
class.
"""

import asyncio
import atexit
import logging as log
import os
import signal
import traceback
from concurrent.futures import Future
from operator import attrgetter
from threading import Thread
from typing import Coroutine, Sequence

import pyotherside

from .pyotherside_events import CoroutineDone, LoopException


class QMLBridge:
    """Setup asyncio and provide methods to call coroutines from QML.

    A thread is created to run the asyncio loop in, to ensure all calls from
    QML return instantly.
    Synchronous methods are provided for QML to call coroutines using
    PyOtherSide, which doesn't have this ability out of the box.

    Attributes:
        backend: The `backend.Backend` object containing general coroutines
            for QML and that manages `MatrixClient` objects.
    """

    def __init__(self) -> None:
        try:
            self._loop = asyncio.get_event_loop()
        except RuntimeError:
            self._loop = asyncio.new_event_loop()
            asyncio.set_event_loop(self._loop)
        self._loop.set_exception_handler(self._loop_exception_handler)

        from .backend import Backend
        self.backend: Backend = Backend()

        Thread(target=self._start_asyncio_loop).start()


    def _loop_exception_handler(
        self, loop: asyncio.AbstractEventLoop, context: dict,
    ) -> None:
        if "exception" in context:
            err   = context["exception"]
            trace = "".join(
                traceback.format_exception(type(err), err, err.__traceback__),
            )
            LoopException(context["message"], err, trace)

        loop.default_exception_handler(context)


    def _start_asyncio_loop(self) -> None:
        asyncio.set_event_loop(self._loop)
        self._loop.run_forever()


    def _call_coro(self, coro: Coroutine, uuid: str) -> Future:
        """Schedule a coroutine to run in our thread and return a `Future`."""

        def on_done(future: Future) -> None:
            """Send a PyOtherSide event with the coro's result/exception."""
            result = exception = trace = None

            try:
                result = future.result()
            except Exception as err:
                exception = err
                trace     = traceback.format_exc().rstrip()

            CoroutineDone(uuid, result, exception, trace)

        future = asyncio.run_coroutine_threadsafe(coro, self._loop)
        future.add_done_callback(on_done)
        return future


    def call_backend_coro(
        self, name: str, uuid: str, args: Sequence[str] = (),
    ) -> Future:
        """Schedule a `Backend` coroutine and return a `Future`."""

        return self._call_coro(attrgetter(name)(self.backend)(*args), uuid)


    def call_client_coro(
        self, user_id: str, name: str, uuid: str, args: Sequence[str] = (),
    ) -> Future:
        """Schedule a `MatrixClient` coroutine and return a `Future`."""

        client = self.backend.clients[user_id]
        return self._call_coro(attrgetter(name)(client)(*args), uuid)


    def pdb(self, additional_data: Sequence = ()) -> None:
        """Call the RemotePdb debugger; define some conveniance variables."""

        ad  = additional_data              # noqa
        ba  = self.backend                 # noqa
        mo  = self.backend.models          # noqa
        cl  = self.backend.clients
        gcl = lambda user: cl[f"@{user}"]  # noqa

        rc = lambda c: asyncio.run_coroutine_threadsafe(c, self._loop)  # noqa

        p = print  # pdb's `p` doesn't print a class's __str__  # noqa
        try:
            log.warning("\nThe pprintpp python package is not installed.")
            from pprintpp import pprint as pp  # noqa
        except ModuleNotFoundError:
            pass

        try:
            import remote_pdb
        except ModuleNotFoundError:
            log.warning(
                "\nThe remote_pdb python package is not installed, falling "
                "back to pdb.",
            )
            import pdb
            pdb.set_trace()
        else:
            log.info(
                "\n=> Run `socat readline tcp:127.0.0.1:4444` in a terminal "
                "to connect to the debugger.",
            )
            remote_pdb.RemotePdb("127.0.0.1", 4444).set_trace()


    def exit_mirage(self) -> None:
        """Used to end some tasks before closing"""

        try:
            # Set accounts presence to offline
            asyncio.run_coroutine_threadsafe(
                self.backend.logoff_all(),
                self._loop,
            ).result()
        except Exception as e:
            print(e)


# The AppImage AppRun script overwrites some environment path variables to
# correctly work, and sets RESTORE_<name> equivalents with the original values.
# If the app is launched from an AppImage, now restore the original values
# to prevent problems like QML Qt.openUrlExternally() failing because
# the external launched program is affected by our AppImage-specific variables.
for var in ("LD_LIBRARY_PATH", "PYTHONHOME", "PYTHONUSERBASE"):
    if f"RESTORE_{var}" in os.environ:
        os.environ[var] = os.environ[f"RESTORE_{var}"]


# Make CTRL-C work again
try:
    signal.signal(signal.SIGINT, signal.SIG_DFL)
except ValueError:
    # FIXME - happens when we're imported from a thread,
    # occurs in py3.8 but not 3.6?
    pass

BRIDGE = QMLBridge()

pyotherside.atexit(BRIDGE.exit_mirage)
