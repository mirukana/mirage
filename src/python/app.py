import asyncio
import logging as log
import signal
from concurrent.futures import Future
from operator import attrgetter
from threading import Thread
from typing import Coroutine, Sequence

import uvloop
from appdirs import AppDirs

from . import __about__, pyotherside
from .pyotherside_events import CoroutineDone

log.getLogger().setLevel(log.INFO)


class App:
    def __init__(self) -> None:
        self.appdirs = AppDirs(appname=__about__.__pkg_name__, roaming=True)

        from .backend import Backend
        self.backend = Backend(app=self)
        self.debug   = False

        from .image_provider import ImageProvider
        self.image_provider = ImageProvider(self)
        pyotherside.set_image_provider(self.image_provider.get)

        self.loop = asyncio.get_event_loop()

        if not pyotherside.AVAILABLE:
            self.set_debug(True, verbose=True)

        self.loop_thread = Thread(target=self._loop_starter)
        self.loop_thread.start()


    def set_debug(self, enable: bool, verbose: bool = False) -> None:
        if verbose:
            log.getLogger().setLevel(log.DEBUG)

        if enable:
            log.info("Debug mode enabled.")
            self.loop.set_debug(True)
            self.debug = True
        else:
            self.loop.set_debug(False)
            self.debug = False


    def _loop_starter(self) -> None:
        asyncio.set_event_loop(self.loop)
        asyncio.set_event_loop_policy(uvloop.EventLoopPolicy())
        self.loop.run_forever()


    def run_in_loop(self, coro: Coroutine) -> Future:
        return asyncio.run_coroutine_threadsafe(coro, self.loop)


    def _call_coro(self, coro: Coroutine, uuid: str) -> None:
        self.run_in_loop(coro).add_done_callback(
            lambda future: CoroutineDone(uuid=uuid, result=future.result()),
        )


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


    def test_run(self) -> None:
        self.call_backend_coro("load_settings", "")
        self.call_backend_coro("load_saved_accounts", "")


# Make CTRL-C work again
signal.signal(signal.SIGINT, signal.SIG_DFL)

APP = App()
