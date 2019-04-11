# Copyright 2019 miruka
# This file is part of harmonyqml, licensed under GPLv3.

from typing import Any, DefaultDict, Dict, NamedTuple, Optional

from PyQt5.QtCore import QDateTime, QObject, pyqtProperty, pyqtSlot

from matrix_client.user import User as MatrixUser

from ..base import Backend, User
from .client_manager import ClientManager


class MatrixNioBackend(Backend):
    def __init__(self) -> None:
        super().__init__()
        self._client_manager = ClientManager()

        # a = self._client_manager
        # from PyQt5.QtCore import pyqtRemoveInputHook as PRI; import pdb; PRI(); pdb.set_trace()

        self._client_manager.configLoad()


    @pyqtProperty("QVariant")
    def clientManager(self):
        return self._client_manager
