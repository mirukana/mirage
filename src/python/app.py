import asyncio
import logging as log
import signal
import sys
import traceback
from concurrent.futures import Future
from operator import attrgetter
from threading import Thread
from typing import Coroutine, Sequence

import nio
from appdirs import AppDirs

from . import __about__
from .pyotherside_events import CoroutineDone

log.getLogger().setLevel(log.INFO)
nio.logger_group.level = nio.log.logbook.ERROR
nio.log.logbook.StreamHandler(sys.stderr).push_application()

try:
    import uvloop
except ModuleNotFoundError:
    UVLOOP = False
    log.info("uvloop not available, using default asyncio loop.")
else:
    UVLOOP = True
    log.info("uvloop is available.")


class App:
    def __init__(self) -> None:
        self.appdirs = AppDirs(appname=__about__.__pkg_name__, roaming=True)

        from .backend import Backend
        self.backend = Backend(app=self)
        self.debug   = False

        self.loop        = asyncio.get_event_loop()
        self.loop_thread = Thread(target=self._loop_starter)
        self.loop_thread.start()


    def _loop_starter(self) -> None:
        asyncio.set_event_loop(self.loop)

        if UVLOOP:
            asyncio.set_event_loop_policy(uvloop.EventLoopPolicy())

        self.loop.run_forever()


    def run_in_loop(self, coro: Coroutine) -> Future:
        return asyncio.run_coroutine_threadsafe(coro, self.loop)


    def _call_coro(self, coro: Coroutine, uuid: str) -> None:
        def on_done(future: Future) -> None:
            result = exception = trace = None

            try:
                result = future.result()
            except Exception as err:
                exception = err
                trace     = traceback.format_exc().rstrip()

            CoroutineDone(uuid, result, exception, trace)

        self.run_in_loop(coro).add_done_callback(on_done)


    def call_backend_coro(self, name: str, uuid: str, args: Sequence[str] = (),
                         ) -> None:
        self._call_coro(attrgetter(name)(self.backend)(*args), uuid)


    def call_client_coro(self,
                         account_id: str,
                         name:       str,
                         uuid:       str,
                         args:       Sequence[str] = ()) -> None:
        client = self.backend.clients[account_id]
        self._call_coro(attrgetter(name)(client)(*args), uuid)


    def pdb(self, additional_data: Sequence = ()) -> None:
        ad  = additional_data              # noqa
        rl  = self.run_in_loop             # noqa
        ba  = self.backend                 # noqa
        mo  = self.backend.models          # noqa
        cl  = self.backend.clients
        tcl = lambda user: cl[f"@test_{user}:matrix.org"]  # noqa

        from .models.items import Account, Room, Member, Event, Device  # noqa

        p = print  # pdb's `p` doesn't print a class's __str__  # noqa
        from pprintpp import pprint as pp  # noqa

        log.info("\n=> Run `socat readline tcp:127.0.0.1:4444` in a terminal "
                 "to connect to pdb.")
        import remote_pdb
        remote_pdb.RemotePdb("127.0.0.1", 4444).set_trace()


# Make CTRL-C work again
signal.signal(signal.SIGINT, signal.SIG_DFL)

APP = App()
