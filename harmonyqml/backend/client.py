# Copyright 2019 miruka
# This file is part of harmonyqml, licensed under GPLv3.

import time
from concurrent.futures import ThreadPoolExecutor
from threading import Event
from typing import DefaultDict, Tuple

from PyQt5.QtCore import (
    QObject, QStandardPaths, pyqtProperty, pyqtSignal, pyqtSlot
)

import nio

from .network_manager import NetworkManager
from .pyqt_future import futurize


class Client(QObject):
    roomInvited = pyqtSignal([str, dict], [str])
    roomJoined  = pyqtSignal(str)
    roomLeft    = pyqtSignal([str, dict], [str])

    roomAboutToBeForgotten = pyqtSignal(str)

    roomSyncPrevBatchTokenReceived = pyqtSignal(str, str)
    roomPastPrevBatchTokenReceived = pyqtSignal(str, str)
    roomEventReceived              = pyqtSignal(str, str, dict)
    roomTypingUsersUpdated         = pyqtSignal(str, list)

    messageAboutToBeSent = pyqtSignal(str, dict)


    def __init__(self,
                 manager,
                 hostname:         str,
                 username:         str,
                 device_id:        str = "") -> None:
        super().__init__(manager)
        self.manager = manager

        host, *port    = hostname.split(":")
        self.host: str = host
        self.port: int = int(port[0]) if port else 443

        self.pool: ThreadPoolExecutor = ThreadPoolExecutor(6)

        store_path = self.manager.backend.getDir(
            QStandardPaths.AppDataLocation
        )

        self.nio: nio.client.HttpClient = nio.client.HttpClient(
            self.host, username, device_id, store_path=store_path
        )

        # Since nio clients can't handle more than one talk operation
        # at a time, this one is used exclusively to poll the sync API
        self.nio_sync: nio.client.HttpClient = nio.client.HttpClient(
            self.host, username, device_id, store_path=store_path
        )

        self.net      = NetworkManager(self.host, self.port, self.nio)
        self.net_sync = NetworkManager(self.host, self.port, self.nio_sync)

        self._loading: bool = False

        self._stop_sync: Event = Event()

        # {room_id: (was_typing, at_timestamp_secs)}
        self._last_typing_set: DefaultDict[str, Tuple[bool, float]] = \
            DefaultDict(lambda: (False, 0))


    def __repr__(self) -> str:
        return "%s(host=%r, port=%r, user_id=%r)" % \
            (type(self).__name__, self.host, self.port, self.userId)


    @pyqtProperty(str, constant=True)
    def userId(self) -> str:
        return self.nio.user_id


    @futurize(pyqt=False)
    def _keys_upload(self) -> None:
        print("uploading key")
        self.net.talk(self.nio.keys_upload)


    @futurize(max_instances=1, pyqt=False)
    def _keys_query(self) -> None:
        print("querying keys")
        self.net.talk(self.nio.keys_query)


    @pyqtSlot(str, result="QVariant")
    @pyqtSlot(str, str, result="QVariant")
    @futurize()
    def login(self, password: str, device_name: str = "") -> "Client":
        response = self.net.talk(self.nio.login, password, device_name)
        self.nio_sync.receive_response(response)

        if not self.nio.olm_account_shared:
            self._keys_upload()

        return self


    @pyqtSlot(str, str, str, result="QVariant")
    @futurize()
    def resumeSession(self, user_id: str, token: str, device_id: str
                     ) -> "Client":
        response = nio.LoginResponse(user_id, device_id, token)
        self.nio.receive_response(response)
        self.nio_sync.receive_response(response)

        if not self.nio.olm_account_shared:
            self._keys_upload()

        return self


    @pyqtSlot(result="QVariant")
    @futurize()
    def logout(self) -> "Client":
        self._stop_sync.set()
        self.net.http_disconnect()
        self.net_sync.http_disconnect()
        return self


    @futurize(pyqt=False)
    def startSyncing(self) -> None:
        while True:
            try:
                response = self.net_sync.talk(self.nio_sync.sync, timeout=8000)
            except nio.LocalProtocolError:  # logout occured
                pass
            else:
                self._on_sync(response)

            if self._stop_sync.is_set():
                self._stop_sync.clear()
                break


    def _on_sync(self, response: nio.SyncResponse) -> None:
        self.nio.receive_response(response)

        if self.nio.should_upload_keys:
            self._keys_upload()

        if self.nio.should_query_keys:
            self._keys_query()

        for room_id, room_info in response.rooms.invite.items():
            for ev in room_info.invite_state:
                member_ev = isinstance(ev, nio.InviteMemberEvent)

                if member_ev and ev.content["membership"] == "join":
                    self.roomInvited.emit(room_id, ev.content)
                    break
            else:
                self.roomInvited[str].emit(room_id)

        for room_id, room_info in response.rooms.join.items():
            self.roomJoined.emit(room_id)

            self.roomSyncPrevBatchTokenReceived.emit(
                room_id, room_info.timeline.prev_batch
            )

            for ev in room_info.timeline.events:
                self.roomEventReceived.emit(
                    room_id, type(ev).__name__, ev.__dict__
                )

            for ev in room_info.ephemeral:
                if isinstance(ev, nio.TypingNoticeEvent):
                    self.roomTypingUsersUpdated.emit(room_id, ev.users)
                else:
                    print("ephemeral event: ", ev)

        for room_id, room_info in response.rooms.leave.items():
            for ev in room_info.timeline.events:
                member_ev = isinstance(ev, nio.RoomMemberEvent)

                if member_ev and ev.content["membership"] in ("leave", "ban"):
                    self.roomLeft.emit(room_id, ev.__dict__)
                    break
            else:
                self.roomLeft[str].emit(room_id)


    @futurize()
    def loadPastEvents(self, room_id: str, start_token: str, limit: int = 100
                      ) -> None:
        # From QML, use Backend.loastPastEvents instead

        if self._loading:
            return
        self._loading = True

        self._on_past_events(
            room_id,
            self.net.talk(
                self.nio.room_messages, room_id, start=start_token, limit=limit
            )
        )
        self._loading = False


    def _on_past_events(self, room_id: str, response: nio.RoomMessagesResponse
                       ) -> None:
        self.roomPastPrevBatchTokenReceived.emit(room_id, response.end)

        for ev in response.chunk:
            self.roomEventReceived.emit(
                room_id, type(ev).__name__, ev.__dict__
            )


    @pyqtSlot(str, bool)
    @futurize(max_instances=1)
    def setTypingState(self, room_id: str, typing: bool) -> None:
        set_for_secs        = 5
        last_set, last_time = self._last_typing_set[room_id]

        if not typing and last_set is False:
            return

        if typing and time.time() - last_time < set_for_secs - 1:
            return

        self._last_typing_set[room_id] = (typing, time.time())

        self.net.talk(
            self.nio.room_typing,
            room_id        = room_id,
            typing_state   = typing,
            timeout        = set_for_secs * 1000,
        )


    @pyqtSlot(str, str)
    def sendMarkdown(self, room_id: str, text: str) -> None:
        html = self.manager.backend.htmlFilter.fromMarkdown(text)
        content = {
            "body": text,
            "formatted_body": html,
            "format": "org.matrix.custom.html",
            "msgtype": "m.text",
        }
        self.messageAboutToBeSent.emit(room_id, content)

        # If the thread pool workers are all occupied, and @futurize
        # wrapped sendMarkdown, the messageAboutToBeSent signal neccessary
        # for local echoes would not be sent until a thread is free.
        @futurize()
        def send(self):
            return self.net.talk(
                self.nio.room_send,
                room_id      = room_id,
                message_type = "m.room.message",
                content      = content,
            )

        return send(self)


    @pyqtSlot(str, result="QVariant")
    @futurize()
    def joinRoom(self, room_id: str) -> None:
        return self.net.talk(self.nio.join, room_id=room_id)


    @pyqtSlot(str, result="QVariant")
    @futurize()
    def leaveRoom(self, room_id: str) -> None:
        return self.net.talk(self.nio.room_leave, room_id=room_id)


    @pyqtSlot(str, result="QVariant")
    @futurize()
    def forgetRoom(self, room_id: str) -> None:
        self.roomAboutToBeForgotten.emit(room_id)
        return self.net.talk(self.nio.room_forget, room_id=room_id)
