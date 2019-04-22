# Copyright 2019 miruka
# This file is part of harmonyqml, licensed under GPLv3.

from typing import Deque

from PyQt5.QtCore import QObject, pyqtProperty

from .list_model import ListModel
from .list_model_map import ListModelMap


class QMLModels(QObject):
    def __init__(self, parent: QObject) -> None:
        super().__init__(parent)
        self._accounts:    ListModel    = ListModel(parent)
        self._rooms:       ListModelMap = ListModelMap(parent)
        self._room_events: ListModelMap = ListModelMap(parent,
                                                       models_container=Deque)


    @pyqtProperty(ListModel, constant=True)
    def accounts(self):
        return self._accounts


    @pyqtProperty("QVariant", constant=True)
    def rooms(self):
        return self._rooms


    @pyqtProperty("QVariant", constant=True)
    def roomEvents(self):
        return self._room_events
