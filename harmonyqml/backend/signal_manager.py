# Copyright 2019 miruka
# This file is part of harmonyqml, licensed under GPLv3.

from threading import Lock
from typing import Any, Deque, Dict, List, Optional

from PyQt5.QtCore import QDateTime, QObject, pyqtBoundSignal

import nio
from nio.rooms import MatrixRoom

from .backend import Backend
from .client import Client
from .model.items import Room, RoomEvent, User

Inviter   = Optional[Dict[str, str]]
LeftEvent = Optional[Dict[str, str]]


class SignalManager(QObject):
    _event_handling_lock: Lock = Lock()

    def __init__(self, backend: Backend) -> None:
        super().__init__(parent=backend)
        self.backend = backend

        self.last_room_events:    Deque[str] = Deque(maxlen=1000)
        self._events_in_transfer: int        = 0

        cm = self.backend.clientManager
        cm.clientAdded.connect(self.onClientAdded)
        cm.clientDeleted.connect(self.onClientDeleted)


    def onClientAdded(self, client: Client) -> None:
        self.connectClient(client)
        self.backend.models.accounts.append(User(
            userId      = client.userId,
            displayName = self.backend.getUserDisplayName(client.userId),
        ))


    def onClientDeleted(self, user_id: str) -> None:
        accs = self.backend.models.accounts
        del accs[accs.indexWhere("userId", user_id)]


    def connectClient(self, client: Client) -> None:
        for name in dir(client):
            attr = getattr(client, name)

            if isinstance(attr, pyqtBoundSignal):
                def onSignal(*args, name=name) -> None:
                    func = getattr(self, f"on{name[0].upper()}{name[1:]}")
                    func(client, *args)

                attr.connect(onSignal)


    def onRoomInvited(self,
                      client:  Client,
                      room_id: str,
                      inviter: Inviter = None) -> None:

        self._add_room(client, room_id, client.nio.invited_rooms[room_id],
                       "Invites", inviter=inviter)


    def onRoomJoined(self, client: Client, room_id: str) -> None:
        self._add_room(client, room_id, client.nio.rooms[room_id], "Rooms")


    def onRoomLeft(self,
                   client:     Client,
                   room_id:    str,
                   left_event: LeftEvent = None) -> None:

        self._add_room(client, room_id, client.nio.rooms.get(room_id), "Left",
                       left_event=left_event)


    def _add_room(self,
                  client:     Client,
                  room_id:    str,
                  room:       MatrixRoom,
                  category:   str,
                  inviter:    Inviter   = None,
                  left_event: LeftEvent = None) -> None:

        assert not (inviter and left_event)

        model     = self.backend.models.rooms[client.userId]
        no_update = []

        def get_displayname() -> Optional[str]:
            if not room:
                no_update.append("displayName")
                return room_id

            name = room.name or room.canonical_alias
            if name:
                return name

            name = room.group_name()
            return None if name == "Empty room?" else name

        item = Room(
            roomId      = room_id,
            category    = category,
            displayName = get_displayname(),
            topic       = room.topic if room else "",
            inviter     = inviter,
            leftEvent   = left_event,
            no_update   = no_update,
        )

        model.updateOrAppendWhere("roomId", room_id, item)


    def onRoomSyncPrevBatchTokenReceived(
            self, _: Client, room_id: str, token: str
        ) -> None:

        if room_id not in self.backend.past_tokens:
            self.backend.past_tokens[room_id] = token


    def onRoomPastPrevBatchTokenReceived(
            self, _: Client, room_id: str, token: str
        ) -> None:

        if self.backend.past_tokens[room_id] == token:
            self.backend.fully_loaded_rooms.add(room_id)

        self.backend.past_tokens[room_id] = token


    def onRoomEventReceived(
            self, _: Client, room_id: str, etype: str, edict: Dict[str, Any]
        ) -> None:

        with self._event_handling_lock:
            # Prevent duplicate events in models due to multiple accounts
            if edict["event_id"] in self.last_room_events:
                return

            self.last_room_events.appendleft(edict["event_id"])

            model     = self.backend.models.roomEvents[room_id]
            date_time = QDateTime\
                        .fromMSecsSinceEpoch(edict["server_timestamp"])
            new_event = RoomEvent(type=etype, dateTime=date_time, dict=edict)

            if self._events_in_transfer:
                local_echoes_met: int           = 0
                update_at:       Optional[int] = None

                # Find if any locally echoed event corresponds to new_event
                for i, event in enumerate(model):
                    if not event.isLocalEcho:
                        continue

                    sb     = (event.dict["sender"], event.dict["body"])
                    new_sb = (new_event.dict["sender"], new_event.dict["body"])

                    if sb == new_sb:
                        # The oldest matching local echo shall be replaced
                        update_at = max(update_at or 0, i)

                    local_echoes_met += 1
                    if local_echoes_met >= self._events_in_transfer:
                        break

                if update_at is not None:
                    model.update(update_at, new_event)
                    self._events_in_transfer -= 1
                    return

            for i, event in enumerate(model):
                if event.isLocalEcho:
                    continue

                # Model is sorted from newest to oldest message
                if new_event.dateTime > event.dateTime:
                    model.insert(i, new_event)
                    return

            model.append(new_event)


    def onRoomTypingUsersUpdated(
            self, client: Client, room_id: str, users: List[str]
        ) -> None:

        rooms = self.backend.models.rooms[client.userId]
        rooms[rooms.indexWhere("roomId", room_id)].typingUsers = users


    def onMessageAboutToBeSent(
            self, client: Client, room_id: str, content: Dict[str, str]
        ) -> None:
        with self._event_handling_lock:
            timestamp = QDateTime.currentMSecsSinceEpoch()
            model     = self.backend.models.roomEvents[room_id]
            nio_event = nio.events.RoomMessage.parse_event({
                "event_id":         "",
                "sender":           client.userId,
                "origin_server_ts": timestamp,
                "content":          content,
            })
            event = RoomEvent(
                type        = type(nio_event).__name__,
                dateTime    = QDateTime.fromMSecsSinceEpoch(timestamp),
                dict        = nio_event.__dict__,
                isLocalEcho = True,
            )
            model.insert(0, event)
            self._events_in_transfer += 1
