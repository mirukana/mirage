from typing import Any, Callable, DefaultDict, MutableSequence

from PyQt5.QtCore import QObject, pyqtSlot

from .list_model import ListModel


class ListModelMap(QObject):
    def __init__(self,
                 models_container: Callable[..., MutableSequence] = list,
                 parent:           QObject = None) -> None:
        super().__init__(parent)

        # Set the parent to prevent item garbage-collection on the C++ side
        self.dict: DefaultDict[Any, ListModel] = \
            DefaultDict(
                lambda: ListModel(container=models_container, parent=self)
            )


    @pyqtSlot(str, result="QVariant")
    def get(self, key) -> ListModel:
        return self.dict[key]


    @pyqtSlot(str, result=bool)
    def has(self, key) -> bool:
        return key in self.dict


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
