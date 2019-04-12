# Copyright 2019 miruka
# This file is part of harmonyqml, licensed under GPLv3.

import functools
from concurrent.futures import Future, ThreadPoolExecutor
from threading import Event
from typing import Callable, DefaultDict, Dict

from PyQt5.QtCore import QObject, pyqtSlot

import nio
import nio.responses as nr

from .model.items import User

# One pool per hostname/remote server;
# multiple Client for different accounts on the same server can exist.
_POOLS: DefaultDict[str, ThreadPoolExecutor] = \
    DefaultDict(lambda: ThreadPoolExecutor(max_workers=6))


def futurize(func: Callable) -> Callable:
    @functools.wraps(func)
    def wrapper(*args, **kwargs) -> Future:
        return args[0].pool.submit(func, *args, **kwargs)  # args[0] = self
    return wrapper


class Client(QObject):
    def __init__(self, hostname: str, username: str, device_id: str = ""
                ) -> None:
        super().__init__()

        host, *port    = hostname.split(":")
        self.host: str = host
        self.port: int = int(port[0]) if port else 443

        self.nio: nio.client.HttpClient = \
            nio.client.HttpClient(self.host, username, device_id)

        self.pool: ThreadPoolExecutor = _POOLS[self.host]

        from .network_manager import NetworkManager
        self.net: NetworkManager = NetworkManager(self)

        self._stop_sync: Event = Event()


    def __repr__(self) -> str:
        return "%s(host=%r, port=%r, user_id=%r)" % \
            (type(self).__name__, self.host, self.port, self.nio.user_id)


    @pyqtSlot(str)
    @pyqtSlot(str, str)
    @futurize
    def login(self, password: str, device_name: str = "") -> None:
        self.net.write(self.nio.connect())
        self.net.talk(self.nio.login, password, device_name)
        self.startSyncing()


    @pyqtSlot(str, str, str)
    @futurize
    def resumeSession(self, user_id: str, token: str, device_id: str
                     ) -> None:
        self.net.write(self.nio.connect())
        response = nr.LoginResponse(user_id, device_id, token)
        self.nio.receive_response(response)
        self.startSyncing()


    @pyqtSlot()
    @futurize
    def logout(self) -> None:
        self._stop_sync.set()
        self.net.write(self.nio.disconnect())


    @pyqtSlot()
    @futurize
    def startSyncing(self) -> None:
        while True:
            self.net.talk(self.nio.sync, timeout=10)

            if self._stop_sync.is_set():
                self._stop_sync.clear()
                break


    @pyqtSlot(str, str, result="QVariantMap")
    def getUser(self, room_id: str, user_id: str) -> Dict[str, str]:
        try:
            name = self.nio.rooms[room_id].user_name(user_id)
        except KeyError:
            name = None

        return User(
            user_id      = user_id,
            display_name = name or user_id,
        )._asdict()
