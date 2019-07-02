import asyncio
import inspect
import logging as log
import platform
from contextlib import suppress
from datetime import datetime
from types import ModuleType
from typing import Dict, Optional, Type

import nio
from nio.rooms import MatrixRoom

from . import __about__
from .events import rooms, users
from .events.rooms_timeline import EventType, HtmlMessageReceived
from .html_filter import HTML_FILTER


class MatrixClient(nio.AsyncClient):
    def __init__(self,
                 user:       str,
                 homeserver: str           = "https://matrix.org",
                 device_id:  Optional[str] = None) -> None:

        # TODO: ensure homeserver starts with a scheme://
        self.sync_task: Optional[asyncio.Future] = None
        super().__init__(homeserver=homeserver, user=user, device_id=device_id)

        self.connect_callbacks()


    def __repr__(self) -> str:
        return "%s(user_id=%r, homeserver=%r, device_id=%r)" % (
            type(self).__name__, self.user_id, self.homeserver, self.device_id
        )


    @staticmethod
    def _classes_defined_in(module: ModuleType) -> Dict[str, Type]:
        return {
            m[0]: m[1] for m in inspect.getmembers(module, inspect.isclass)
            if not m[0].startswith("_") and
            m[1].__module__.startswith(module.__name__)
        }


    def connect_callbacks(self) -> None:
        for name, class_ in self._classes_defined_in(nio.responses).items():
            with suppress(AttributeError):
                self.add_response_callback(getattr(self, f"on{name}"), class_)

        for name, class_ in self._classes_defined_in(nio.events).items():
            with suppress(AttributeError):
                self.add_event_callback(getattr(self, f"on{name}"), class_)


    async def start_syncing(self) -> None:
        self.sync_task = asyncio.ensure_future(
            self.sync_forever(timeout=10_000)
        )

        def callback(task):
            raise task.exception()

        self.sync_task.add_done_callback(callback)


    @property
    def default_device_name(self) -> str:
        os_ = f" on {platform.system()}".rstrip()
        os_ = f"{os_} {platform.release()}".rstrip() if os_ != " on" else ""
        return f"{__about__.__pretty_name__}{os_}"


    async def login(self, password: str, device_name: str = "") -> None:
        response = await super().login(
            password, device_name or self.default_device_name
        )

        if isinstance(response, nio.LoginError):
            print(response)
        else:
            await self.start_syncing()


    async def resume(self, user_id: str, token: str, device_id: str) -> None:
        response = nio.LoginResponse(user_id, device_id, token)
        await self.receive_response(response)
        await self.start_syncing()


    async def logout(self) -> None:
        if self.sync_task:
            self.sync_task.cancel()
            with suppress(asyncio.CancelledError):
                await self.sync_task

        await self.close()


    async def request_user_update_event(self, user_id: str) -> None:
        response = await self.get_profile(user_id)

        if isinstance(response, nio.ProfileGetError):
            log.warning("Error getting profile for %r: %s", user_id, response)

        users.UserUpdated(
            user_id        = user_id,
            display_name   = getattr(response, "displayname", None),
            avatar_url     = getattr(response, "avatar_url", None),
            status_message = None,  # TODO
        )


    # Callbacks for nio responses

    @staticmethod
    def _get_room_name(room: MatrixRoom) -> Optional[str]:
        # FIXME: reimplanted because of nio's non-standard room.display_name
        name = room.name or room.canonical_alias
        if name:
            return name

        name = room.group_name()
        return None if name == "Empty room?" else name


    async def onSyncResponse(self, resp: nio.SyncResponse) -> None:
        for room_id, _ in resp.rooms.invite.items():
            room: MatrixRoom = self.invited_rooms[room_id]

            rooms.RoomUpdated(
                user_id      = self.user_id,
                category     = "Invites",
                room_id      = room_id,
                display_name = self._get_room_name(room),
                avatar_url   = room.gen_avatar_url,
                topic        = room.topic,
                inviter      = room.inviter,
            )

        for room_id, _ in resp.rooms.join.items():
            room = self.rooms[room_id]

            rooms.RoomUpdated(
                user_id      = self.user_id,
                category     = "Rooms",
                room_id      = room_id,
                display_name = self._get_room_name(room),
                avatar_url   = room.gen_avatar_url,
                topic        = room.topic,
            )

        for room_id, _ in resp.rooms.leave.items():
            rooms.RoomUpdated(
                user_id  = self.user_id,
                category = "Left",
                room_id  = room_id,
                # left_event TODO
            )


    # Callbacks for nio events

    async def onRoomMessageText(self, room: MatrixRoom, ev: nio.RoomMessageText
                               ) -> None:
        is_html = ev.format == "org.matrix.custom.html"
        filter_ = HTML_FILTER.filter

        HtmlMessageReceived(
            type          = EventType.html if is_html else EventType.text,
            room_id       = room.room_id,
            event_id      = ev.event_id,
            sender_id     = ev.sender,
            date          = datetime.fromtimestamp(ev.server_timestamp / 1000),
            is_local_echo = False,
            content       = filter_(ev.formatted_body) if is_html else ev.body,
        )
