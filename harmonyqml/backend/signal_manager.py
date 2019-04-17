# Copyright 2019 miruka
# This file is part of harmonyqml, licensed under GPLv3.

from threading import Lock
from typing import Any, Deque, Dict, List, Optional

from PyQt5.QtCore import QDateTime, QObject, pyqtBoundSignal

from .backend import Backend
from .client import Client
from .model.items import Room, RoomEvent, User


class SignalManager(QObject):
    _duplicate_check_lock: Lock = Lock()

    def __init__(self, backend: Backend) -> None:
        super().__init__(parent=backend)
        self.backend = backend

        self.last_room_events: Deque[str] = Deque(maxlen=1000)

        cm = self.backend.clientManager
        cm.clientAdded.connect(self.onClientAdded)
        cm.clientDeleted.connect(self.onClientDeleted)


    def onClientAdded(self, client: Client) -> None:
        self.connectClient(client)
        self.backend.models.accounts.append(User(
            user_id      = client.userID,
            display_name = client.userID.lstrip("@").split(":")[0],
        ))


    def onClientDeleted(self, user_id: str) -> None:
        accs = self.backend.models.accounts
        del accs[accs.indexWhere("user_id", user_id)]


    def connectClient(self, client: Client) -> None:
        for name in dir(client):
            attr = getattr(client, name)

            if isinstance(attr, pyqtBoundSignal):
                def onSignal(*args, name=name) -> None:
                    func = getattr(self, f"on{name[0].upper()}{name[1:]}")
                    func(client, *args)

                attr.connect(onSignal)


    def onRoomInvited(self, client: Client, room_id: str) -> None:
        pass  # TODO


    def onRoomJoined(self, client: Client, room_id: str) -> None:
        model = self.backend.models.rooms[client.userID]
        room  = client.nio.rooms[room_id]

        def group_name() -> Optional[str]:
            name = room.group_name()
            return None if name == "Empty room?" else name

        item = Room(
            room_id      = room_id,
            display_name = room.name or room.canonical_alias or group_name(),
            description  = getattr(room, "topic", ""),  # FIXME: outside init
        )

        try:
            index = model.indexWhere("room_id", room_id)
        except ValueError:
            model.append(item)
        else:
            model[index] = item


    def onRoomLeft(self, client: Client, room_id: str) -> None:
        rooms = self.backend.models.rooms[client.userID]
        del rooms[rooms.indexWhere("room_id", room_id)]


    def onRoomEventReceived(
            self, _: Client, room_id: str, etype: str, edict: Dict[str, Any]
        ) -> None:

        # Prevent duplicate events in models due to multiple accounts
        with self._duplicate_check_lock:
            if edict["event_id"] in self.last_room_events:
                return

            self.last_room_events.appendleft(edict["event_id"])

        model     = self.backend.models.roomEvents[room_id]
        date_time = QDateTime.fromMSecsSinceEpoch(edict["server_timestamp"])
        new_event = RoomEvent(type=etype, date_time=date_time, dict=edict)

        # Model is sorted from newest to oldest message
        insert_at = None
        for i, event in enumerate(model):
            if new_event.date_time > event.date_time:
                insert_at = i
                break

        if insert_at is None:
            model.append(new_event)
        else:
            model.insert(insert_at, new_event)


    def onRoomTypingUsersUpdated(
            self, client: Client, room_id: str, users: List[str]
        ) -> None:

        rooms = self.backend.models.rooms[client.userID]
        rooms[rooms.indexWhere("room_id", room_id)].typing_users = users
