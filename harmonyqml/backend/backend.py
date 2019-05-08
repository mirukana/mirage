# Copyright 2019 miruka
# This file is part of harmonyqml, licensed under GPLv3.

import os
from concurrent.futures import ThreadPoolExecutor
from typing import Deque, Dict, Optional, Sequence, Set

from atomicfile import AtomicFile
from PyQt5.QtCore import QObject, QStandardPaths, pyqtProperty, pyqtSlot

from .html_filter import HtmlFilter
from .model import ListModel, ListModelMap
from .pyqt_future import futurize


class Backend(QObject):
    def __init__(self, parent: QObject) -> None:
        super().__init__(parent)
        self.pool: ThreadPoolExecutor = ThreadPoolExecutor(max_workers=6)

        self._queried_displaynames: Dict[str, str] = {}

        self.past_tokens:        Dict[str, str] = {}
        self.fully_loaded_rooms: Set[str]       = set()

        self._html_filter: HtmlFilter = HtmlFilter(self)

        from .client_manager import ClientManager
        self._client_manager: ClientManager = ClientManager(self)

        self._accounts:    ListModel    = ListModel(parent=parent)
        self._room_events: ListModelMap = ListModelMap(Deque, parent)

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
    def signals(self):
        return self._signal_manager


    @pyqtSlot(str, result="QVariant")
    @pyqtSlot(str, bool, result="QVariant")
    @futurize(max_running=1, consider_args=True)
    def getUserDisplayName(self, user_id: str, can_block: bool = True) -> str:
        if user_id in self._queried_displaynames:
            return self._queried_displaynames[user_id]

        for client in self.clients.values():
            for room in client.nio.rooms.values():
                displayname = room.user_name(user_id)

                if displayname:
                    return displayname

        return self._query_user_displayname(user_id) if can_block else user_id


    def _query_user_displayname(self, user_id: str) -> str:
        client      = next(iter(self.clients.values()))
        response    = client.net.talk(client.nio.get_displayname, user_id)
        displayname = getattr(response, "displayname", "") or user_id

        self._queried_displaynames[user_id] = displayname
        return displayname


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

        tcl = lambda user: cl[f"@test_{user}:matrix.org"]

        import pdb
        from PyQt5.QtCore import pyqtRemoveInputHook
        pyqtRemoveInputHook()
        pdb.set_trace()
