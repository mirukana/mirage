import asyncio
import json
import random
from pathlib import Path
from typing import Dict, Optional, Tuple

from atomicfile import AtomicFile

from .app import App
from .events import users
from .html_filter import HTML_FILTER
from .matrix_client import MatrixClient

SavedAccounts = Dict[str, Dict[str, str]]
CONFIG_LOCK   = asyncio.Lock()


class Backend:
    def __init__(self, app: App) -> None:
        self.app = app
        self.clients: Dict[str, MatrixClient] = {}


    def __repr__(self) -> str:
        return f"{type(self).__name__}(clients={self.clients!r})"


    # Clients management

    async def login_client(self,
                           user:       str,
                           password:   str,
                           device_id:  Optional[str] = None,
                           homeserver: str = "https://matrix.org") -> str:
        client = MatrixClient(
            user=user, homeserver=homeserver, device_id=device_id
        )
        await client.login(password)
        self.clients[client.user_id] = client
        users.AccountUpdated(client.user_id)
        return client.user_id


    async def resume_client(self,
                            user_id:    str,
                            token:      str,
                            device_id:  str,
                            homeserver: str = "https://matrix.org") -> None:
        client = MatrixClient(
            user=user_id, homeserver=homeserver, device_id=device_id
        )
        await client.resume(user_id=user_id, token=token, device_id=device_id)
        self.clients[client.user_id] = client
        users.AccountUpdated(client.user_id)


    async def logout_client(self, user_id: str) -> None:
        client = self.clients.pop(user_id, None)
        if client:
            await client.logout()
            users.AccountDeleted(user_id)


    async def logout_all_clients(self) -> None:
        await asyncio.gather(*(
            self.logout_client(user_id) for user_id in self.clients.copy()
        ))


    # Saved account operations - TODO: Use aiofiles?

    @property
    def saved_accounts_path(self) -> Path:
        return Path(self.app.appdirs.user_config_dir) / "accounts.json"


    @property
    def saved_accounts(self) -> SavedAccounts:
        try:
            return json.loads(self.saved_accounts_path.read_text())
        except (json.JSONDecodeError, FileNotFoundError):
            return {}


    async def has_saved_accounts(self) -> bool:
        return bool(self.saved_accounts)


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
            resume(uid, info) for uid, info in self.saved_accounts.items()
        ))


    async def save_account(self, user_id: str) -> None:
        client = self.clients[user_id]

        await self._write_config({
            **self.saved_accounts,
            client.user_id: {
                "homeserver": client.homeserver,
                "token":      client.access_token,
                "device_id":  client.device_id,
            }
        })


    async def forget_account(self, user_id: str) -> None:
        await self._write_config({
            uid: info
            for uid, info in self.saved_accounts.items() if uid != user_id
        })


    async def _write_config(self, accounts: SavedAccounts) -> None:
        js = json.dumps(accounts, indent=4, ensure_ascii=False, sort_keys=True)

        async with CONFIG_LOCK:
            self.saved_accounts_path.parent.mkdir(parents=True, exist_ok=True)

            with AtomicFile(self.saved_accounts_path, "w") as new:
                new.write(js)


    # General functions

    async def request_user_update_event(self, user_id: str) -> None:
        client = self.clients.get(user_id,
                                  random.choice(tuple(self.clients.values())))
        await client.request_user_update_event(user_id)


    @staticmethod
    def inlinify(html: str) -> str:
        return HTML_FILTER.filter_inline(html)
