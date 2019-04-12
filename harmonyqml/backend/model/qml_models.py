# Copyright 2019 miruka
# This file is part of harmonyqml, licensed under GPLv3.

from typing import DefaultDict, Dict

from PyQt5.QtCore import QObject, pyqtProperty

from .list_model import ListModel, _QtListModel


class QMLModels(QObject):
    def __init__(self) -> None:
        super().__init__()
        self._accounts: ListModel                   = ListModel()
        self._rooms:    DefaultDict[str, ListModel] = DefaultDict(ListModel)
        self._messages: DefaultDict[str, ListModel] = DefaultDict(ListModel)


    @pyqtProperty(_QtListModel, constant=True)
    def accounts(self) -> _QtListModel:
        return self._accounts.qt_model


    @pyqtProperty("QVariantMap", constant=True)
    def rooms(self) -> Dict[str, _QtListModel]:
        return {user_id: l.qt_model for user_id, l in self._rooms.items()}


    @pyqtProperty("QVariantMap", constant=True)
    def messages(self) -> Dict[str, _QtListModel]:
        return {room_id: l.qt_model for room_id, l in self._messages.items()}
