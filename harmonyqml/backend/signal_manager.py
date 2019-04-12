# Copyright 2019 miruka
# This file is part of harmonyqml, licensed under GPLv3.

from PyQt5.QtCore import QObject

from .backend import Backend
from .client import Client
from .model.items import User


class SignalManager(QObject):
    def __init__(self, backend: Backend) -> None:
        super().__init__()
        self.backend = backend
        self.connectAll()


    def connectAll(self) -> None:
        be = self.backend
        be.clientManager.clientAdded.connect(self.onClientAdded)
        be.clientManager.clientDeleted.connect(self.onClientDeleted)


    def onClientAdded(self, client: Client) -> None:
        self.backend.models.accounts.append(User(
            user_id      = client.nio.user_id,
            display_name = client.nio.user_id.lstrip("@").split(":")[0],
        ))


    def onClientDeleted(self, user_id: str) -> None:
        accs = self.backend.models.accounts
        del accs[accs.indexWhere("user_id", user_id)]
