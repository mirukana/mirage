# Copyright 2019 miruka
# This file is part of harmonyqml, licensed under GPLv3.

from concurrent.futures import ThreadPoolExecutor
from typing import Deque, Dict, Sequence, Set

from PyQt5.QtCore import QObject, pyqtProperty, pyqtSlot

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


    @pyqtSlot(str, result="QVariant")
    @pyqtSlot(str, bool, result="QVariant")
    @futurize()
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


    @pyqtSlot()
    @pyqtSlot(list)
    def pdb(self, additional_data: Sequence = ()) -> None:
        # pylint: disable=all
        a = additional_data
        c = self.clients
        m = self.models

        tcl = lambda user: c[f"@test_{user}:matrix.org"]

        import pdb
        from PyQt5.QtCore import pyqtRemoveInputHook
        pyqtRemoveInputHook()
        pdb.set_trace()
