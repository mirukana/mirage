from typing import Any, Callable, DefaultDict, MutableSequence

from PyQt5.QtCore import QObject, pyqtSlot

from .list_model import ListModel


class ListModelMap(QObject):
    def __init__(self, models_container: Callable[..., MutableSequence] = list
                ) -> None:
        super().__init__()

        # Set the parent to prevent item garbage-collection on the C++ side
        self.dict: DefaultDict[Any, ListModel] = \
            DefaultDict(lambda: ListModel(parent    = self,
                                          container = models_container))


    @pyqtSlot(str, result="QVariant")
    def get(self, key) -> ListModel:
        return self.dict[key]


    def __getitem__(self, key) -> ListModel:
        return self.dict[key]


    def __setitem__(self, key, value: ListModel) -> None:
        value.setParent(self)
        self.dict[key] = value


    def __detitem__(self, key) -> None:
        del self.dict[key]


    def __iter__(self):
        return iter(self.dict)


    def __len__(self) -> int:
        return len(self.dict)
