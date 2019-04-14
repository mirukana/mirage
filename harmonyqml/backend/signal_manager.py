# Copyright 2019 miruka
# This file is part of harmonyqml, licensed under GPLv3.

from typing import Any, Dict, Optional

from PyQt5.QtCore import QDateTime, QObject, pyqtBoundSignal

from .backend import Backend
from .client import Client
from .model.items import Room, RoomEvent, User


class SignalManager(QObject):
    def __init__(self, backend: Backend) -> None:
        super().__init__(parent=backend)
        self.backend = backend

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
        model     = self.backend.models.roomEvents[room_id]
        date_time = QDateTime.fromMSecsSinceEpoch(edict["server_timestamp"])
        new_event = RoomEvent(type=etype, date_time=date_time, dict=edict)

        # Insert event in model at the right position, based on timestamps
        # to keep them sorted by date of arrival.
        # Iterate in reverse, since a new event is more likely to be appended,
        # but events can arrive out of order.
        if not model or model[-1].date_time < new_event.date_time:
            model.append(new_event)
        else:
            for i, event in enumerate(reversed(model)):
                if event.date_time < new_event.date_time:
                    model.insert(-i, new_event)
                    break
            else:
                model.insert(0, new_event)
