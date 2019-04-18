# Copyright 2019 miruka
# This file is part of harmonyqml, licensed under GPLv3.

import hashlib
from typing import Dict, Set

from PyQt5.QtCore import QObject, pyqtProperty, pyqtSlot

from .html_filter import HtmlFilter
from .model.items import User
from .model.qml_models import QMLModels


class Backend(QObject):
    def __init__(self) -> None:
        super().__init__()
        self.past_tokens:        Dict[str, str] = {}
        self.fully_loaded_rooms: Set[str]       = set()

        from .client_manager import ClientManager
        self._client_manager: ClientManager = ClientManager(self)
        self._models:         QMLModels     = QMLModels()
        self._html_filter:    HtmlFilter    = HtmlFilter()
        # a = self._client_manager; m = self._models

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


    @pyqtSlot(str, result="QVariantMap")
    def getUser(self, user_id: str) -> Dict[str, str]:
        for client in self.clientManager.clients.values():
            for room in client.nio.rooms.values():

                name = room.user_name(user_id)
                if name:
                    return User(user_id=user_id, display_name=name)._asdict()

        return User(user_id=user_id, display_name=user_id)._asdict()


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
