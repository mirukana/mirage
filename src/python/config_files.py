import asyncio
import json
import logging as log
from pathlib import Path
from typing import Any, Dict

import aiofiles
from dataclasses import dataclass, field

from . import pyotherside
from .backend import Backend
from .theme_parser import convert_to_qml
from .utils import dict_update_recursive

JsonData = Dict[str, Any]

WRITE_LOCK = asyncio.Lock()


@dataclass
class ConfigFile:
    backend:  Backend = field(repr=False)
    filename: str     = field()

    _cached_read: str = field(default="", init=False, compare=False)

    @property
    def path(self) -> Path:
        return Path(self.backend.app.appdirs.user_config_dir) / self.filename


    async def default_data(self):
        return ""


    async def read(self):
        if self._cached_read:
            log.debug("Returning cached config %s", type(self).__name__)
            return self._cached_read

        log.debug("Reading config %s at %s", type(self).__name__, self.path)
        self._cached_read = self.path.read_text()
        return self._cached_read


    async def write(self, data) -> None:
        async with WRITE_LOCK:
            self.path.parent.mkdir(parents=True, exist_ok=True)

            async with aiofiles.open(self.path, "w") as new:
                await new.write(data)


@dataclass
class JSONConfigFile(ConfigFile):
    async def default_data(self) -> JsonData:
        return {}


    async def read(self) -> JsonData:
        try:
            data = json.loads(await super().read())
        except (FileNotFoundError, json.JSONDecodeError):
            data = {}

        all_data = await self.default_data()
        dict_update_recursive(all_data, data)

        if len(data) != len(all_data):
            await self.write(all_data)

        return all_data


    async def write(self, data: JsonData) -> None:
        js = json.dumps(data, indent=4, ensure_ascii=False, sort_keys=True)
        await super().write(js)


@dataclass
class Accounts(JSONConfigFile):
    filename: str = "accounts.json"

    async def any_saved(self) -> bool:
        return bool(await self.read())


    async def add(self, user_id: str) -> None:
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
        await self.write({
            uid: info
            for uid, info in (await self.read()).items() if uid != user_id
        })


@dataclass
class UISettings(JSONConfigFile):
    filename: str = "settings.json"

    async def default_data(self) -> JsonData:
        return {
            "alertOnMessageForMsec": 4000,
            "theme": "Default.qpl",
            "writeAliases": {},
            "keys": {
                "reloadConfig":     ["Alt+Shift+R"],
                "scrollUp":         ["Alt+Up", "Alt+K"],
                "scrollDown":       ["Alt+Down", "Alt+J"],
                "filterRooms":      ["Alt+S", "Ctrl+S"],
                "goToPreviousRoom": ["Alt+Shift+Up", "Alt+Shift+K"],
                "goToNextRoom":     ["Alt+Shift+Down", "Alt+Shift+J"],
                "startDebugger":    ["Alt+Shift+D"],
            },
        }


@dataclass
class UIState(JSONConfigFile):
    filename: str = "state.json"

    @property
    def path(self) -> Path:
        return Path(self.backend.app.appdirs.user_data_dir) / self.filename


    async def default_data(self) -> JsonData:
        return {
            "collapseAccounts":    {},
            "page":                "Pages/Default.qml",
            "pageProperties":      {},
            "sidePaneFilter":      "",
            "sidePaneManualWidth": None,
        }


@dataclass
class Theme(ConfigFile):
    @property
    def path(self) -> Path:
        data_dir = Path(self.backend.app.appdirs.user_data_dir)
        return data_dir / "themes" / self.filename


    async def default_data(self) -> str:
        async with aiofiles.open("src/themes/Default.qpl", "r") as file:
            return await file.read()


    async def read(self) -> str:
        if not pyotherside.AVAILABLE:
            return ""

        if not self.path.exists():
            await self.write(await self.default_data())

        return convert_to_qml(await super().read())
