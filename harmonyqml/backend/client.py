# Copyright 2019 miruka
# This file is part of harmonyqml, licensed under GPLv3.

import functools
import logging
import sys
import traceback
from concurrent.futures import Future, ThreadPoolExecutor
from threading import Event, currentThread
from typing import Callable, DefaultDict

from PyQt5.QtCore import QObject, pyqtProperty, pyqtSignal, pyqtSlot

import nio
import nio.responses as nr

from .network_manager import NetworkManager

# One pool per hostname/remote server;
# multiple Client for different accounts on the same server can exist.
_POOLS: DefaultDict[str, ThreadPoolExecutor] = \
    DefaultDict(lambda: ThreadPoolExecutor(max_workers=6))


def futurize(func: Callable) -> Callable:
    @functools.wraps(func)
    def wrapper(*args, **kwargs) -> Future:
        def run_and_catch_errs():
            # Without this, exceptions are silently ignored
            try:
                func(*args, **kwargs)
            except Exception:
                traceback.print_exc()
                logging.error("Exiting %s due to exception.", currentThread())
                sys.exit(1)

        return args[0].pool.submit(run_and_catch_errs)  # args[0] = self
    return wrapper


class Client(QObject):
    roomInvited                    = pyqtSignal(str)
    roomJoined                     = pyqtSignal(str)
    roomLeft                       = pyqtSignal(str)
    roomSyncPrevBatchTokenReceived = pyqtSignal(str, str)
    roomPastPrevBatchTokenReceived = pyqtSignal(str, str)
    roomEventReceived              = pyqtSignal(str, str, dict)
    roomTypingUsersUpdated         = pyqtSignal(str, list)
    messageAboutToBeSent           = pyqtSignal(str, dict)


    def __init__(self,
                 manager,
                 hostname:  str,
                 username:  str,
                 device_id: str = "") -> None:
        super().__init__(manager)
        self.manager = manager

        host, *port    = hostname.split(":")
        self.host: str = host
        self.port: int = int(port[0]) if port else 443

        self.pool: ThreadPoolExecutor = _POOLS[self.host]

        self.nio: nio.client.HttpClient = \
            nio.client.HttpClient(self.host, username, device_id)

        # Since nio clients can't handle more than one talk operation
        # at a time, this one is used exclusively to poll the sync API
        self.nio_sync: nio.client.HttpClient = \
            nio.client.HttpClient(self.host, username, device_id)

        self.net      = NetworkManager(self.host, self.port, self.nio)
        self.net_sync = NetworkManager(self.host, self.port, self.nio_sync)

        self._loading: bool = False

        self._stop_sync: Event = Event()


    def __repr__(self) -> str:
        return "%s(host=%r, port=%r, user_id=%r)" % \
            (type(self).__name__, self.host, self.port, self.userID)


    @pyqtProperty(str, constant=True)
    def userID(self) -> str:
        return self.nio.user_id


    @pyqtSlot(str)
    @pyqtSlot(str, str)
    @futurize
    def login(self, password: str, device_name: str = "") -> None:
        self.net.write(self.nio.connect())
        response = self.net.talk(self.nio.login, password, device_name)

        self.net_sync.write(self.nio_sync.connect())
        self.nio_sync.receive_response(response)
        self.startSyncing()


    @pyqtSlot(str, str, str)
    @futurize
    def resumeSession(self, user_id: str, token: str, device_id: str
                     ) -> None:
        self.net.write(self.nio.connect())
        response = nr.LoginResponse(user_id, device_id, token)
        self.nio.receive_response(response)

        self.net_sync.write(self.nio_sync.connect())
        self.nio_sync.receive_response(response)
        self.startSyncing()


    @pyqtSlot()
    @futurize
    def logout(self) -> None:
        self._stop_sync.set()
        self.net.write(self.nio.disconnect())
        self.net_sync.write(self.nio_sync.disconnect())


    @pyqtSlot()
    @futurize
    def startSyncing(self) -> None:
        while True:
            self._on_sync(self.net_sync.talk(
                self.nio_sync.sync, timeout=10_000
            ))

            if self._stop_sync.is_set():
                self._stop_sync.clear()
                break


    def _on_sync(self, response: nr.SyncResponse) -> None:
        self.nio.receive_response(response)

        for room_id in response.rooms.invite:
            self.roomInvited.emit(room_id)

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
                if isinstance(ev, nr.TypingNoticeEvent):
                    self.roomTypingUsersUpdated.emit(room_id, ev.users)
                else:
                    print("ephemeral event: ", ev)

        for room_id in response.rooms.leave:
            self.roomLeft.emit(room_id)


    @futurize
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


    def _on_past_events(self, room_id: str, response: nr.RoomMessagesResponse
                       ) -> None:
        self.roomPastPrevBatchTokenReceived.emit(room_id, response.end)

        for ev in response.chunk:
            self.roomEventReceived.emit(
                room_id, type(ev).__name__, ev.__dict__
            )


    @pyqtSlot(str, str)
    @futurize
    def sendMarkdown(self, room_id: str, text: str) -> None:
        html = self.manager.backend.htmlFilter.fromMarkdown(text)
        content = {
            "body": text,
            "formatted_body": html,
            "format": "org.matrix.custom.html",
            "msgtype": "m.text",
        }
        self.messageAboutToBeSent.emit(room_id, content)

        self.net.talk(
            self.nio.room_send,
            room_id      = room_id,
            message_type = "m.room.message",
            content      = content,
        )
