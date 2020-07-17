# SPDX-License-Identifier: LGPL-3.0-or-later

import asyncio
import logging as log
import os
import sys
import traceback
from pathlib import Path
from typing import Any, DefaultDict, Dict, List, Optional

from appdirs import AppDirs

import nio

from . import __app_name__
from .errors import MatrixError
from .matrix_client import MatrixClient
from .media_cache import MediaCache
from .models import SyncId
from .models.filters import FieldSubstringFilter
from .models.items import Account, Presence
from .models.model import Model
from .models.model_store import ModelStore
from .user_files import Accounts, History, Theme, UISettings, UIState

# Logging configuration
log.getLogger().setLevel(log.INFO)
nio.logger_group.level = nio.log.logbook.ERROR
nio.log.logbook.StreamHandler(sys.stderr).push_application()


class Backend:
    """Manage matrix clients and provide other useful general methods.

    Attributes:
        saved_accounts: User config file for saved matrix account.

        ui_settings: User config file for QML interface settings.

        ui_state: User data file for saving/restoring QML UI state.

        history: User data file for saving/restoring text typed into QML
            components.

        models: A mapping containing our data models that are
            synchronized between the Python backend and the QML UI.
            The models should only ever be modified from the backend.

            If a non-existent key is accessed, it is created and an
            associated `Model` and returned.

            The mapping keys are the `Model`'s synchronization ID,
            which a strings or tuple of strings.

            Currently used sync ID throughout the code are:

            - `"accounts"`: logged-in accounts;

            - `("<user_id>", "rooms")`: rooms our account `user_id` is part of;

            - `("<user_id>", "uploads")`: ongoing or failed file uploads for
              our account `user_id`;

            - `("<user_id>", "<room_id>", "members")`: members in the room
              `room_id` that our account `user_id` is part of;

            - `("<user_id>", "<room_id>", "events")`: state events and messages
              in the room `room_id` that our account `user_id` is part of.

            Special models:

            - `"all_rooms"`: See `models.special_models.AllRooms` docstring

            - `"matching_accounts"`
              See `models.special_models.MatchingAccounts` docstring

            - `("<user_id>", "<room_id>", "filtered_members")`:
              See `models.special_models.FilteredMembers` docstring


        clients: A `{user_id: MatrixClient}` dict for the logged-in clients
            we managed. Every client is logged to one matrix account.

        media_cache: A matrix media cache for downloaded files.

        presences: A `{user_id: Presence}` dict for storing presence info about
            matrix users registered on Mirage.
    """

    def __init__(self) -> None:
        self.appdirs = AppDirs(appname=__app_name__, roaming=True)

        self.saved_accounts = Accounts(self)
        self.ui_settings    = UISettings(self)
        self.ui_state       = UIState(self)
        self.history        = History(self)

        self.models = ModelStore()

        self.clients: Dict[str, MatrixClient] = {}

        self.profile_cache: Dict[str, nio.ProfileGetResponse] = {}
        self.get_profile_locks: DefaultDict[str, asyncio.Lock] = \
                DefaultDict(asyncio.Lock)  # {user_id: lock}

        self.send_locks: DefaultDict[str, asyncio.Lock] = \
                DefaultDict(asyncio.Lock)  # {room_id: lock}

        cache_dir = Path(
            os.environ.get("MIRAGE_CACHE_DIR") or self.appdirs.user_cache_dir,
        )

        self.media_cache: MediaCache = MediaCache(self, cache_dir)

        self.presences: Dict[str, Presence] = {}

        self.concurrent_get_presence_limit = asyncio.BoundedSemaphore(8)


    def __repr__(self) -> str:
        return f"{type(self).__name__}(clients={self.clients!r})"


    # Clients management

    async def login_client(self,
        user:       str,
        password:   str,
        device_id:  Optional[str] = None,
        homeserver: str           = "https://matrix.org",
        order:      Optional[int] = None,
   ) -> str:
        """Create and register a `MatrixClient`, login and return a user ID."""

        client = MatrixClient(
            self, user=user, homeserver=homeserver, device_id=device_id,
        )

        try:
            await client.login(password, order=order)
        except MatrixError:
            await client.close()
            raise

        # Check if the user is already present on mirage
        if client.user_id in self.clients:
            await client.logout()
            return client.user_id

        self.clients[client.user_id] = client

        return client.user_id


    async def resume_client(
        self,
        user_id:    str,
        token:      str,
        device_id:  str,
        homeserver: str = "https://matrix.org",
        state:      str = "online",
        status_msg: str = "",
    ) -> None:
        """Create and register a `MatrixClient` with known account details."""

        client = MatrixClient(
            backend=self,
            user=user_id, homeserver=homeserver, device_id=device_id,
        )

        self.clients[user_id] = client

        await client.resume(user_id, token, device_id, state, status_msg)


    async def load_saved_accounts(self) -> List[str]:
        """Call `resume_client` for all saved accounts in user config."""

        async def resume(user_id: str, info: Dict[str, Any]) -> str:
            # Get or create account model
            self.models["accounts"].setdefault(
                user_id, Account(user_id, info.get("order", -1)),
            )

            await self.resume_client(
                user_id    = user_id,
                token      = info["token"],
                device_id  = info["device_id"],
                homeserver = info["homeserver"],
                state      = info.get("presence", "online"),
                status_msg = info.get("status_msg", ""),
            )

            return user_id

        return await asyncio.gather(*(
            resume(uid, info)
            for uid, info in (await self.saved_accounts.read()).items()
            if info.get("enabled", True)
        ))


    async def logout_client(self, user_id: str) -> None:
        """Log a `MatrixClient` out and unregister it from our models."""

        client = self.clients.pop(user_id, None)

        if client:
            self.models["accounts"].pop(user_id, None)
            self.models["matching_accounts"].pop(user_id, None)
            self.models[user_id, "uploads"].clear()

            for room_id in self.models[user_id, "rooms"]:
                self.models["all_rooms"].pop(room_id, None)
                self.models[user_id, room_id, "members"].clear()
                self.models[user_id, room_id, "events"].clear()
                self.models[user_id, room_id, "filtered_members"].clear()

            self.models[user_id, "rooms"].clear()

            await client.logout()

        await self.saved_accounts.delete(user_id)


    async def terminate_clients(self) -> None:
        """Call every `MatrixClient`'s `terminate()` method."""

        log.info("Setting clients offline...")
        tasks = [client.terminate() for client in self.clients.values()]
        await asyncio.gather(*tasks)


    async def get_client(self, user_id: str) -> MatrixClient:
        """Wait until a `MatrixClient` is registered in model and return it."""

        failures = 0

        while True:
            if user_id in self.clients:
                return self.clients[user_id]

            if failures and failures % 100 == 0:  # every 10s except first time
                log.warning(
                    "Client %r not found after %ds, stack trace:\n%s",
                    user_id, failures / 10, traceback.format_stack(),
                )

            await asyncio.sleep(0.1)
            failures += 1


    async def get_any_client(self) -> MatrixClient:
        """Return any healthy syncing `MatrixClient` registered in model."""

        failures = 0

        while True:
            for client in self.clients.values():
                if client.syncing:
                    return client

            if failures and failures % 300 == 0:
                log.warn(
                    "No healthy client found after %ds, stack trace:\n%s",
                    failures / 10, traceback.format_stack(),
                )

            await asyncio.sleep(0.1)
            failures += 1


    # Client functions that don't need authentification

    async def get_profile(
        self, user_id: str, use_cache: bool = True,
    ) -> nio.ProfileGetResponse:
        """Cache and return the matrix profile of `user_id`."""

        async with self.get_profile_locks[user_id]:
            if use_cache and user_id in self.profile_cache:
                return self.profile_cache[user_id]

            client   = self.clients.get(user_id) or await self.get_any_client()
            response = await client.get_profile(user_id)

            self.profile_cache[user_id] = response
            return response


    async def thumbnail(
        self, server_name: str, media_id: str, width: int, height: int,
    ) -> nio.ThumbnailResponse:
        """Return thumbnail for a matrix media."""

        args   = (server_name, media_id, width, height)
        client = await self.get_any_client()
        return await client.thumbnail(*args)


    async def download(
        self, server_name: str, media_id: str,
    ) -> nio.DownloadResponse:
        """Return the content of a matrix media."""

        client = await self.get_any_client()
        return await client.download(server_name, media_id)


    async def update_room_read_marker(
        self, room_id: str, event_id: str,
    ) -> None:
        """Update room's read marker to an event for all accounts part of it.
        """

        async def update(client: MatrixClient) -> None:
            room    = self.models[client.user_id, "rooms"].get(room_id)
            account = self.models["accounts"][client.user_id]

            if room:
                room.set_fields(
                    unreads          = 0,
                    highlights       = 0,
                    local_unreads    = False,
                    local_highlights = False,
                )
                await client.update_account_unread_counts()

                # Only update server markers if the account is not invisible
                if account.presence != Presence.State.invisible:
                    await client.update_receipt_marker(room_id, event_id)

        await asyncio.gather(*[update(c) for c in self.clients.values()])


    # General functions

    async def get_config_dir(self) -> Path:
        return Path(self.appdirs.user_config_dir)


    async def load_settings(self) -> tuple:
        """Return parsed user config files."""

        settings = await self.ui_settings.read()
        ui_state = await self.ui_state.read()
        history  = await self.history.read()
        theme    = await Theme(self, settings["theme"]).read()

        state_data = self.ui_state._data
        if state_data:
            for user, collapse in state_data["collapseAccounts"].items():
                self.models["all_rooms"].set_account_collapse(user, collapse)

        return (settings, ui_state, history, theme)


    async def set_substring_filter(self, model_id: SyncId, value: str) -> None:
        """Set a FieldSubstringFilter model's filter property.

        This should only be called from QML.
        """

        if isinstance(model_id, list):  # QML can't pass tuples
            model_id = tuple(model_id)

        model = Model.proxies[model_id]

        if not isinstance(model, FieldSubstringFilter):
            raise TypeError("model_id must point to a FieldSubstringFilter")

        model.filter = value


    async def set_account_collapse(self, user_id: str, collapse: bool) -> None:
        """Call `set_account_collapse()` on the `all_rooms` model.

        This should only be called from QML.
        """
        self.models["all_rooms"].set_account_collapse(user_id, collapse)


    async def verify_device(
        self, user_id: str, device_id: str, ed25519_key: str,
    ) -> None:
        """Mark a device as verified on all our accounts."""

        for client in self.clients.values():
            try:
                device = client.device_store[user_id][device_id]
            except KeyError:
                continue

            if device.ed25519 == ed25519_key:
                client.verify_device(device)


    async def blacklist_device(
        self, user_id: str, device_id: str, ed25519_key: str,
    ) -> None:
        """Mark a device as blacklisted on all our accounts."""

        for client in self.clients.values():
            try:
                # This won't include the client's current device, as expected
                device = client.device_store[user_id][device_id]
            except KeyError:
                continue

            if device.ed25519 == ed25519_key:
                client.blacklist_device(device)
