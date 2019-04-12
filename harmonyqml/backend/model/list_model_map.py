from typing import Any, DefaultDict

from PyQt5.QtCore import QObject, pyqtSlot

from .list_model import ListModel


class ListModelMap(QObject):
    def __init__(self) -> None:
        super().__init__()
        self.dict: DefaultDict[Any, ListModel] = DefaultDict(ListModel)


    @pyqtSlot(str, result="QVariant")
    def get(self, key) -> ListModel:
        return self.dict[key]


    def __getitem__(self, key) -> ListModel:
        return self.dict[key]


    def __setitem__(self, key, value: ListModel) -> None:
        self.dict[key] = value


    def __detitem__(self, key) -> None:
        del self.dict[key]


    def __iter__(self):
        return iter(self.dict)


    def __len__(self) -> int:
        return len(self.dict)
