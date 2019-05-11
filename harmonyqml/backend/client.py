# Copyright 2019 miruka
# This file is part of harmonyqml, licensed under GPLv3.

import logging as log
import time
from concurrent.futures import ThreadPoolExecutor
from threading import Event
from typing import DefaultDict, Tuple

from PyQt5.QtCore import (
    QObject, QStandardPaths, pyqtProperty, pyqtSignal, pyqtSlot
)

import nio

from .model.items import Trust
from .network_manager import NetworkManager
from .pyqt_future import PyQtFuture, futurize


class Client(QObject):
    roomInvited = pyqtSignal([str, dict], [str])
    roomJoined  = pyqtSignal(str)
    roomLeft    = pyqtSignal([str, dict], [str])

    roomAboutToBeForgotten = pyqtSignal(str)

    roomSyncPrevBatchTokenReceived = pyqtSignal(str, str)
    roomPastPrevBatchTokenReceived = pyqtSignal(str, str)
    roomEventReceived              = pyqtSignal(str, str, dict)
    roomTypingMembersUpdated       = pyqtSignal(str, list)

    messageAboutToBeSent = pyqtSignal(str, dict)

    deviceIsPresent = pyqtSignal(str, str, str)
    deviceIsDeleted = pyqtSignal(str, str)


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


    @futurize(max_running=1, discard_if_max_running=True, pyqt=False)
    def uploadE2EKeys(self) -> None:
        self.net.talk(self.nio.keys_upload)


    def queryE2EKeys(self) -> None:
        self._on_query_e2e_keys(self.net.talk(self.nio.keys_query))


    def _on_query_e2e_keys(self, response: nio.KeysQueryResponse) -> None:
        for user_id, device_dict in response.device_keys.items():
            for device_id, payload in device_dict.items():
                if device_id == self.nio.device_id:
                    continue

                ed25519_key = payload["keys"][f"ed25519:{device_id}"]
                self.deviceIsPresent.emit(user_id, device_id, ed25519_key)

            for device_id, device in self.nio.device_store[user_id].items():
                if device.deleted:
                    self.deviceIsDeleted.emit(user_id, device_id)


    def claimE2EKeysForRoom(self, room_id: str) -> None:
        self.net.talk(self.nio.keys_claim, room_id)


    def shareRoomE2ESession(self,
                            room_id: str,
                            ignore_missing_sessions: bool = False) -> None:
        self.net.talk(
            self.nio.share_group_session,
            room_id                 = room_id,
            ignore_missing_sessions = ignore_missing_sessions,
        )


    def getDeviceTrust(self, device: nio.crypto.OlmDevice) -> Trust:
        olm = self.nio.olm
        return (
            Trust.trusted     if olm.is_device_verified(device)    else
            Trust.blacklisted if olm.is_device_blacklisted(device) else
            Trust.undecided
        )


    @pyqtSlot(str, result="QVariant")
    @pyqtSlot(str, str, result="QVariant")
    @futurize()
    def login(self, password: str, device_name: str = "") -> "Client":
        # Main nio client will receive the response here
        response = self.net.talk(self.nio.login, password, device_name)
        # Now, receive it with the sync nio client too:
        self.nio_sync.receive_response(response)
        return self


    @pyqtSlot(str, str, str, result="QVariant")
    @futurize()
    def resumeSession(self, user_id: str, token: str, device_id: str
                     ) -> "Client":
        response = nio.LoginResponse(user_id, device_id, token)
        self.nio.receive_response(response)
        self.nio_sync.receive_response(response)
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
            self.uploadE2EKeys()

        if self.nio.should_query_keys:
            self.queryE2EKeys()

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
                    self.roomTypingMembersUpdated.emit(room_id, ev.users)
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


    @futurize(max_running=1, discard_if_max_running=True)
    def loadPastEvents(self, room_id: str, start_token: str, limit: int = 100
                      ) -> None:
        # From QML, use Backend.loastPastEvents instead

        self._on_past_events(
            room_id,
            self.net.talk(
                self.nio.room_messages, room_id, start=start_token, limit=limit
            )
        )


    def _on_past_events(self, room_id: str, response: nio.RoomMessagesResponse
                       ) -> None:
        self.roomPastPrevBatchTokenReceived.emit(room_id, response.end)

        for ev in response.chunk:
            self.roomEventReceived.emit(
                room_id, type(ev).__name__, ev.__dict__
            )


    @pyqtSlot(str, bool)
    @futurize(max_running=1, discard_if_max_running=True)
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
    def sendMarkdown(self, room_id: str, text: str) -> PyQtFuture:
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
        #
        # send() only takes the room_id argument explicitely because
        # of consider_args=True: This means the max number of messages being
        # sent at a time is one per room at a time.
        @futurize(max_running=1, consider_args=True)
        def send(self, room_id: str) -> PyQtFuture:
            talk = lambda: self.net.talk(
                self.nio.room_send,
                room_id      = room_id,
                message_type = "m.room.message",
                content      = content,
            )

            try:
                log.debug("Try sending message %r to %r", content, room_id)
                return talk()
            except nio.GroupEncryptionError as err:
                log.warning(err)
                try:
                    self.shareRoomE2ESession(room_id)
                except nio.EncryptionError as err:
                    log.warning(err)
                    self.claimE2EKeysForRoom(room_id)
                    self.shareRoomE2ESession(room_id,
                                             ignore_missing_sessions=True)

                log.debug("Final try to send %r to %r", content, room_id)
                return talk()

        return send(self, room_id)


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
        response = self.net.talk(self.nio.room_forget, room_id=room_id)
        self.nio.invalidate_outbound_session(room_id)
        return response


    @pyqtSlot(str, result=bool)
    def roomHasUnknownDevices(self, room_id: str) -> bool:
        return self.nio.room_contains_unverified(room_id)
