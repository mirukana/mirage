# Copyright 2019 miruka
# This file is part of harmonyqml, licensed under GPLv3.

from PyQt5.QtCore import QObject, pyqtProperty, pyqtSignal

from .list_model import ListModel
from .list_model_map import ListModelMap


class QMLModels(QObject):
    roomsChanged = pyqtSignal()


    def __init__(self) -> None:
        super().__init__()
        self._accounts:    ListModel    = ListModel()
        self._rooms:       ListModelMap = ListModelMap()
        self._room_events: ListModelMap = ListModelMap()


    @pyqtProperty(ListModel, constant=True)
    def accounts(self):
        return self._accounts


    @pyqtProperty("QVariant", notify=roomsChanged)
    def rooms(self):
        return self._rooms


    @pyqtProperty("QVariant", constant=True)
    def roomEvents(self):
        return self._room_events
