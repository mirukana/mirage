import asyncio
from concurrent.futures import Future
from pathlib import Path
from threading import Thread
from typing import Any, Coroutine, Dict, List, Optional, Sequence
from uuid import uuid4

from appdirs import AppDirs

from . import __about__
from .events.app import CoroutineDone, ExitRequested


class App:
    def __init__(self) -> None:
        self.appdirs = AppDirs(appname=__about__.__pkg_name__, roaming=True)

        self.backend = None

        self.loop        = asyncio.get_event_loop()
        self.loop_thread = Thread(target=self._loop_starter)
        self.loop_thread.start()


    def start(self, cli_flags: Sequence[str] = ()) -> bool:
        debug = False

        if "-d" in cli_flags or "--debug" in cli_flags:
            self._run_in_loop(self._exit_on_app_file_change())
            debug = True

        from .backend import Backend
        self.backend = Backend(app=self)  # type: ignore

        return debug


    async def _exit_on_app_file_change(self) -> None:
        from watchgod import awatch

        async for _ in awatch(Path(__file__).resolve().parent):
            ExitRequested(231)


    def _loop_starter(self) -> None:
        asyncio.set_event_loop(self.loop)
        self.loop.run_forever()


    def _run_in_loop(self, coro: Coroutine) -> Future:
        return asyncio.run_coroutine_threadsafe(coro, self.loop)


    def call_backend_coro(self,
                          name:   str,
                          args:   Optional[List[str]]      = None,
                          kwargs: Optional[Dict[str, Any]] = None) -> str:
        # To be used from QML

        coro = getattr(self.backend, name)(*args or [], **kwargs or {})
        uuid = str(uuid4())

        self._run_in_loop(coro).add_done_callback(
            lambda future: CoroutineDone(uuid=uuid, result=future.result())
        )
        return uuid


    def pdb(self, additional_data: Sequence = ()) -> None:
        # pylint: disable=all
        ad = additional_data
        ba = self.backend
        cl = self.backend.clients  # type: ignore
        tcl = lambda user: cl[f"@test_{user}:matrix.org"]

        import json
        jd = lambda obj: print(json.dumps(obj, indent=4, ensure_ascii=False))

        import pdb
        pdb.set_trace()


APP = App()
