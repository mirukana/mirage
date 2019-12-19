# SPDX-License-Identifier: LGPL-3.0-or-later

"""User data and configuration files definitions."""

import asyncio
import json
import logging as log
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any, ClassVar, Dict, Optional

import aiofiles

from .backend import Backend
from .theme_parser import convert_to_qml
from .utils import dict_update_recursive

JsonData = Dict[str, Any]

WRITE_LOCK = asyncio.Lock()


@dataclass
class DataFile:
    """Base class representing a user data file."""

    is_config: ClassVar[bool] = False

    backend:  Backend = field(repr=False)
    filename: str     = field()

    _to_write: Optional[str] = field(init=False, default=None)


    def __post_init__(self) -> None:
        asyncio.ensure_future(self._write_loop())


    @property
    def path(self) -> Path:
        """Full path of the file, even if it doesn't exist yet."""

        if self.is_config:
            return Path(self.backend.appdirs.user_config_dir) / self.filename

        return Path(self.backend.appdirs.user_data_dir) / self.filename


    async def default_data(self):
        """Default content if the file doesn't exist."""

        return ""


    async def read(self):
        """Return the content of the existing file on disk."""

        log.debug("Reading config %s at %s", type(self).__name__, self.path)
        return self.path.read_text()


    async def write(self, data) -> None:
        """Request for the file to be written/updated with data."""

        self._to_write = data


    async def _write_loop(self) -> None:
        """Write/update file to on disk with a 1 second cooldown."""

        self.path.parent.mkdir(parents=True, exist_ok=True)

        while True:
            if self._to_write is not None:
                async with aiofiles.open(self.path, "w") as new:
                    await new.write(self._to_write)

                self._to_write = None

            await asyncio.sleep(1)



@dataclass
class JSONDataFile(DataFile):
    """Represent a user data file in the JSON format."""

    async def default_data(self) -> JsonData:
        return {}


    async def read(self) -> JsonData:
        """Return the content of the existing file on disk.

        If the file doesn't exist on disk or it has missing keys, the missing
        data will be merged and written to disk before returning.
        """
        try:
            data = json.loads(await super().read())
        except (FileNotFoundError, json.JSONDecodeError):
            data = {}

        all_data = await self.default_data()
        dict_update_recursive(all_data, data)

        if data != all_data:
            await self.write(all_data)

        return all_data


    async def write(self, data: JsonData) -> None:
        js = json.dumps(data, indent=4, ensure_ascii=False, sort_keys=True)
        await super().write(js)


@dataclass
class Accounts(JSONDataFile):
    """Config file for saved matrix accounts: user ID, access tokens, etc."""

    is_config = True

    filename: str = "accounts.json"


    async def any_saved(self) -> bool:
        """Return whether there are any accounts saved on disk."""
        return bool(await self.read())


    async def add(self, user_id: str) -> None:
        """Add an account to the config and write it on disk.

        The account's details such as its access token are retrieved from
        the corresponding `MatrixClient` in `backend.clients`.
        """

        client = self.backend.clients[user_id]

        await self.write({
            **await self.read(),
            client.user_id: {
                "homeserver": client.homeserver,
                "token":      client.access_token,
                "device_id":  client.device_id,
            },
        })


    async def delete(self, user_id: str) -> None:
        """Delete an account from the config and write it on disk."""

        await self.write({
            uid: info
            for uid, info in (await self.read()).items() if uid != user_id
        })


@dataclass
class UISettings(JSONDataFile):
    """Config file for QML interface settings and keybindings."""

    is_config = True

    filename: str = "settings.json"


    async def default_data(self) -> JsonData:
        return {
            "alertOnMessageForMsec": 4000,
            "clearRoomFilterOnEnter": True,
            "clearRoomFilterOnEscape": True,
            "theme": "Default.qpl",
            "writeAliases": {},
            "media": {
                "autoLoad": True,
                "autoPlay": False,
                "autoPlayGIF": True,
                "autoHideOSDAfterMsec": 3000,
                "defaultVolume": 100,
                "startMuted": False,
            },
            "keys": {
                "startPythonDebugger": ["Alt+Shift+D"],
                "toggleDebugConsole":  ["Alt+Shift+C", "F1"],
                "reloadConfig":        ["Alt+Shift+R"],

                "zoomIn":    ["Ctrl++"],
                "zoomOut":   ["Ctrl+-"],
                "zoomReset": ["Ctrl+="],

                "scrollUp":       ["Alt+Up", "Alt+K"],
                "scrollDown":     ["Alt+Down", "Alt+J"],
                "scrollPageUp":   ["Alt+Ctrl+Up", "Alt+Ctrl+K", "PgUp"],
                "scrollPageDown": ["Alt+Ctrl+Down", "Alt+Ctrl+J", "PgDown"],
                "scrollToTop":
                    ["Alt+Ctrl+Shift+Up", "Alt+Ctrl+Shift+K", "Home"],
                "scrollToBottom":
                    ["Alt+Ctrl+Shift+Down", "Alt+Ctrl+Shift+J", "End"],

                "previousTab": ["Alt+Shift+Left", "Alt+Shift+H"],
                "nextTab":     ["Alt+Shift+Right", "Alt+Shift+L"],

                "focusMainPane":   ["Alt+S"],
                "clearRoomFilter": ["Alt+Shift+S"],
                "accountSettings": ["Alt+A"],
                "addNewChat":      ["Alt+N"],
                "addNewAccount":   ["Alt+Shift+N"],

                "goToLastPage":          ["Ctrl+Tab"],
                "goToPreviousRoom":      ["Alt+Shift+Up", "Alt+Shift+K"],
                "goToNextRoom":          ["Alt+Shift+Down", "Alt+Shift+J"],
                "toggleCollapseAccount": [ "Alt+O"],

                "clearRoomMessages":           ["Ctrl+L"],
                "sendFile":                    ["Alt+F"],
                "sendFileFromPathInClipboard": ["Alt+Shift+F"],
            },
        }


@dataclass
class UIState(JSONDataFile):
    """File to save and restore the state of the QML interface."""

    filename: str = "state.json"


    async def default_data(self) -> JsonData:
        return {
            "collapseAccounts": {},
            "page":             "Pages/Default.qml",
            "pageProperties":   {},
        }


@dataclass
class History(JSONDataFile):
    """File to save and restore lines typed by the user in QML components."""

    filename: str = "history.json"


    async def default_data(self) -> JsonData:
        return {"console": []}


@dataclass
class Theme(DataFile):
    """A theme file defining the look of QML components."""


    @property
    def path(self) -> Path:
        data_dir = Path(self.backend.appdirs.user_data_dir)
        return data_dir / "themes" / self.filename


    async def default_data(self) -> str:
        async with aiofiles.open("src/themes/Default.qpl") as file:
            return await file.read()


    async def read(self) -> str:
        if not self.path.exists():
            await self.write(await self.default_data())

        return convert_to_qml(await super().read())
