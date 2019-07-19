# Copyright 2019 miruka
# This file is part of harmonyqml, licensed under LGPLv3.

import asyncio
import json
from pathlib import Path
from typing import Any, Dict

import aiofiles
from dataclasses import dataclass, field

from .backend import Backend

JsonData = Dict[str, Any]

WRITE_LOCK = asyncio.Lock()


@dataclass
class ConfigFile:
    backend:  Backend = field()
    filename: str     = field()

    @property
    def path(self) -> Path:
        # pylint: disable=no-member
        return Path(self.backend.app.appdirs.user_config_dir) / self.filename


@dataclass
class JSONConfigFile(ConfigFile):
    async def default_data(self) -> JsonData:
        return {}


    async def read(self) -> JsonData:
        try:
            return json.loads(self.path.read_text())
        except (json.JSONDecodeError, FileNotFoundError):
            return await self.default_data()


    async def write(self, data: JsonData) -> None:
        js = json.dumps(data, indent=4, ensure_ascii=False, sort_keys=True)

        async with WRITE_LOCK:
            self.path.parent.mkdir(parents=True, exist_ok=True)

            async with aiofiles.open(self.path, "w") as new:
                await new.write(js)


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
            "write_aliases": {}
        }
