# Copyright 2019 miruka
# This file is part of harmonyqml, licensed under GPLv3.

from typing import Optional

from PyQt5.QtCore import QObject

from .backend import Backend
from .client import Client
from .model.items import Room, User


class SignalManager(QObject):
    def __init__(self, backend: Backend) -> None:
        super().__init__()
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
        for sig_name in ("roomInvited", "roomJoined", "roomLeft"):
            sig    = getattr(client, sig_name)
            on_sig = getattr(self, f"on{sig_name[0].upper()}{sig_name[1:]}")
            sig.connect(lambda room_id, o=on_sig, c=client: o(c, room_id))


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
