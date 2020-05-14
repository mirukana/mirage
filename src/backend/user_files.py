# SPDX-License-Identifier: LGPL-3.0-or-later

"""User data and configuration files definitions."""

import asyncio
import json
import os
import platform
from dataclasses import dataclass, field
from pathlib import Path
from typing import TYPE_CHECKING, Any, ClassVar, Dict, Optional

import aiofiles

import pyotherside

from .theme_parser import convert_to_qml
from .utils import atomic_write, dict_update_recursive

if TYPE_CHECKING:
    from .backend import Backend

JsonData = Dict[str, Any]

WRITE_LOCK = asyncio.Lock()


@dataclass
class DataFile:
    """Base class representing a user data file."""

    is_config:      ClassVar[bool] = False
    create_missing: ClassVar[bool] = True

    backend:  "Backend" = field(repr=False)
    filename: str       = field()

    _to_write: Optional[str] = field(init=False, default=None)


    def __post_init__(self) -> None:
        asyncio.ensure_future(self._write_loop())


    @property
    def path(self) -> Path:
        """Full path of the file, even if it doesn't exist yet."""

        if self.is_config:
            return Path(
                os.environ.get("MIRAGE_CONFIG_DIR") or
                self.backend.appdirs.user_config_dir,
            ) / self.filename

        return Path(
            os.environ.get("MIRAGE_DATA_DIR") or
            self.backend.appdirs.user_data_dir,
        ) / self.filename


    async def default_data(self):
        """Default content if the file doesn't exist."""

        return ""


    async def read(self):
        """Return content of the existing file on disk, or default content."""

        try:
            return self.path.read_text()
        except FileNotFoundError:
            default = await self.default_data()

            if self.create_missing:
                await self.write(default)

            return default


    async def write(self, data) -> None:
        """Request for the file to be written/updated with data."""

        self._to_write = data


    async def _write_loop(self) -> None:
        """Write/update file on disk with a 1 second cooldown."""

        self.path.parent.mkdir(parents=True, exist_ok=True)

        while True:
            await asyncio.sleep(1)

            if self._to_write is None:
                continue

            if not self.create_missing and not self.path.exists():
                continue

            async with atomic_write(self.path) as (new, done):
                await new.write(self._to_write)
                done()

            self._to_write = None



@dataclass
class JSONDataFile(DataFile):
    """Represent a user data file in the JSON format."""

    _data: Optional[Dict[str, Any]] = field(init=False, default=None)


    def __getitem__(self, key: str) -> Any:
        if self._data is None:
            raise RuntimeError(f"{self}: read() hasn't been called yet")

        return self._data[key]


    async def default_data(self) -> JsonData:
        return {}


    async def read(self) -> JsonData:
        """Return content of the existing file on disk, or default content.

        If the file has missing keys, the missing data will be merged and
        written to disk before returning.

        If `create_missing` is `True` and the file doesn't exist, it will be
        created.
        """

        try:
            data = json.loads(self.path.read_text())
        except FileNotFoundError:
            if not self.create_missing:
                data       = await self.default_data()
                self._data = data
                return data

            data = {}
        except json.JSONDecodeError:
            data = {}

        all_data = await self.default_data()
        dict_update_recursive(all_data, data)

        if data != all_data:
            await self.write(all_data)

        self._data = all_data
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
                "enabled":    True,
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
        def alt_or_cmd() -> str:
            # Ctrl in Qt corresponds to Cmd on OSX
            return "Ctrl" if platform.system() == "Darwin" else "Alt"

        return {
            "alertOnMessageForMsec": 4000,
            "alwaysCenterRoomHeader": False,
            "compactMode": False,
            "clearRoomFilterOnEnter": True,
            "clearRoomFilterOnEscape": True,
            "collapseSidePanesUnderWindowWidth": 400,
            "hideProfileChangeEvents": True,
            "hideMembershipEvents": False,
            "hideUnknownEvents": False,
            "theme": "Midnight.qpl",
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

                "zoomIn":            ["Ctrl++"],
                "zoomOut":           ["Ctrl+-"],
                "zoomReset":         ["Ctrl+="],
                "toggleCompactMode": ["Ctrl+Alt+C"],

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

                "addNewAccount":         ["Alt+Shift+A"],
                "accountSettings":       ["Alt+A"],
                "addNewChat":            ["Alt+C"],
                "toggleFocusMainPane":   ["Alt+F"],
                "clearRoomFilter":       ["Alt+Shift+F"],
                "toggleCollapseAccount": [ "Alt+O"],

                "goToLastPage":              ["Ctrl+Tab"],
                "goToPreviousAccount":       ["Alt+Shift+N"],
                "goToNextAccount":           ["Alt+N"],
                "goToPreviousRoom":          ["Alt+Shift+Up", "Alt+Shift+K"],
                "goToNextRoom":              ["Alt+Shift+Down", "Alt+Shift+J"],
                "goToPreviousUnreadRoom":    ["Alt+Shift+U"],
                "goToNextUnreadRoom":        ["Alt+U"],
                "goToPreviousMentionedRoom": ["Alt+Shift+M"],
                "goToNextMentionedRoom":     ["Alt+M"],

                "focusRoomAtIndex": {
                    "01": f"{alt_or_cmd()}+1",
                    "02": f"{alt_or_cmd()}+2",
                    "03": f"{alt_or_cmd()}+3",
                    "04": f"{alt_or_cmd()}+4",
                    "05": f"{alt_or_cmd()}+5",
                    "06": f"{alt_or_cmd()}+6",
                    "07": f"{alt_or_cmd()}+7",
                    "08": f"{alt_or_cmd()}+8",
                    "09": f"{alt_or_cmd()}+9",
                    "10": f"{alt_or_cmd()}+0",
                },

                "unfocusOrDeselectAllMessages":    ["Escape"],
                "focusPreviousMessage":            ["Ctrl+Up", "Ctrl+K"],
                "focusNextMessage":                ["Ctrl+Down", "Ctrl+J"],
                "toggleSelectMessage":             ["Ctrl+Space"],
                "selectMessagesUntilHere":         ["Ctrl+Shift+Space"],
                "removeFocusedOrSelectedMessages": ["Ctrl+R", "Alt+Del"],
                "debugFocusedMessage":             ["Ctrl+D"],
                "clearRoomMessages":               ["Ctrl+L"],

                "sendFile":                    ["Alt+S"],
                "sendFileFromPathInClipboard": ["Alt+Shift+S"],
                "inviteToRoom":                ["Alt+I"],
                "leaveRoom":                   ["Alt+Escape"],
                "forgetRoom":                  ["Alt+Shift+Escape"],

                "toggleFocusRoomPane": ["Alt+R"],
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

    # Since it currently breaks at every update and the file format will be
    # changed later, don't copy the theme to user data dir if it doesn't exist.
    create_missing = False


    @property
    def path(self) -> Path:
        data_dir = Path(self.backend.appdirs.user_data_dir)
        return data_dir / "themes" / self.filename


    async def default_data(self) -> str:
        path = f"src/themes/{self.filename}"

        try:
            byte_content = pyotherside.qrc_get_file_contents(path)
        except ValueError:
            # App was compiled without QRC
            async with aiofiles.open(path) as file:
                return await file.read()
        else:
            return byte_content.decode()


    async def read(self) -> str:
        return convert_to_qml(await super().read())
