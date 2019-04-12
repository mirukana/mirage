# Copyright 2019 miruka
# This file is part of harmonyqml, licensed under GPLv3.

import hashlib

from PyQt5.QtCore import QObject, pyqtProperty, pyqtSlot

from .client_manager import ClientManager
from .model.qml_models import QMLModels


class Backend(QObject):
    def __init__(self) -> None:
        super().__init__()
        self._client_manager: ClientManager = ClientManager()
        self._models:         QMLModels     = QMLModels()

        from .signal_manager import SignalManager
        self._signal_manager: SignalManager = SignalManager(self)

        # a = self._client_manager; m = self._models
        # from PyQt5.QtCore import pyqtRemoveInputHook as PRI
        # import pdb; PRI(); pdb.set_trace()

        self.clientManager.configLoad()


    @pyqtProperty("QVariant", constant=True)
    def clientManager(self):
        return self._client_manager


    @pyqtProperty("QVariant", constant=True)
    def models(self):
        return self._models


    @pyqtSlot(str, result=float)
    def hueFromString(self, string: str) -> float:
      # pylint:disable=no-self-use
        md5 = hashlib.md5(bytes(string, "utf-8")).hexdigest()
        return float("0.%s" % int(md5[-10:], 16))
