# Copyright Mirage authors & contributors <https://github.com/mirukana/mirage>
# SPDX-License-Identifier: LGPL-3.0-or-later

"""User data and configuration files definitions."""

import asyncio
import json
import os
import traceback
from collections.abc import MutableMapping
from dataclasses import dataclass, field
from pathlib import Path
from typing import (
    TYPE_CHECKING, Any, ClassVar, Dict, Iterator, Optional, Tuple,
)

import pyotherside
from watchgod import Change, awatch

from .pcn.section import Section
from .pyotherside_events import LoopException, UserFileChanged
from .theme_parser import convert_to_qml
from .utils import (
    aiopen, atomic_write, deep_serialize_for_qml, dict_update_recursive,
    flatten_dict_keys,
)

if TYPE_CHECKING:
    from .backend import Backend


@dataclass
class UserFile:
    """Base class representing a user config or data file."""

    create_missing: ClassVar[bool] = True

    backend:  "Backend"              = field(repr=False)
    filename: str                    = field()
    parent:   Optional["UserFile"]   = None
    children: Dict[Path, "UserFile"] = field(default_factory=dict)

    data:        Any             = field(init=False, default_factory=dict)
    _need_write: bool            = field(init=False, default=False)
    _mtime:      Optional[float] = field(init=False, default=None)

    _reader:     Optional[asyncio.Future] = field(init=False, default=None)
    _writer:     Optional[asyncio.Future] = field(init=False, default=None)

    def __post_init__(self) -> None:
        self.data        = self.default_data
        self._need_write = self.create_missing

        if self.path.exists():
            try:
                text                        = self.path.read_text()
                self.data, self._need_write = self.deserialized(text)
            except Exception as err:  # noqa
                LoopException(str(err), err, traceback.format_exc().rstrip())

        self._reader = asyncio.ensure_future(self._start_reader())
        self._writer = asyncio.ensure_future(self._start_writer())

    @property
    def path(self) -> Path:
        """Full path of the file to read, can exist or not exist."""
        raise NotImplementedError()

    @property
    def write_path(self) -> Path:
        """Full path of the file to write, can exist or not exist."""
        return self.path

    @property
    def default_data(self) -> Any:
        """Default deserialized content to use if the file doesn't exist."""
        raise NotImplementedError()

    @property
    def qml_data(self) -> Any:
        """Data converted for usage in QML."""
        return self.data

    def deserialized(self, data: str) -> Tuple[Any, bool]:
        """Return parsed data from file text and whether to call `save()`."""
        return (data, False)

    def serialized(self) -> str:
        """Return text from `UserFile.data` that can be written to disk."""
        raise NotImplementedError()

    def save(self) -> None:
        """Inform the disk writer coroutine that the data has changed."""
        self._need_write = True

    def stop_watching(self) -> None:
        """Stop watching the on-disk file for changes."""
        if self._reader:
            self._reader.cancel()

        if self._writer:
            self._writer.cancel()

        for child in self.children.values():
            child.stop_watching()


    async def set_data(self, data: Any) -> None:
        """Set `data` and call `save()`, conveniance method for QML."""
        self.data = data
        self.save()

    async def update_from_file(self) -> None:
        """Read file at `path`, update `data` and call `save()` if needed."""

        if not self.path.exists():
            self.data        = self.default_data
            self._need_write = self.create_missing
            return

        async with aiopen(self.path) as file:
            self.data, self._need_write = self.deserialized(await file.read())

    async def _start_reader(self) -> None:
        """Disk reader coroutine, watches for file changes to update `data`."""

        while not self.path.exists():
            await asyncio.sleep(1)

        async for changes in awatch(self.path):
            try:
                ignored = 0

                for change in changes:
                    if change[0] in (Change.added, Change.modified):
                        mtime = self.path.stat().st_mtime

                        if mtime == self._mtime:
                            ignored += 1
                            continue

                        await self.update_from_file()
                        self._mtime = mtime

                    elif change[0] == Change.deleted:
                        self._mtime      = None
                        self.data        = self.default_data
                        self._need_write = self.create_missing

                if changes and ignored < len(changes):
                    UserFileChanged(type(self), self.qml_data)

                    parent = self.parent
                    while parent:
                        await parent.update_from_file()
                        UserFileChanged(type(parent), parent.qml_data)
                        parent = parent.parent

                while not self.path.exists():
                    # Prevent error spam after file gets deleted
                    await asyncio.sleep(0.5)

            except Exception as err:  # noqa
                LoopException(str(err), err, traceback.format_exc().rstrip())

    async def _start_writer(self) -> None:
        """Disk writer coroutine, update the file with a 1 second cooldown."""

        self.write_path.parent.mkdir(parents=True, exist_ok=True)

        while True:
            await asyncio.sleep(1)

            try:
                if self._need_write:
                    async with atomic_write(self.write_path) as (new, done):
                        await new.write(self.serialized())
                        done()

                    self._need_write = False
                    self._mtime      = self.write_path.stat().st_mtime

            except Exception as err:  # noqa
                self._need_write = False
                LoopException(str(err), err, traceback.format_exc().rstrip())


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

    def __getattr__(self, key: Any) -> Any:
        try:
            return self.data[key]
        except KeyError:
            return super().__getattribute__(key)

    def __setattr__(self, key: Any, value: Any) -> None:
        if key in self.__dataclass_fields__:
            super().__setattr__(key, value)
            return

        self.data[key] = value

    def __delattr__(self, key: Any) -> None:
        del self.data[key]


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

        loaded   = json.loads(data)
        all_data = self.default_data.copy()
        dict_update_recursive(all_data, loaded)
        return (all_data, loaded != all_data)

    def serialized(self) -> str:
        data = self.data
        return json.dumps(data, indent=4, ensure_ascii=False, sort_keys=True)


@dataclass
class PCNFile(MappingFile):
    """File stored in the PCN format, with machine edits in a separate JSON."""

    create_missing = False

    path_override: Optional[Path]        = None

    @property
    def path(self) -> Path:
        return self.path_override or super().path

    @property
    def write_path(self) -> Path:
        """Full path of file where programatically-done edits are stored."""
        return self.path.with_suffix(".gui.json")

    @property
    def qml_data(self) -> Dict[str, Any]:
        return deep_serialize_for_qml(self.data.as_dict())  # type: ignore

    @property
    def default_data(self) -> Section:
        return Section()

    def deserialized(self, data: str) -> Tuple[Section, bool]:
        root  = Section.from_source_code(data, self.path)
        edits = "{}"

        if self.write_path.exists():
            edits = self.write_path.read_text()

        includes_now = list(root.all_includes)

        for path, pcn in self.children.copy().items():
            if path not in includes_now:
                pcn.stop_watching()
                del self.children[path]

        for path in includes_now:
            if path not in self.children:
                self.children[path] = PCNFile(
                    self.backend,
                    filename      = path.name,
                    parent        = self,
                    path_override = path,
                )

        return (root, root.deep_merge_edits(json.loads(edits)))

    def serialized(self) -> str:
        edits = self.data.edits_as_dict()
        return json.dumps(edits, indent=4, ensure_ascii=False)

    async def set_data(self, data: Dict[str, Any]) -> None:
        self.data.deep_merge_edits({"set": data}, has_expressions=False)
        self.save()


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
class Settings(ConfigFile, PCNFile):
    """General config file for UI and backend settings"""

    filename: str = "settings.py"

    @property
    def default_data(self) -> Section:
        root  = Section.from_file("src/config/settings.py")
        edits = "{}"

        if self.write_path.exists():
            edits = self.write_path.read_text()

        root.deep_merge_edits(json.loads(edits))
        return root

    def deserialized(self, data: str) -> Tuple[Section, bool]:
        section, save = super().deserialized(data)

        if self and self.General.theme != section.General.theme:
            if hasattr(self.backend, "theme"):
                self.backend.theme.stop_watching()

            self.backend.theme = Theme(
                self.backend, section.General.theme,  # type: ignore
            )
            UserFileChanged(Theme, self.backend.theme.qml_data)

        # if self and self.General.new_theme != section.General.new_theme:
        #     self.backend.new_theme.stop_watching()
        #     self.backend.new_theme = NewTheme(
        #         self.backend, section.General.new_theme,  # type: ignore
        #     )
        #     UserFileChanged(Theme, self.backend.new_theme.qml_data)

        return (section, save)


@dataclass
class NewTheme(UserDataFile, PCNFile):
    """A theme file defining the look of QML components."""

    create_missing = False

    @property
    def path(self) -> Path:
        data_dir = Path(
            os.environ.get("MIRAGE_DATA_DIR") or
            self.backend.appdirs.user_data_dir,
        )
        return data_dir / "themes" / self.filename

    @property
    def qml_data(self) -> Dict[str, Any]:
        return flatten_dict_keys(super().qml_data, last_level=False)


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
