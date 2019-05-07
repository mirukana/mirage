# Copyright 2018 miruka
# This file is part of harmonyqt, licensed under GPLv3.

import json
import os
import platform
import threading
from collections.abc import Mapping
from typing import Dict, Iterable, Optional

from atomicfile import AtomicFile
from PyQt5.QtCore import (
    QObject, QStandardPaths, pyqtProperty, pyqtSignal, pyqtSlot
)

from harmonyqml import __about__

from .backend import Backend
from .client import Client

AccountConfig = Dict[str, Dict[str, str]]

_CONFIG_LOCK = threading.Lock()


class _ClientManagerMeta(type(QObject), type(Mapping)):  # type: ignore
    pass


class ClientManager(QObject, Mapping, metaclass=_ClientManagerMeta):
    clientAdded        = pyqtSignal(Client)
    clientDeleted      = pyqtSignal(str)
    clientCountChanged = pyqtSignal(int)


    def __init__(self, backend: Backend) -> None:
        super().__init__(backend)
        self.backend = backend
        self._clients: Dict[str, Client] = {}

        func = lambda: self.clientCountChanged.emit(len(self))
        self.clientAdded.connect(func)
        self.clientDeleted.connect(func)


    def __repr__(self) -> str:
        return f"{type(self).__name__}(clients={self._clients!r})"


    def __getitem__(self, user_id: str) -> Client:
        return self.get(user_id)


    def __len__(self) -> int:
        return self.count


    def __iter__(self):
        return iter(self._clients)


    @pyqtSlot(str, result="QVariant")
    def get(self, key: str) -> Client:
        return self._clients[key]


    @pyqtProperty(int, notify=clientCountChanged)
    def count(self):
        return len(self._clients)


    @pyqtSlot()
    def configLoad(self) -> None:
        for user_id, info in self.configAccounts().items():
            client = Client(self, info["hostname"], user_id)
            client.resumeSession(user_id, info["token"], info["device_id"])\
                  .add_done_callback(lambda _, c=client: self._on_connected(c))


    @pyqtSlot(str, str, str, result="QVariant")
    @pyqtSlot(str, str, str, str, result="QVariant")
    def new(self, hostname: str, username: str, password: str,
            device_id: str = "") -> None:

        client = Client(self, hostname, username, device_id)
        future = client.login(password, self.defaultDeviceName)
        future.add_done_callback(lambda _: self._on_connected(client))
        return future


    def _on_connected(self, client: Client) -> None:
        self._clients[client.userId] = client
        self.clientAdded.emit(client)
        client.startSyncing()


    @pyqtSlot(str)
    def remove(self, user_id: str) -> None:
        client = self._clients.pop(user_id, None)
        if client:
            self.clientDeleted.emit(user_id)
            client.logout()


    @pyqtSlot()
    def removeAll(self) -> None:
        for user_id in self._clients.copy():
            self.remove(user_id)


    @pyqtProperty(str, constant=True)
    def defaultDeviceName(self) -> str:  # pylint: disable=no-self-use
        os_ = f" on {platform.system()}".rstrip()
        os_ = f"{os_} {platform.release()}".rstrip() if os_ != " on" else ""
        return f"{__about__.__pretty_name__}{os}"


    # Standard file paths

    def getAccountConfigPath(self) -> str:
        return self.backend.getPath(
            QStandardPaths.AppConfigLocation, "accounts.json", "[]"
        )


    # Config file operations

    def configAccounts(self) -> AccountConfig:
        with open(self.getAccountConfigPath(), "r") as file:
            return json.loads(file.read().strip()) or {}


    @pyqtSlot("QVariant")
    def remember(self, client: Client) -> None:
        self._write_config({
            **self.configAccounts(),
            **{client.userId: {
                "hostname": client.nio.host,
                "token": client.nio.access_token,
                "device_id": client.nio.device_id,
            }}
        })


    @pyqtSlot(str)
    def forget(self, user_id: str) -> None:
        self._write_config({
            uid: info
            for uid, info in self.configAccounts().items() if uid != user_id
        })


    def _write_config(self, accounts: AccountConfig) -> None:
        js = json.dumps(accounts, indent=4, ensure_ascii=False, sort_keys=True)

        with _CONFIG_LOCK:
            with AtomicFile(self.getAccountConfigPath(), "w") as new:
                new.write(js)
