# Copyright 2018 miruka
# This file is part of harmonyqt, licensed under GPLv3.

import hashlib
import json
import os
import platform
import threading
from typing import Dict, Optional

from atomicfile import AtomicFile
from PyQt5.QtCore import (
    QObject, QStandardPaths, pyqtProperty, pyqtSignal, pyqtSlot
)

from harmonyqml import __about__

from .backend import Backend
from .client import Client

AccountConfig = Dict[str, Dict[str, str]]

_CONFIG_LOCK   = threading.Lock()
# _CRYPT_DB_LOCK = threading.Lock()


class ClientManager(QObject):
    clientAdded   = pyqtSignal(Client)
    clientDeleted = pyqtSignal(str)


    def __init__(self, backend: Backend) -> None:
        super().__init__(backend)
        self.backend = backend
        self._clients: Dict[str, Client] = {}


    def __repr__(self) -> str:
        return f"{type(self).__name__}(clients={self.clients!r})"


    @pyqtProperty("QVariantMap", constant=True)
    def clients(self):
        return self._clients


    @pyqtSlot()
    def configLoad(self) -> None:
        for user_id, info in self.configAccounts().items():
            client = Client(self, info["hostname"], user_id)
            client.resumeSession(user_id, info["token"], info["device_id"])\
                  .add_done_callback(lambda _, c=client: self._on_connected(c))


    @pyqtSlot(str, str, str)
    @pyqtSlot(str, str, str)
    def new(self, hostname: str, username: str, password: str,
            device_id: str = "") -> None:

        client = Client(self, hostname, username, device_id)
        client.login(password, self.defaultDeviceName)\
              .add_done_callback(lambda _: self._on_connected(client))


    def _on_connected(self, client: Client) -> None:
        self.clients[client.userID] = client
        self.clientAdded.emit(client)


    @pyqtSlot(str)
    def delete(self, user_id: str) -> None:
        client = self.clients.pop(user_id, None)
        if client:
            self.clientDeleted.emit(user_id)
            client.logout()


    @pyqtProperty(str, constant=True)
    def defaultDeviceName(self) -> str:  # pylint: disable=no-self-use
        os_ = f" on {platform.system()}".rstrip()
        os_ = f"{os_} {platform.release()}".rstrip() if os_ != " on" else ""
        return f"{__about__.__pretty_name__}{os}"


    # Standard file paths

    @staticmethod
    def _get_standard_path(kind:            QStandardPaths.StandardLocation,
                           file:            str,
                           initial_content: Optional[str] = None) -> str:
        relative_path = file.replace("/", os.sep)

        path = QStandardPaths.locate(kind, relative_path)
        if path:
            return path

        base_dir = QStandardPaths.writableLocation(kind)
        path     = f"{base_dir}{os.sep}{relative_path}"
        os.makedirs(os.path.split(path)[0], exist_ok=True)

        if initial_content is not None:
            with AtomicFile(path, "w") as new:
                new.write(initial_content)

        return path


    def getAccountConfigPath(self) -> str:
        return self._get_standard_path(
            QStandardPaths.AppConfigLocation, "accounts.json", "[]"
        )


    def getCryptDBPath(self, user_id: str) -> str:
        safe_filename = hashlib.md5(user_id.encode("utf-8")).hexdigest()
        return self._get_standard_path(
            QStandardPaths.AppDataLocation, f"encryption/{safe_filename}.db"
        )


    # Config file operations

    def configAccounts(self) -> AccountConfig:
        with open(self.getAccountConfigPath(), "r") as file:
            return json.loads(file.read().strip()) or {}


    @pyqtSlot(Client)
    def configAdd(self, client: Client) -> None:
        self._write_config({
            **self.configAccounts(),
            **{client.userID: {
                "hostname": client.nio.host,
                "token": client.nio.access_token,
                "device_id": client.nio.device_id,
            }}
        })


    @pyqtSlot(str)
    def configDelete(self, user_id: str) -> None:
        self._write_config({
            uid: info
            for uid, info in self.configAccounts().items() if uid != user_id
        })


    def _write_config(self, accounts: AccountConfig) -> None:
        js = json.dumps(accounts, indent=4, ensure_ascii=False, sort_keys=True)

        with _CONFIG_LOCK:
            with AtomicFile(self.getAccountConfigPath(), "w") as new:
                new.write(js)
