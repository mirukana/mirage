import asyncio
import json
import logging as log
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any, Dict

import aiofiles

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
        return Path(self.backend.app.appdirs.user_config_dir) / self.filename


    async def default_data(self):
        return ""


    async def read(self):
        log.debug("Reading config %s at %s", type(self).__name__, self.path)
        return self.path.read_text()


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

        if data != all_data:
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
                "toggleDebugConsole":  ["Alt+Shift+C"],
                "reloadConfig":        ["Alt+Shift+R"],

                "zoomIn":    ["Ctrl+Plus", "Ctrl+Shift+Plus"],
                "zoomOut":   ["Ctrl+Minus", "Ctrl+Shift+Minus"],
                "zoomReset": ["Ctrl+Equal", "Ctrl+Shift+Backspace"],

                "scrollUp":       ["Alt+Up", "Alt+K"],
                "scrollDown":     ["Alt+Down", "Alt+J"],
                "scrollPageUp":   ["Alt+Ctrl+Up", "Alt+Ctrl+K", "PageUp"],
                "scrollPageDown": ["Alt+Ctrl+Down", "Alt+Ctrl+J", "PageDown"],
                "scrollToTop":
                    ["Alt+Ctrl+Shift+Up", "Alt+Ctrl+Shift+K", "Home"],
                "scrollToBottom":
                    ["Alt+Ctrl+Shift+Down", "Alt+Ctrl+Shift+J", "End"],

                "previousTab": ["Alt+Shift+Left", "Alt+Shift+H"],
                "nextTab":     ["Alt+Shift+Right", "Alt+Shift+L"],

                "focusSidePane":   ["Alt+S"],
                "clearRoomFilter": ["Alt+Shift+S"],
                "accountSettings": ["Alt+A"],
                "addNewChat":      ["Alt+N"],
                "addNewAccount":   ["Alt+Shift+N"],

                "goToLastPage":          ["Ctrl+Tab"],
                "goToPreviousRoom":      ["Alt+Shift+Up", "Alt+Shift+K"],
                "goToNextRoom":          ["Alt+Shift+Down", "Alt+Shift+J"],
                "toggleCollapseAccount": [ "Alt+O"],

                "clearRoomMessages": ["Ctrl+L"],
                "sendFile": ["Alt+F"],
                "sendFileFromPathInClipboard": ["Alt+Shift+F"],
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
        async with aiofiles.open("src/themes/Default.qpl") as file:
            return await file.read()


    async def read(self) -> str:
        if not self.path.exists():
            await self.write(await self.default_data())

        return convert_to_qml(await super().read())
