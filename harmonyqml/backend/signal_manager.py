# Copyright 2019 miruka
# This file is part of harmonyqml, licensed under GPLv3.

from threading import Lock
from typing import Any, Deque, Dict, List, Optional

from PyQt5.QtCore import QDateTime, QObject, pyqtBoundSignal, pyqtSignal

import nio
from nio.rooms import MatrixRoom

from .backend import Backend
from .client import Client
from .model.items import (
    Account, Device, ListModel, Room, RoomCategory, RoomEvent
)
from .model.sort_filter_proxy import SortFilterProxy

Inviter   = Optional[Dict[str, str]]
LeftEvent = Optional[Dict[str, str]]


class SignalManager(QObject):
    roomCategoryChanged = pyqtSignal(str, str, str, str)

    _lock: Lock = Lock()

    def __init__(self, backend: Backend) -> None:
        super().__init__(parent=backend)
        self.backend = backend

        self.last_room_events:    Deque[str] = Deque(maxlen=1000)
        self._events_in_transfer: int        = 0

        self.backend.clients.clientAdded.connect(self.onClientAdded)
        self.backend.clients.clientDeleted.connect(self.onClientDeleted)


    def onClientAdded(self, client: Client) -> None:
        # Build an Account item for the Backend.accounts model
        room_categories_kwargs: List[Dict[str, Any]] = [
            {"name": "Invites", "rooms": ListModel()},
            {"name": "Rooms", "rooms": ListModel()},
            {"name": "Left", "rooms": ListModel()},
        ]

        for i, _ in enumerate(room_categories_kwargs):
            proxy = SortFilterProxy(
                source_model = room_categories_kwargs[i]["rooms"],
                sort_by_role = "lastEventDateTime",
                ascending    = False,
            )
            room_categories_kwargs[i]["sortedRooms"] = proxy

        self.backend.accounts.append(Account(
            userId         = client.userId,
            roomCategories = ListModel([
                RoomCategory(**kws) for kws in room_categories_kwargs
            ]),
            displayName = self.backend.getUserDisplayName(client.userId),
        ))

        # Upload our E2E keys to the matrix server if needed
        if not client.nio.olm_account_shared:
            client.uploadE2EKeys()

        # Add our devices to the Backend.devices model
        store = client.nio.device_store

        for user_id in store.users:
            self.backend.devices[user_id].clear()
            self.backend.devices[user_id].extend([
                Device(
                    deviceId   = dev.id,
                    ed25519Key = dev.ed25519,
                    trust      = client.getDeviceTrust(dev),
                ) for dev in store.active_user_devices(user_id)
            ])

        # Finally, connect all client signals
        self.connectClient(client)


    def onClientDeleted(self, user_id: str) -> None:
        del self.backend.accounts[user_id]


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
        categories = self.backend.accounts[client.userId].roomCategories

        previous_room = categories["Rooms"].rooms.pop(room_id, None)
        previous_left = categories["Left"].rooms.pop(room_id, None)

        categories["Invites"].rooms.upsert(
            where_main_key_is = room_id,
            update_with       = Room(
                roomId            = room_id,
                displayName       = self._get_room_displayname(nio_room),
                topic             = nio_room.topic,
                inviter           = inviter,
                lastEventDateTime = QDateTime.currentDateTime(),  # FIXME
            ),
            new_index_if_insert = 0,
            ignore_roles        = ("typingUsers"),
        )

        signal = self.roomCategoryChanged
        if previous_room:
            signal.emit(client.userId, room_id, "Rooms", "Invites")
        elif previous_left:
            signal.emit(client.userId, room_id, "Left", "Invites")


    def onRoomJoined(self, client: Client, room_id: str) -> None:
        nio_room   = client.nio.rooms[room_id]
        categories = self.backend.accounts[client.userId].roomCategories

        previous_invite = categories["Invites"].rooms.pop(room_id, None)
        previous_left   = categories["Left"].rooms.pop(room_id, None)

        categories["Rooms"].rooms.upsert(
            where_main_key_is = room_id,
            update_with       = Room(
                roomId      = room_id,
                displayName = self._get_room_displayname(nio_room),
                topic       = nio_room.topic,
            ),
            new_index_if_insert = 0,
            ignore_roles        = ("typingUsers", "lastEventDateTime"),
        )

        signal = self.roomCategoryChanged
        if previous_invite:
            signal.emit(client.userId, room_id, "Invites", "Rooms")
        elif previous_left:
            signal.emit(client.userId, room_id, "Left", "Rooms")


    def onRoomLeft(self,
                   client:     Client,
                   room_id:    str,
                   left_event: LeftEvent = None) -> None:
        categories = self.backend.accounts[client.userId].roomCategories

        previous_room   = categories["Rooms"].rooms.pop(room_id, None)
        previous_invite = categories["Invites"].rooms.pop(room_id, None)
        previous        = previous_room or previous_invite or \
                          categories["Left"].rooms.get(room_id, None)

        left_time = left_event.get("server_timestamp") if left_event else None

        categories["Left"].rooms.upsert(
            where_main_key_is = room_id,
            update_with     = Room(
                roomId      = room_id,
                displayName = previous.displayName if previous else None,
                topic       = previous.topic       if previous else None,
                leftEvent   = left_event,
                lastEventDateTime = (
                    QDateTime.fromMSecsSinceEpoch(left_time)
                    if left_time else QDateTime.currentDateTime()
                ),
            ),
            new_index_if_insert = 0,
            ignore_roles        = ("typingUsers", "lastEventDateTime"),
        )

        signal = self.roomCategoryChanged
        if previous_room:
            signal.emit(client.userId, room_id, "Rooms", "Left")
        elif previous_invite:
            signal.emit(client.userId, room_id, "Invites", "Left")



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


    def _set_room_last_event(self, user_id: str, room_id: str, event: RoomEvent
                            ) -> None:
        for categ in self.backend.accounts[user_id].roomCategories:
            if room_id in categ.rooms:
                # Use setProperty to make sure to trigger model changed signals
                categ.rooms.setProperty(
                    room_id, "lastEventDateTime", event.dateTime
                )


    def onRoomEventReceived(self,
                            client:  Client,
                            room_id: str,
                            etype:   str,
                            edict:   Dict[str, Any]) -> None:

        def process() -> Optional[RoomEvent]:
            # Prevent duplicate events in models due to multiple accounts
            if edict["event_id"] in self.last_room_events:
                return None

            self.last_room_events.appendleft(edict["event_id"])

            model     = self.backend.roomEvents[room_id]
            date_time = QDateTime\
                        .fromMSecsSinceEpoch(edict["server_timestamp"])
            new_event = RoomEvent(type=etype, dateTime=date_time, dict=edict)

            event_is_our_profile_changed = (
                etype == "RoomMemberEvent" and
                edict.get("sender") in self.backend.clients and
                ((edict.get("content") or {}).get("membership") ==
                 (edict.get("prev_content") or {}).get("membership"))
            )

            if event_is_our_profile_changed:
                return None

            if etype == "RoomCreateEvent":
                self.backend.fully_loaded_rooms.add(room_id)

            if self._events_in_transfer:
                local_echoes_met: int           = 0
                update_at:        Optional[int] = None

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
                    return new_event

            for i, event in enumerate(model):
                if event.isLocalEcho:
                    continue

                # Model is sorted from newest to oldest message
                if new_event.dateTime > event.dateTime:
                    model.insert(i, new_event)
                    return new_event

            model.append(new_event)
            return new_event

        with self._lock:
            new_event = process()
            if new_event:
                self._set_room_last_event(client.userId, room_id, new_event)


    def onRoomTypingUsersUpdated(self,
                                 client:  Client,
                                 room_id: str,
                                 users:   List[str]) -> None:
        categories = self.backend.accounts[client.userId].roomCategories
        for categ in categories:
            try:
                categ.rooms.setProperty(room_id, "typingUsers", users)
                break
            except ValueError:
                pass


    def onMessageAboutToBeSent(self,
                               client:  Client,
                               room_id: str,
                               content: Dict[str, str]) -> None:

        with self._lock:
            model     = self.backend.roomEvents[room_id]
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

            self._set_room_last_event(client.userId, room_id, event)


    def onRoomAboutToBeForgotten(self, client: Client, room_id: str) -> None:
        categories = self.backend.accounts[client.userId].roomCategories

        for categ in categories:
            categ.rooms.pop(room_id, None)

        self.backend.roomEvents[room_id].clear()


    def onDeviceIsPresent(self,
                          client:      Client,
                          user_id:     str,
                          device_id:   str,
                          ed25519_key: str) -> None:
        nio_device = client.nio.device_store[user_id][device_id]

        self.backend.devices[user_id].upsert(
            where_main_key_is = device_id,
            update_with       = Device(
                deviceId   = device_id,
                ed25519Key = ed25519_key,
                trust      = client.getDeviceTrust(nio_device),
            )
        )


    def onDeviceIsDeleted(self, _: Client, user_id: str, device_id: str
                         ) -> None:
        self.backend.devices[user_id].pop(device_id, None)
