# Copyright 2019 miruka
# This file is part of harmonyqml, licensed under GPLv3.

import hashlib
from typing import Any, DefaultDict, Dict, NamedTuple, Optional

from PyQt5.QtCore import QDateTime, QObject, pyqtProperty, pyqtSlot

from .enums import Activity, MessageKind, Presence
from .list_model import ListModel, _QtListModel


class User(NamedTuple):
    user_id:      str
    display_name: str
    avatar_url:   Optional[str] = None


class Room(NamedTuple):
    account_id:                 str
    room_id:                    str
    display_name:               str
    subtitle:                   str           = ""
    unread_messages:            int           = 0
    presence:                   Presence      = Presence.none
    activity:                   Activity      = Activity.none
    last_activity_timestamp_ms: Optional[int] = None
    avatar_url:                 Optional[str] = None


class Message(NamedTuple):
    sender_id:     str
    date_time:     QDateTime
    content:       str
    kind:          MessageKind   = MessageKind.text
    sender_avatar: Optional[str] = None


class Backend(QObject):
    def __init__(self) -> None:
        super().__init__()
        self._known_users: Dict[str, User] = {}

        self.rooms:    ListModel                   = ListModel()
        self.messages: DefaultDict[str, ListModel] = DefaultDict(ListModel)


    @pyqtProperty(_QtListModel, constant=True)
    def roomsModel(self) -> _QtListModel:
        return self.rooms.qt_model


    @pyqtProperty("QVariantMap", constant=True)
    def messagesModel(self) -> Dict[str, _QtListModel]:
        return {room_id: l.qt_model for room_id, l in self.messages.items()}


    @pyqtSlot(str, str, str)
    def sendMessage(self, sender_id: str, room_id: str, markdown: str) -> None:
        self.localEcho(sender_id, room_id, markdown)
        self.sendToServer(sender_id, room_id, markdown)


    def localEcho(self, sender_id: str, room_id: str, html: str) -> None:
        self.messages[room_id].append(Message(
            sender_id, QDateTime.currentDateTime(), html,
        ))


    def sendToServer(self, sender_id: str, room_id: str, html: str) -> None:
        pass


    @pyqtSlot(str, result="QVariantMap")
    def getUser(self, user_id: str) -> Dict[str, Any]:
        try:
            return self._known_users[user_id]._asdict()
        except KeyError:
            name = user_id.lstrip("@").split(":")[0].capitalize()
            user = User(user_id, name)
            self._known_users[user_id] = user
            return user._asdict()


    @pyqtSlot(str, result=float)
    def hueFromString(self, string: str) -> float:
        # pylint: disable=no-self-use
        md5 = hashlib.md5(bytes(string, "utf-8")).hexdigest()
        return float("0.%s" % int(md5[-10:], 16))
