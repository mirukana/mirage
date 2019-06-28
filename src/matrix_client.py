import asyncio
import inspect
import platform
from contextlib import suppress
from typing import Optional

import nio

from . import __about__
from .events import rooms, users


class MatrixClient(nio.AsyncClient):
    def __init__(self,
                 user:       str,
                 homeserver: str           = "https://matrix.org",
                 device_id:  Optional[str] = None) -> None:

        # TODO: ensure homeserver starts with a scheme://
        self.sync_task: Optional[asyncio.Task] = None
        super().__init__(homeserver=homeserver, user=user, device_id=device_id)

        self.connect_callbacks()


    def __repr__(self) -> str:
        return "%s(user_id=%r, homeserver=%r, device_id=%r)" % (
            type(self).__name__, self.user_id, self.homeserver, self.device_id
        )


    def connect_callbacks(self) -> None:
        for name in dir(nio.responses):
            if name.startswith("_"):
                continue

            obj = getattr(nio.responses, name)
            if inspect.isclass(obj) and issubclass(obj, nio.Response):
                with suppress(AttributeError):
                    self.add_response_callback(getattr(self, f"on{name}"), obj)


    async def start_syncing(self) -> None:
        self.sync_task = asyncio.ensure_future(  # type: ignore
            self.sync_forever(timeout=10_000)
        )


    @property
    def default_device_name(self) -> str:
        os_ = f" on {platform.system()}".rstrip()
        os_ = f"{os_} {platform.release()}".rstrip() if os_ != " on" else ""
        return f"{__about__.__pretty_name__}{os_}"


    async def login(self, password: str) -> None:
        response = await super().login(password, self.default_device_name)

        if isinstance(response, nio.LoginError):
            print(response)
        else:
            await self.start_syncing()


    async def resume(self, user_id: str, token: str, device_id: str) -> None:
        self.receive_response(nio.LoginResponse(user_id, device_id, token))
        await self.start_syncing()


    async def logout(self) -> None:
        if self.sync_task:
            self.sync_task.cancel()
            with suppress(asyncio.CancelledError):
                await self.sync_task

        await self.close()


    async def request_user_update_event(self, user_id: str) -> None:
        response = await self.get_profile(user_id)

        users.UserUpdated(
            user_id        = user_id,
            display_name   = response.displayname,
            avatar_url     = response.avatar_url,
            status_message = None,  # TODO
        )


    # Callbacks for nio responses

    async def onSyncResponse(self, response: nio.SyncResponse) -> None:
        for room_id in response.rooms.invite:
            room: nio.rooms.MatrixRoom = self.invited_rooms[room_id]

            rooms.RoomUpdated(
                user_id      = self.user_id,
                category     = "Invites",
                room_id      = room_id,
                display_name = room.display_name,
                avatar_url   = room.gen_avatar_url,
                topic        = room.topic,
                inviter      = room.inviter,
            )

        for room_id in response.rooms.join:
            room = self.rooms[room_id]

            rooms.RoomUpdated(
                user_id      = self.user_id,
                category     = "Rooms",
                room_id      = room_id,
                display_name = room.display_name,
                avatar_url   = room.gen_avatar_url,
                topic        = room.topic,
            )

        for room_id in response.rooms.left:
            rooms.RoomUpdated(
                user_id  = self.user_id,
                category = "Left",
                room_id  = room_id,
                # left_event TODO
            )
