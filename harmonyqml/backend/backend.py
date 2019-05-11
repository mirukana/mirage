# Copyright 2019 miruka
# This file is part of harmonyqml, licensed under GPLv3.

import os
import random
from concurrent.futures import ThreadPoolExecutor
from typing import Deque, Dict, Optional, Sequence, Set, Tuple

from atomicfile import AtomicFile
from PyQt5.QtCore import QObject, QStandardPaths, pyqtProperty, pyqtSlot

from .html_filter import HtmlFilter
from .model import ListModel, ListModelMap
from .model.items import User
from .network_manager import NioErrorResponse
from .pyqt_future import futurize


class Backend(QObject):
    def __init__(self, parent: QObject) -> None:
        super().__init__(parent)
        self.pool: ThreadPoolExecutor = ThreadPoolExecutor(max_workers=6)

        self.past_tokens:        Dict[str, str] = {}
        self.fully_loaded_rooms: Set[str]       = set()

        self._html_filter: HtmlFilter = HtmlFilter(self)

        from .client_manager import ClientManager
        self._client_manager: ClientManager = ClientManager(self)

        self._accounts: ListModel = ListModel(parent=parent)

        self._room_events: ListModelMap = ListModelMap(
            container = Deque,
            parent    = self
        )

        self._users: ListModel = ListModel(
            default_factory = self._query_user,
            parent          = self
        )

        from .signal_manager import SignalManager
        self._signal_manager: SignalManager = SignalManager(self)

        self.clients.configLoad()


    @pyqtProperty("QVariant", constant=True)
    def htmlFilter(self):
        return self._html_filter

    @pyqtProperty("QVariant", constant=True)
    def clients(self):
        return self._client_manager

    @pyqtProperty("QVariant", constant=True)
    def accounts(self):
        return self._accounts

    @pyqtProperty("QVariant", constant=True)
    def roomEvents(self):
        return self._room_events

    @pyqtProperty("QVariant", constant=True)
    def users(self):
        return self._users

    @pyqtProperty("QVariant", constant=True)
    def signals(self):
        return self._signal_manager


    def _query_user(self, user_id: str) -> User:
        client = random.choice(tuple(self.clients.values()))  # nosec

        @futurize(running_value=user_id)
        def get_displayname(self) -> str:
            print("querying", user_id)
            try:
                response = client.net.talk(client.nio.get_displayname, user_id)
                return response.displayname or user_id
            except NioErrorResponse:
                return user_id

        return User(
            userId      = user_id,
            displayName = get_displayname(self),
            devices     = ListModel(),
        )


    @pyqtSlot(str, result=float)
    def hueFromString(self, string: str) -> float:
        # pylint:disable=no-self-use
        return sum((ord(char) * 99 for char in string)) % 360 / 360


    @pyqtSlot(str)
    @pyqtSlot(str, int)
    def loadPastEvents(self, room_id: str, limit: int = 100) -> None:
        if not room_id in self.past_tokens:
            return  # Initial sync not done yet

        if room_id in self.fully_loaded_rooms:
            return

        for client in self.clients.values():
            if room_id in client.nio.rooms:
                client.loadPastEvents(
                    room_id, self.past_tokens[room_id], limit
                )
                break


    @pyqtSlot(str)
    def setRoomFilter(self, pattern: str) -> None:
        for account in self.accounts:
            for categ in account.roomCategories:
                categ.sortedRooms.filter = pattern


    @staticmethod
    def getDir(standard_dir: QStandardPaths.StandardLocation) -> str:
        path = QStandardPaths.writableLocation(standard_dir)
        os.makedirs(path, exist_ok=True)
        return path


    def getFile(self,
                standard_dir:       QStandardPaths.StandardLocation,
                relative_file_path: str,
                initial_content:    Optional[str] = None) -> str:

        relative_file_path = relative_file_path.replace("/", os.sep)

        path = QStandardPaths.locate(standard_dir, relative_file_path)
        if path:
            return path

        path = os.path.join(self.getDir(standard_dir), relative_file_path)

        if initial_content is not None:
            with AtomicFile(path, "w") as new:
                new.write(initial_content)

        return path


    @pyqtSlot()
    @pyqtSlot(list)
    def pdb(self, additional_data: Sequence = ()) -> None:
        # pylint: disable=all
        ad = additional_data
        cl = self.clients
        ac = self.accounts
        re = self.roomEvents
        us = self.users

        tcl = lambda user: cl[f"@test_{user}:matrix.org"]

        import json
        jd = lambda obj: print(json.dumps(obj, indent=4, ensure_ascii=False))

        import pdb
        from PyQt5.QtCore import pyqtRemoveInputHook
        pyqtRemoveInputHook()
        pdb.set_trace()
