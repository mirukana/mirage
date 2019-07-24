# Copyright 2019 miruka
# This file is part of harmonyqml, licensed under LGPLv3.

import asyncio
import random
from typing import Dict, List, Optional, Set, Tuple

import hsluv

from .app import App
from .events import users
from .html_filter import HTML_FILTER
from .matrix_client import MatrixClient


class Backend:
    def __init__(self, app: App) -> None:
        self.app = app

        from . import config_files
        self.saved_accounts = config_files.Accounts(self)
        self.ui_settings    = config_files.UISettings(self)
        self.ui_state       = config_files.UIState(self)

        self.clients: Dict[str, MatrixClient] = {}

        self.past_tokens:        Dict[str, str] =  {}    # {room_id: token}
        self.fully_loaded_rooms: Set[str]       = set()  # {room_id}

        self.pending_profile_requests: Set[str] = set()


    def __repr__(self) -> str:
        return f"{type(self).__name__}(clients={self.clients!r})"


    # Clients management

    async def login_client(self,
                           user:       str,
                           password:   str,
                           device_id:  Optional[str] = None,
                           homeserver: str = "https://matrix.org") -> str:
        client = MatrixClient(
            backend=self, user=user, homeserver=homeserver, device_id=device_id
        )
        await client.login(password)
        self.clients[client.user_id] = client
        users.AccountUpdated(client.user_id)
        return client.user_id


    async def resume_client(self,
                            user_id:    str,
                            token:      str,
                            device_id:  str,
                            homeserver: str = "https://matrix.org") -> None:
        client = MatrixClient(
            backend=self,
            user=user_id, homeserver=homeserver, device_id=device_id
        )
        await client.resume(user_id=user_id, token=token, device_id=device_id)
        self.clients[client.user_id] = client
        users.AccountUpdated(client.user_id)


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
            await client.logout()
            users.AccountDeleted(user_id)


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


    async def request_user_update_event(self, user_id: str) -> None:
        if not self.clients:
            await self.wait_until_client_exists()

        client = self.clients.get(
            user_id,
            random.choice(tuple(self.clients.values()))
        )
        await client.request_user_update_event(user_id)


    @staticmethod
    def inlinify(html: str) -> str:
        return HTML_FILTER.filter_inline(html)


    @staticmethod
    def hsluv(hue: int, saturation: int, lightness: int) -> List[float]:
        # (0-360, 0-100, 0-100) -> [0-1, 0-1, 0-1]
        return hsluv.hsluv_to_rgb([hue, saturation, lightness])
