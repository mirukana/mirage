from typing import Any, DefaultDict

from PyQt5.QtCore import QObject, pyqtSlot

from .list_model import ListModel


class ListModelMap(QObject):
    def __init__(self, *models_args, parent: QObject = None, **models_kwargs
                ) -> None:
        super().__init__(parent)
        models_kwargs["parent"] = self

        # Set the parent to prevent item garbage-collection on the C++ side
        self.dict: DefaultDict[Any, ListModel] = \
            DefaultDict(
                lambda: ListModel(*models_args, **models_kwargs)
            )


    def __repr__(self) -> str:
        return "%s(%r)" % (type(self).__name__, self.dict)


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


    @pyqtSlot(result=str)
    def repr(self) -> str:
        return self.__repr__()


    @pyqtSlot(str, result="QVariant")
    def get(self, key) -> ListModel:
        return self.dict[key]


    @pyqtSlot(str, result=bool)
    def has(self, key) -> bool:
        return key in self.dict
