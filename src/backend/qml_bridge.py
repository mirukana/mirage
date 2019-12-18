import asyncio
import logging as log
import signal
import traceback
from concurrent.futures import Future
from operator import attrgetter
from threading import Thread
from typing import Coroutine, Sequence

from .backend import Backend
from .pyotherside_events import CoroutineDone

try:
    import uvloop
except ModuleNotFoundError:
    log.warning("uvloop module not found, using slower default asyncio loop")
else:
    uvloop.install()


class QmlBridge:
    def __init__(self) -> None:
        self.backend = Backend()

        self.loop = asyncio.get_event_loop()
        Thread(target=self._start_loop_in_thread).start()


    def _start_loop_in_thread(self) -> None:
        asyncio.set_event_loop(self.loop)
        self.loop.run_forever()


    def _run_coro_in_loop(self, coro: Coroutine) -> Future:
        return asyncio.run_coroutine_threadsafe(coro, self.loop)


    def _call_coro(self, coro: Coroutine, uuid: str) -> Future:
        def on_done(future: Future) -> None:
            result = exception = trace = None

            try:
                result = future.result()
            except Exception as err:
                exception = err
                trace     = traceback.format_exc().rstrip()

            CoroutineDone(uuid, result, exception, trace)

        future = self._run_coro_in_loop(coro)
        future.add_done_callback(on_done)
        return future


    def call_backend_coro(
        self, name: str, uuid: str, args: Sequence[str] = (),
    ) -> Future:
        return self._call_coro(attrgetter(name)(self.backend)(*args), uuid)


    def call_client_coro(
        self, user_id: str, name: str, uuid: str, args: Sequence[str] = (),
    ) -> Future:

        client = self.backend.clients[user_id]
        return self._call_coro(attrgetter(name)(client)(*args), uuid)


    def pdb(self, additional_data: Sequence = ()) -> None:
        ad  = additional_data              # noqa
        rc  = self._run_coro_in_loop       # noqa
        ba  = self.backend                 # noqa
        mo  = self.backend.models          # noqa
        cl  = self.backend.clients
        gcl = lambda user: cl[f"@{user}:matrix.org"]  # noqa

        from .models.items import Account, Room, Member, Event, Device  # noqa

        p = print  # pdb's `p` doesn't print a class's __str__  # noqa
        try:
            from pprintpp import pprint as pp  # noqa
        except ModuleNotFoundError:
            pass

        log.info("\n=> Run `socat readline tcp:127.0.0.1:4444` in a terminal "
                 "to connect to pdb.")
        import remote_pdb
        remote_pdb.RemotePdb("127.0.0.1", 4444).set_trace()


# Make CTRL-C work again
signal.signal(signal.SIGINT, signal.SIG_DFL)

BRIDGE = QmlBridge()
