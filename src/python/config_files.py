# Copyright 2019 miruka
# This file is part of harmonyqml, licensed under LGPLv3.

import asyncio
import json
from pathlib import Path
from typing import Any, Dict

import aiofiles
from dataclasses import dataclass, field

from .backend import Backend
from .theme_parser import convert_to_qml
from .utils import dict_update_recursive

JsonData = Dict[str, Any]

WRITE_LOCK = asyncio.Lock()


@dataclass
class ConfigFile:
    backend:  Backend = field(repr=False)
    filename: str     = field()

    @property
    def path(self) -> Path:
        # pylint: disable=no-member
        return Path(self.backend.app.appdirs.user_config_dir) / self.filename


    async def default_data(self):
        return ""


    async def read(self):
        try:
            return self.path.read_text()
        except FileNotFoundError:
            return await self.default_data()


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
        except json.JSONDecodeError:
            data = {}

        all_data = await self.default_data()
        dict_update_recursive(all_data, data)
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
        # pylint: disable=no-member
        client = self.backend.clients[user_id]

        await self.write({
            **await self.read(),
            client.user_id: {
                "homeserver": client.homeserver,
                "token":      client.access_token,
                "device_id":  client.device_id,
            }
        })


    async def delete(self, user_id: str) -> None:
        await self.write({
            uid: info
            for uid, info in (await self.read()).items() if uid != user_id
        })


@dataclass
class UISettings(JSONConfigFile):
    filename: str = "ui-settings.json"

    async def default_data(self) -> JsonData:
        return {
            "theme":        "Default.qpl",
            "writeAliases": {},
            "keys": {
                "reloadConfig":  ["Alt+R"],
                "scrollUp":      ["Alt+Up", "Alt+K"],
                "scrollDown":    ["Alt+Down", "Alt+J"],
                "startDebugger": ["Alt+Shift+D"],
            },
        }


@dataclass
class UIState(JSONConfigFile):
    filename: str = "ui-state.json"

    @property
    def path(self) -> Path:
        # pylint: disable=no-member
        return Path(self.backend.app.appdirs.user_data_dir) / self.filename


    async def default_data(self) -> JsonData:
        return {
            "collapseAccounts":    {},
            "collapseCategories":  {},
            "page":                "Pages/Default.qml",
            "pageProperties":      {},
            "sidePaneManualWidth": None,
        }


@dataclass
class Theme(ConfigFile):
    @property
    def path(self) -> Path:
        # pylint: disable=no-member
        data_dir = Path(self.backend.app.appdirs.user_data_dir)
        user_file = data_dir / "themes" / self.filename

        if user_file.exists():
            return user_file

        return Path("src") / "themes" / self.filename


    async def default_data(self) -> str:
        async with aiofiles.open("src/themes/Default.qpl", "r") as file:
            return file.read()


    async def read(self) -> str:
        return convert_to_qml(await super().read())


    async def write(self, data: str) -> None:
        raise NotImplementedError()
