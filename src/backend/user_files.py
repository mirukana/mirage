# Copyright Mirage authors & contributors <https://github.com/mirukana/mirage>
# SPDX-License-Identifier: LGPL-3.0-or-later

"""User data and configuration files definitions."""

import asyncio
import json
import os
import platform
from collections.abc import MutableMapping
from dataclasses import dataclass, field
from pathlib import Path
from typing import TYPE_CHECKING, Any, ClassVar, Iterator, Optional, Tuple

import aiofiles
from watchgod import Change, awatch

import pyotherside

from .pyotherside_events import UserFileChanged
from .theme_parser import convert_to_qml
from .utils import atomic_write, dict_update_recursive

if TYPE_CHECKING:
    from .backend import Backend


@dataclass
class UserFile:
    """Base class representing a user config or data file."""

    create_missing: ClassVar[bool] = True

    backend:  "Backend" = field(repr=False)
    filename: str       = field()

    data:        Any  = field(init=False, default_factory=dict)
    _need_write: bool = field(init=False, default=False)
    _wrote:      bool = field(init=False, default=False)

    _reader:     Optional[asyncio.Future] = field(init=False, default=None)
    _writer:     Optional[asyncio.Future] = field(init=False, default=None)

    def __post_init__(self) -> None:
        try:
            self.data, save = self.deserialized(self.path.read_text())
        except FileNotFoundError:
            self.data        = self.default_data
            self._need_write = self.create_missing
        else:
            if save:
                self.save()

        self._reader = asyncio.ensure_future(self._start_reader())
        self._writer = asyncio.ensure_future(self._start_writer())

    @property
    def path(self) -> Path:
        """Full path of the file, can exist or not exist."""
        raise NotImplementedError()

    @property
    def default_data(self) -> Any:
        """Default deserialized content to use if the file doesn't exist."""
        raise NotImplementedError()

    def deserialized(self, data: str) -> Tuple[Any, bool]:
        """Return parsed data from file text and whether to call `save()`."""
        return (data, False)

    def serialized(self) -> str:
        """Return text from `UserFile.data` that can be written to disk."""
        raise NotImplementedError()

    def save(self) -> None:
        """Inform the disk writer coroutine that the data has changed."""
        self._need_write = True

    async def set_data(self, data: Any) -> None:
        """Set `data` and call `save()`, conveniance method for QML."""
        self.data = data
        self.save()

    async def _start_reader(self) -> None:
        """Disk reader coroutine, watches for file changes to update `data`."""

        while not self.path.exists():
            await asyncio.sleep(1)

        async for changes in awatch(self.path):
            ignored = 0

            for change in changes:
                if change[0] in (Change.added, Change.modified):
                    if self._need_write or self._wrote:
                        self._wrote = False
                        ignored    += 1
                        continue

                    async with aiofiles.open(self.path) as file:
                        self.data, save = self.deserialized(await file.read())

                        if save:
                            self.save()

                elif change[0] == Change.deleted:
                    self._wrote      = False
                    self.data        = self.default_data
                    self._need_write = self.create_missing

            if changes and ignored < len(changes):
                UserFileChanged(type(self), self.data)


    async def _start_writer(self) -> None:
        """Disk writer coroutine, update the file with a 1 second cooldown."""

        self.path.parent.mkdir(parents=True, exist_ok=True)

        while True:
            await asyncio.sleep(1)

            if self._need_write:
                async with atomic_write(self.path) as (new, done):
                    await new.write(self.serialized())
                    done()

                self._need_write = False
                self._wrote      = True


@dataclass
class ConfigFile(UserFile):
    """A file that goes in the configuration directory, e.g. ~/.config/app."""

    @property
    def path(self) -> Path:
        return Path(
            os.environ.get("MIRAGE_CONFIG_DIR") or
            self.backend.appdirs.user_config_dir,
        ) / self.filename


@dataclass
class UserDataFile(UserFile):
    """A file that goes in the user data directory, e.g. ~/.local/share/app."""

    @property
    def path(self) -> Path:
        return Path(
            os.environ.get("MIRAGE_DATA_DIR") or
            self.backend.appdirs.user_data_dir,
        ) / self.filename


@dataclass
class MappingFile(MutableMapping, UserFile):
    """A file manipulable like a dict. `data` must be a mutable mapping."""
    def __getitem__(self, key: Any) -> Any:
        return self.data[key]

    def __setitem__(self, key: Any, value: Any) -> None:
        self.data[key] = value

    def __delitem__(self, key: Any) -> None:
        del self.data[key]

    def __iter__(self) -> Iterator:
        return iter(self.data)

    def __len__(self) -> int:
        return len(self.data)


@dataclass
class JSONFile(MappingFile):
    """A file stored on disk in the JSON format."""

    @property
    def default_data(self) -> dict:
        return {}


    def deserialized(self, data: str) -> Tuple[dict, bool]:
        """Return parsed data from file text and whether to call `save()`.

        If the file has missing keys, the missing data will be merged to the
        returned dict and the second tuple item will be `True`.
        """

        try:
            loaded = json.loads(data)
        except json.JSONDecodeError:
            loaded = {}

        all_data = self.default_data.copy()
        dict_update_recursive(all_data, loaded)
        return (all_data, loaded != all_data)


    def serialized(self) -> str:
        data = self.data
        return json.dumps(data, indent=4, ensure_ascii=False, sort_keys=True)


@dataclass
class Accounts(ConfigFile, JSONFile):
    """Config file for saved matrix accounts: user ID, access tokens, etc"""

    filename: str = "accounts.json"

    async def any_saved(self) -> bool:
        """Return for QML whether there are any accounts saved on disk."""
        return bool(self.data)


    async def add(self, user_id: str) -> None:
        """Add an account to the config and write it on disk.

        The account's details such as its access token are retrieved from
        the corresponding `MatrixClient` in `backend.clients`.
        """

        client  = self.backend.clients[user_id]
        account = self.backend.models["accounts"][user_id]

        self.update({
            client.user_id: {
                "homeserver": client.homeserver,
                "token":      client.access_token,
                "device_id":  client.device_id,
                "enabled":    True,
                "presence":   account.presence.value,
                "status_msg": account.status_msg,
                "order":      account.order,
            },
        })
        self.save()


    async def set(
        self,
        user_id:    str,
        enabled:    Optional[str] = None,
        presence:   Optional[str] = None,
        order:      Optional[int] = None,
        status_msg: Optional[str] = None,
    ) -> None:
        """Update an account if found in the config file and write to disk."""

        if user_id not in self:
            return

        if enabled is not None:
            self[user_id]["enabled"] = enabled

        if presence is not None:
            self[user_id]["presence"] = presence

        if order is not None:
            self[user_id]["order"] = order

        if status_msg is not None:
            self[user_id]["status_msg"] = status_msg

        self.save()


    async def forget(self, user_id: str) -> None:
        """Delete an account from the config and write it on disk."""

        self.pop(user_id, None)
        self.save()


@dataclass
class Settings(ConfigFile, JSONFile):
    """General config file for UI and backend settings"""

    filename: str = "settings.json"

    @property
    def default_data(self) -> dict:
        def ctrl_or_osx_ctrl() -> str:
            # Meta in Qt corresponds to Ctrl on OSX
            return "Meta" if platform.system() == "Darwin" else "Ctrl"

        def alt_or_cmd() -> str:
            # Ctrl in Qt corresponds to Cmd on OSX
            return "Ctrl" if platform.system() == "Darwin" else "Alt"

        return {
            "alertOnMentionForMsec": -1,
            "alertOnMessageForMsec": 0,
            "alwaysCenterRoomHeader": False,
            # "autoHideScrollBarsAfterMsec": 2000,
            "beUnavailableAfterSecondsIdle": 60 * 10,
            "centerRoomListOnClick": False,
            "compactMode": False,
            "clearRoomFilterOnEnter": True,
            "clearRoomFilterOnEscape": True,
            "clearMemberFilterOnEscape": True,
            "closeMinimizesToTray": False,
            "collapseSidePanesUnderWindowWidth": 450,
            "enableKineticScrolling": True,
            "hideProfileChangeEvents": True,
            "hideMembershipEvents": False,
            "hideUnknownEvents": True,
            "kineticScrollingMaxSpeed": 2500,
            "kineticScrollingDeceleration": 1500,
            "lexicalRoomSorting": False,
            "markRoomReadMsecDelay": 200,
            "maxMessageCharactersPerLine": 65,
            "nonKineticScrollingSpeed": 1.0,
            "ownMessagesOnLeftAboveWidth": 895,
            "theme": "Midnight.qpl",
            "writeAliases": {},
            "zoom": 1.0,
            "roomBookmarkIDs": {},

            "media": {
                "autoLoad": True,
                "autoPlay": False,
                "autoPlayGIF": True,
                "autoHideOSDAfterMsec": 3000,
                "defaultVolume": 100,
                "openExternallyOnClick": False,
                "startMuted": False,
            },
            "keys": {
                "startPythonDebugger": ["Alt+Shift+D"],
                "toggleDebugConsole":  ["Alt+Shift+C", "F1"],

                "zoomIn":             ["Ctrl++"],
                "zoomOut":            ["Ctrl+-"],
                "zoomReset":          ["Ctrl+="],
                "toggleCompactMode":  ["Ctrl+Alt+C"],
                "toggleHideRoomPane": ["Ctrl+Alt+R"],

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
                "toggleCollapseAccount": ["Alt+O"],

                "openPresenceMenu":          ["Alt+P"],
                "togglePresenceUnavailable": ["Alt+Ctrl+U", "Alt+Ctrl+A"],
                "togglePresenceInvisible":   ["Alt+Ctrl+I"],
                "togglePresenceOffline":     ["Alt+Ctrl+O"],

                "goToLastPage":              ["Ctrl+Tab"],
                "goToPreviousAccount":       ["Alt+Shift+N"],
                "goToNextAccount":           ["Alt+N"],
                "goToPreviousRoom":          ["Alt+Shift+Up", "Alt+Shift+K"],
                "goToNextRoom":              ["Alt+Shift+Down", "Alt+Shift+J"],
                "goToPreviousUnreadRoom":    ["Alt+Shift+U"],
                "goToNextUnreadRoom":        ["Alt+U"],
                "goToPreviousMentionedRoom": ["Alt+Shift+M"],
                "goToNextMentionedRoom":     ["Alt+M"],

                "focusAccountAtIndex": {
                    "01": f"{ctrl_or_osx_ctrl()}+1",
                    "02": f"{ctrl_or_osx_ctrl()}+2",
                    "03": f"{ctrl_or_osx_ctrl()}+3",
                    "04": f"{ctrl_or_osx_ctrl()}+4",
                    "05": f"{ctrl_or_osx_ctrl()}+5",
                    "06": f"{ctrl_or_osx_ctrl()}+6",
                    "07": f"{ctrl_or_osx_ctrl()}+7",
                    "08": f"{ctrl_or_osx_ctrl()}+8",
                    "09": f"{ctrl_or_osx_ctrl()}+9",
                    "10": f"{ctrl_or_osx_ctrl()}+0",
                },
                # On OSX, alt+numbers if used for symbols, use cmd instead
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

                "unfocusOrDeselectAllMessages":       ["Ctrl+D"],
                "focusPreviousMessage":               ["Ctrl+Up", "Ctrl+K"],
                "focusNextMessage":                   ["Ctrl+Down", "Ctrl+J"],
                "toggleSelectMessage":                ["Ctrl+Space"],
                "selectMessagesUntilHere":            ["Ctrl+Shift+Space"],
                "removeFocusedOrSelectedMessages":    ["Ctrl+R", "Alt+Del"],
                "replyToFocusedOrLastMessage":        ["Ctrl+Q"],  # Q → Quote
                "debugFocusedMessage":                ["Ctrl+Shift+D"],
                "openMessagesLinksOrFiles":           ["Ctrl+O"],
                "openMessagesLinksOrFilesExternally": ["Ctrl+Shift+O"],
                "copyFilesLocalPath":                 ["Ctrl+Shift+C"],
                "clearRoomMessages":                  ["Ctrl+L"],

                "sendFile":                    ["Alt+S"],
                "sendFileFromPathInClipboard": ["Alt+Shift+S"],
                "inviteToRoom":                ["Alt+I"],
                "leaveRoom":                   ["Alt+Escape"],
                "forgetRoom":                  ["Alt+Shift+Escape"],

                "toggleFocusRoomPane": ["Alt+R"],

                "refreshDevices":             ["Alt+R", "F5"],
                "signOutCheckedOrAllDevices": ["Alt+S", "Delete"],

                "imageViewer": {
                    "panLeft":  ["H", "Left", "Alt+H", "Alt+Left"],
                    "panDown":  ["J", "Down", "Alt+J", "Alt+Down"],
                    "panUp":    ["K", "Up", "Alt+K", "Alt+Up"],
                    "panRight": ["L", "Right", "Alt+L", "Alt+Right"],

                    "zoomReset": ["Alt+Z", "=", "Ctrl+="],
                    "zoomOut":   ["Shift+Z", "-", "Ctrl+-"],
                    "zoomIn":    ["Z", "+", "Ctrl++"],

                    "rotateReset": ["Alt+R"],
                    "rotateLeft":  ["Shift+R"],
                    "rotateRight": ["R"],

                    "resetSpeed":    ["Alt+S"],
                    "previousSpeed": ["Shift+S"],
                    "nextSpeed":     ["S"],

                    "pause":      ["Space"],
                    "expand":     ["E"],
                    "fullScreen": ["F", "F11", "Alt+Return", "Alt+Enter"],
                    "close":      ["X", "Q"],
                },
            },
        }

    def deserialized(self, data: str) -> Tuple[dict, bool]:
        dict_data, save = super().deserialized(data)

        if "theme" in self and self["theme"] != dict_data["theme"]:
            self.backend.theme = Theme(self.backend, dict_data["theme"])
            UserFileChanged(Theme, self.backend.theme.data)

        return (dict_data, save)


@dataclass
class UIState(UserDataFile, JSONFile):
    """File used to save and restore the state of QML components."""

    filename: str = "state.json"

    @property
    def default_data(self) -> dict:
        return {
            "collapseAccounts": {},
            "page":             "Pages/Default.qml",
            "pageProperties":   {},
        }

    def deserialized(self, data: str) -> Tuple[dict, bool]:
        dict_data, save = super().deserialized(data)

        for user_id, do in dict_data["collapseAccounts"].items():
            self.backend.models["all_rooms"].set_account_collapse(user_id, do)

        return (dict_data, save)


@dataclass
class History(UserDataFile, JSONFile):
    """File to save and restore lines typed by the user in QML components."""

    filename: str = "history.json"

    @property
    def default_data(self) -> dict:
        return {"console": []}


@dataclass
class Theme(UserDataFile):
    """A theme file defining the look of QML components."""

    # Since it currently breaks at every update and the file format will be
    # changed later, don't copy the theme to user data dir if it doesn't exist.
    create_missing = False

    @property
    def path(self) -> Path:
        data_dir = Path(
            os.environ.get("MIRAGE_DATA_DIR") or
            self.backend.appdirs.user_data_dir,
        )
        return data_dir / "themes" / self.filename

    @property
    def default_data(self) -> str:
        path = f"src/themes/{self.filename}"

        try:
            byte_content = pyotherside.qrc_get_file_contents(path)
        except ValueError:
            # App was compiled without QRC
            return convert_to_qml(Path(path).read_text())
        else:
            return convert_to_qml(byte_content.decode())

    def deserialized(self, data: str) -> Tuple[str, bool]:
        return (convert_to_qml(data), False)
