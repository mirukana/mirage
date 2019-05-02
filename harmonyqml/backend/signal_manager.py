# Copyright 2019 miruka
# This file is part of harmonyqml, licensed under GPLv3.

from threading import Lock
from typing import Any, Deque, Dict, List, Optional

from PyQt5.QtCore import QDateTime, QObject, pyqtBoundSignal

import nio
from nio.rooms import MatrixRoom

from .backend import Backend
from .client import Client
from .model.items import Account, Room, RoomCategory, RoomEvent
from .model.list_model import ListModel

Inviter   = Optional[Dict[str, str]]
LeftEvent = Optional[Dict[str, str]]


class SignalManager(QObject):
    _lock: Lock = Lock()

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

        self.backend.models.accounts.append(Account(
            userId         = client.userId,
            roomCategories = ListModel([
                RoomCategory("Invites", ListModel()),
                RoomCategory("Rooms", ListModel()),
                RoomCategory("Left", ListModel()),
            ]),
            displayName = self.backend.getUserDisplayName(client.userId),
        ))


    def onClientDeleted(self, user_id: str) -> None:
        del self.backend.models.accounts[user_id]


    def connectClient(self, client: Client) -> None:
        for name in dir(client):
            attr = getattr(client, name)

            if isinstance(attr, pyqtBoundSignal):
                def onSignal(*args, name=name) -> None:
                    func = getattr(self, f"on{name[0].upper()}{name[1:]}")
                    func(client, *args)

                attr.connect(onSignal)


    @staticmethod
    def _get_room_displayname(nio_room: MatrixRoom) -> Optional[str]:
        name = nio_room.name or nio_room.canonical_alias
        if name:
            return name

        name = nio_room.group_name()
        return None if name == "Empty room?" else name


    def onRoomInvited(self,
                      client:  Client,
                      room_id: str,
                      inviter: Inviter = None) -> None:

        nio_room   = client.nio.invited_rooms[room_id]
        categories = self.backend.models.accounts[client.userId].roomCategories

        categories["Rooms"].rooms.pop(room_id, None)
        categories["Left"].rooms.pop(room_id, None)

        categories["Invites"].rooms.upsert(room_id, Room(
            roomId      = room_id,
            displayName = self._get_room_displayname(nio_room),
            topic       = nio_room.topic,
            inviter     = inviter,
        ), 0, 0)


    def onRoomJoined(self, client: Client, room_id: str) -> None:
        nio_room   = client.nio.rooms[room_id]
        categories = self.backend.models.accounts[client.userId].roomCategories

        categories["Invites"].rooms.pop(room_id, None)
        categories["Left"].rooms.pop(room_id, None)

        categories["Rooms"].rooms.upsert(room_id, Room(
            roomId      = room_id,
            displayName = self._get_room_displayname(nio_room),
            topic       = nio_room.topic,
        ), 0, 0)


    def onRoomLeft(self,
                   client:     Client,
                   room_id:    str,
                   left_event: LeftEvent = None) -> None:
        categories = self.backend.models.accounts[client.userId].roomCategories

        previous = categories["Rooms"].rooms.pop(room_id, None)
        previous = previous or categories["Invites"].rooms.pop(room_id, None)
        previous = previous or categories["Left"].rooms.get(room_id, None)

        categories["Left"].rooms.upsert(0, Room(
            roomId      = room_id,
            displayName = previous.displayName if previous else None,
            topic       = previous.topic if previous else None,
            leftEvent   = left_event,
        ), 0, 0)

    def onRoomSyncPrevBatchTokenReceived(self,
                                         _:       Client,
                                         room_id: str,
                                         token:   str) -> None:

        if room_id not in self.backend.past_tokens:
            self.backend.past_tokens[room_id] = token


    def onRoomPastPrevBatchTokenReceived(self,
                                         _:       Client,
                                         room_id: str,
                                         token:   str) -> None:

        if self.backend.past_tokens[room_id] == token:
            self.backend.fully_loaded_rooms.add(room_id)

        self.backend.past_tokens[room_id] = token


    def onRoomEventReceived(self,
                            _:  Client,
                            room_id: str,
                            etype:   str,
                            edict:   Dict[str, Any]) -> None:
        def process() -> None:
            # Prevent duplicate events in models due to multiple accounts
            if edict["event_id"] in self.last_room_events:
                return

            self.last_room_events.appendleft(edict["event_id"])

            model     = self.backend.models.roomEvents[room_id]
            date_time = QDateTime\
                        .fromMSecsSinceEpoch(edict["server_timestamp"])
            new_event = RoomEvent(type=etype, dateTime=date_time, dict=edict)

            event_is_our_profile_changed = (
                etype == "RoomMemberEvent" and
                edict.get("sender") in self.backend.clientManager.clients and
                ((edict.get("content") or {}).get("membership") ==
                 (edict.get("prev_content") or {}).get("membership"))
            )

            if event_is_our_profile_changed:
                return

            if etype == "RoomCreateEvent":
                self.backend.fully_loaded_rooms.add(room_id)

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

        with self._lock:
            process()
            # self._move_room(client.userId, room_id)


    def onRoomTypingUsersUpdated(self,
                                 client:  Client,
                                 room_id: str,
                                 users:   List[str]) -> None:
        categories = self.backend.models.accounts[client.userId].roomCategories
        for categ in categories:
            try:
                categ.rooms[room_id].typingUsers = users
                break
            except ValueError:
                pass


    def onMessageAboutToBeSent(self,
                               client:  Client,
                               room_id: str,
                               content: Dict[str, str]) -> None:

        with self._lock:
            model     = self.backend.models.roomEvents[room_id]
            nio_event = nio.events.RoomMessage.parse_event({
                "event_id":         "",
                "sender":           client.userId,
                "origin_server_ts": QDateTime.currentMSecsSinceEpoch(),
                "content":          content,
            })
            event = RoomEvent(
                type        = type(nio_event).__name__,
                dict        = nio_event.__dict__,
                isLocalEcho = True,
            )
            model.insert(0, event)
            self._events_in_transfer += 1

            # self._move_room(client.userId, room_id)


    def onRoomAboutToBeForgotten(self, client: Client, room_id: str) -> None:
        categories = self.backend.models.accounts[client.userId].roomCategories

        for categ in categories:
            categ.rooms.pop(room_id, None)

        self.backend.models.roomEvents[room_id].clear()
