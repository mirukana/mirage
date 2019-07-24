# Copyright 2019 miruka
# This file is part of harmonyqml, licensed under LGPLv3.

import asyncio
import signal
from concurrent.futures import Future
from operator import attrgetter
from pathlib import Path
from threading import Thread
from typing import Any, Coroutine, Dict, List, Optional, Sequence

import uvloop
from appdirs import AppDirs

import pyotherside

from . import __about__
from .events.app import CoroutineDone, ExitRequested


class App:
    def __init__(self) -> None:
        self.appdirs = AppDirs(appname=__about__.__pkg_name__, roaming=True)

        from .backend import Backend
        self.backend = Backend(app=self)
        self.debug   = False

        from .image_provider import ImageProvider
        self.image_provider = ImageProvider(self)
        pyotherside.set_image_provider(self.image_provider.get)

        self.loop        = asyncio.get_event_loop()
        self.loop_thread = Thread(target=self._loop_starter)
        self.loop_thread.start()


    def is_debug_on(self, cli_flags: Sequence[str] = ()) -> bool:
        debug      = "-d" in cli_flags or "--debug" in cli_flags
        self.debug = debug
        return debug


    def _loop_starter(self) -> None:
        asyncio.set_event_loop(self.loop)
        asyncio.set_event_loop_policy(uvloop.EventLoopPolicy())
        self.loop.run_forever()


    def run_in_loop(self, coro: Coroutine) -> Future:
        return asyncio.run_coroutine_threadsafe(coro, self.loop)


    def _call_coro(self, coro: Coroutine, uuid: str) -> None:
        self.run_in_loop(coro).add_done_callback(
            lambda future: CoroutineDone(uuid=uuid, result=future.result())
        )


    def call_backend_coro(self, name: str, uuid: str, args: Sequence[str] = ()
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
        # pylint: disable=all
        ad = additional_data
        rl = self.run_in_loop
        ba = self.backend
        cl = self.backend.clients
        tcl = lambda user: cl[f"@test_{user}:matrix.org"]

        import json
        jd = lambda obj: print(json.dumps(obj, indent=4, ensure_ascii=False))

        print("\n=> Run `socat readline tcp:127.0.0.1:4444` in a terminal "
              "to connect to pdb.")
        import remote_pdb
        remote_pdb.RemotePdb("127.0.0.1", 4444).set_trace()


# Make CTRL-C work again
signal.signal(signal.SIGINT, signal.SIG_DFL)

APP = App()
