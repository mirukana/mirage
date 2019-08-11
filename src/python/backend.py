import asyncio
import logging as log
import random
from typing import DefaultDict, Dict, List, Optional, Tuple, Union

import hsluv

import nio

from .app import App
from .matrix_client import MatrixClient
from .models.items import Account, Device, Event, Member, Room
from .models.model_store import ModelStore

ProfileResponse = Union[nio.ProfileGetResponse, nio.ProfileGetError]


class Backend:
    def __init__(self, app: App) -> None:
        self.app = app

        from . import config_files
        self.saved_accounts = config_files.Accounts(self)
        self.ui_settings    = config_files.UISettings(self)
        self.ui_state       = config_files.UIState(self)

        self.models = ModelStore(allowed_key_types={
            Account,             # Logged-in accounts
            (Device, str),       # Devices of user_id
            (Room,   str),       # Rooms for user_id
            (Member, str),       # Members in room_id
            (Event,  str, str),  # Events for account user_id for room_id
        })

        self.clients: Dict[str, MatrixClient] = {}

        self.profile_cache: Dict[str, nio.ProfileGetResponse] = {}
        self.get_profile_locks: DefaultDict[str, asyncio.Lock] = \
                DefaultDict(asyncio.Lock)  # {user_id: lock}


    def __repr__(self) -> str:
        return f"{type(self).__name__}(clients={self.clients!r})"


    # Clients management

    async def login_client(self,
                           user:       str,
                           password:   str,
                           device_id:  Optional[str] = None,
                           homeserver: str = "https://matrix.org") -> str:
        client = MatrixClient(
            self, user=user, homeserver=homeserver, device_id=device_id,
        )
        await client.login(password)
        self.clients[client.user_id]         = client
        self.models[Account][client.user_id] = Account(client.user_id)
        return client.user_id


    async def resume_client(self,
                            user_id:    str,
                            token:      str,
                            device_id:  str,
                            homeserver: str = "https://matrix.org") -> None:

        client = MatrixClient(
            backend=self,
            user=user_id, homeserver=homeserver, device_id=device_id,
        )
        await client.resume(user_id=user_id, token=token, device_id=device_id)

        self.clients[client.user_id]         = client
        self.models[Account][client.user_id] = Account(client.user_id)


    async def load_saved_accounts(self) -> Tuple[str, ...]:
        async def resume(user_id: str, info: Dict[str, str]) -> str:
            await self.resume_client(
                user_id    = user_id,
                token      = info["token"],
                device_id  = info["device_id"],
                homeserver = info["homeserver"],
            )
            return user_id

        return await asyncio.gather(*(
            resume(uid, info)
            for uid, info in (await self.saved_accounts.read()).items()
        ))


    async def logout_client(self, user_id: str) -> None:
        client = self.clients.pop(user_id, None)
        if client:
            self.models[Account].pop(client.user_id, None)
            await client.logout()


    async def logout_all_clients(self) -> None:
        await asyncio.gather(*(
            self.logout_client(user_id) for user_id in self.clients.copy()
        ))


    async def wait_until_client_exists(self, user_id: str = "") -> None:
        while True:
            if user_id and user_id in self.clients:
                return

            if not user_id and self.clients:
                return

            await asyncio.sleep(0.1)


    # General functions

    async def load_settings(self) -> tuple:
        from .config_files import Theme
        settings = await self.ui_settings.read()
        ui_state = await self.ui_state.read()
        theme    = await Theme(self, settings["theme"]).read()

        return (settings, ui_state, theme)


    async def get_profile(self, user_id: str) -> ProfileResponse:
        if user_id in self.profile_cache:
            return self.profile_cache[user_id]

        async with self.get_profile_locks[user_id]:
            if not self.clients:
                await self.wait_until_client_exists()

            client = self.clients.get(
                user_id,
                random.choice(tuple(self.clients.values())),
            )

            response = await client.get_profile(user_id)

            if isinstance(response, nio.ProfileGetError):
                log.warning("%s: %s", user_id, response)

            self.profile_cache[user_id] = response
            return response


    @staticmethod
    def hsluv(hue: int, saturation: int, lightness: int) -> List[float]:
        # (0-360, 0-100, 0-100) -> [0-1, 0-1, 0-1]
        return hsluv.hsluv_to_rgb([hue, saturation, lightness])
