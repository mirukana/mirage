# Copyright 2019 miruka
# This file is part of harmonyqml, licensed under GPLv3.

import hashlib
from concurrent.futures import ThreadPoolExecutor
from typing import Dict, Sequence, Set

from PyQt5.QtCore import QObject, pyqtProperty, pyqtSlot

from .html_filter import HtmlFilter
from .model.qml_models import QMLModels
from .pyqt_future import futurize


class Backend(QObject):
    def __init__(self) -> None:
        super().__init__()
        self.pool: ThreadPoolExecutor = ThreadPoolExecutor(max_workers=6)

        self._queried_displaynames: Dict[str, str] = {}

        self.past_tokens:        Dict[str, str] = {}
        self.fully_loaded_rooms: Set[str]       = set()

        from .client_manager import ClientManager
        self._client_manager: ClientManager = ClientManager(self)
        self._models:         QMLModels     = QMLModels()
        self._html_filter:    HtmlFilter    = HtmlFilter()

        from .signal_manager import SignalManager
        self._signal_manager: SignalManager = SignalManager(self)

        self.clientManager.configLoad()


    @pyqtProperty("QVariant", constant=True)
    def clientManager(self):
        return self._client_manager

    @pyqtProperty("QVariant", constant=True)
    def models(self):
        return self._models

    @pyqtProperty("QVariant", constant=True)
    def htmlFilter(self):
        return self._html_filter


    @pyqtSlot(str, result="QVariant")
    @pyqtSlot(str, bool, result="QVariant")
    @futurize()
    def getUserDisplayName(self, user_id: str, can_block: bool = True) -> str:
        if user_id in self._queried_displaynames:
            return self._queried_displaynames[user_id]

        for client in self.clientManager.clients.values():
            for room in client.nio.rooms.values():
                displayname = room.user_name(user_id)

                if displayname:
                    return displayname

        return self._query_user_displayname(user_id) if can_block else user_id


    def _query_user_displayname(self, user_id: str) -> str:
        client      = next(iter(self.clientManager.clients.values()))
        response    = client.net.talk(client.nio.get_displayname, user_id)
        displayname = getattr(response, "displayname", "") or user_id

        self._queried_displaynames[user_id] = displayname
        return displayname


    @pyqtSlot(str, result=float)
    def hueFromString(self, string: str) -> float:
      # pylint:disable=no-self-use
        md5 = hashlib.md5(bytes(string, "utf-8")).hexdigest()
        return float("0.%s" % int(md5[-10:], 16))


    @pyqtSlot(str)
    @pyqtSlot(str, int)
    def loadPastEvents(self, room_id: str, limit: int = 100) -> None:
        if not room_id in self.past_tokens:
            return  # Initial sync not done yet

        if room_id in self.fully_loaded_rooms:
            return

        for client in self.clientManager.clients.values():
            if room_id in client.nio.rooms:
                client.loadPastEvents(
                    room_id, self.past_tokens[room_id], limit
                )
                break
        else:
            raise ValueError(f"Room not found in any client: {room_id}")


    @pyqtSlot()
    @pyqtSlot(list)
    def pdb(self, additional_data: Sequence = ()) -> None:
        # pylint: disable=all
        ad = additional_data
        cm = self.clientManager
        cl = self.clientManager.clients
        m  = self.models

        tcl = lambda user: cl[f"@test_{user}:matrix.org"]

        import pdb
        from PyQt5.QtCore import pyqtRemoveInputHook
        pyqtRemoveInputHook()
        pdb.set_trace()
