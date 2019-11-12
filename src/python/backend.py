import asyncio
import logging as log
from typing import Any, DefaultDict, Dict, List, Optional, Tuple, Union

import hsluv

import nio

from . import utils
from .app import App
from .errors import MatrixError
from .matrix_client import MatrixClient
from .models.items import Account, Device, Event, Member, Room, Upload
from .models.model_store import ModelStore


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
            (Upload, str),       # Uploads running in room_id
            (Event,  str, str),  # Events for account user_id for room_id
        })

        self.clients: Dict[str, MatrixClient] = {}

        self.profile_cache: Dict[str, nio.ProfileGetResponse] = {}
        self.get_profile_locks: DefaultDict[str, asyncio.Lock] = \
                DefaultDict(asyncio.Lock)  # {user_id: lock}


    def __repr__(self) -> str:
        return f"{type(self).__name__}(clients={self.clients!r})"


    # Clients management

    @utils.cancel_previous
    async def login_client(self,
        user:       str,
        password:   str,
        device_id:  Optional[str] = None,
        homeserver: str           = "https://matrix.org",
   ) -> str:

        client = MatrixClient(
            self, user=user, homeserver=homeserver, device_id=device_id,
        )

        try:
            await client.login(password)
        except MatrixError:
            await client.close()
            raise

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
            self.models[Account].pop(user_id, None)
            await client.logout()

        await self.saved_accounts.delete(user_id)


    async def wait_until_client_exists(self, user_id: str) -> None:
        loops = 0
        while True:
            if user_id in self.clients:
                return

            if loops and loops % 100 == 0:  # every 10s except first time
                log.warning("Waiting for account %s to exist, %ds passed",
                            user_id, loops // 10)

            await asyncio.sleep(0.1)
            loops += 1


    # General functions

    @staticmethod
    def hsluv(hue: int, saturation: int, lightness: int) -> List[float]:
        # (0-360, 0-100, 0-100) -> [0-1, 0-1, 0-1]
        return hsluv.hsluv_to_rgb([hue, saturation, lightness])


    @staticmethod
    async def mxc_to_http(mxc: str) -> Optional[str]:
        return nio.Api.mxc_to_http(mxc)


    @staticmethod
    async def check_exported_keys_passphrase(file_path: str, passphrase: str,
                                            ) -> Union[bool, Tuple[str, bool]]:
        """Check if the exported keys file can be decrypted with passphrase.

        Returns True on success, False is the passphrase is invalid, or
        an (error_message, error_is_translated) tuple if another error occured.
        """

        try:
            nio.crypto.key_export.decrypt_and_read(file_path, passphrase)
            return True

        except OSError as err:  # XXX raise
            return (f"{file_path}: {err.strerror}", True)

        except ValueError as err:  # XXX raise
            if str(err).startswith("HMAC check failed"):
                return False

            return (str(err), False)


    async def load_settings(self) -> tuple:
        from .config_files import Theme
        settings = await self.ui_settings.read()
        ui_state = await self.ui_state.read()
        theme    = await Theme(self, settings["theme"]).read()

        return (settings, ui_state, theme)


    async def get_profile(self, user_id: str) -> nio.ProfileGetResponse:
        if user_id in self.profile_cache:
            return self.profile_cache[user_id]

        async with self.get_profile_locks[user_id]:
            while True:
                try:
                    client = next(c for c in self.clients.values())
                    break
                except StopIteration:
                    # Retry after a bit if no client was present yet
                    await asyncio.sleep(0.1)

            response = await client.get_profile(user_id)

            if isinstance(response, nio.ProfileGetError):
                raise MatrixError.from_nio(response)

            self.profile_cache[user_id] = response
            return response


    async def get_flat_sidepane_data(self) -> List[Dict[str, Any]]:
        data = []

        for account in sorted(self.models[Account].values()):
            data.append({
                "type":    "Account",
                "id":      account.user_id,
                "user_id": account.user_id,
                "data":    account.serialized,
            })

            for room in sorted(self.models[Room, account.user_id].values()):
                data.append({
                    "type":    "Room",
                    "id":      "/".join((account.user_id, room.room_id)),
                    "user_id": account.user_id,
                    "data":    room.serialized,
                })

        return data
