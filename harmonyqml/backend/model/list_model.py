import logging
from typing import (
    Any, Callable, Dict, Iterable, List, Mapping, MutableSequence, Optional,
    Sequence, Tuple, Union
)

from PyQt5.QtCore import (
    QAbstractListModel, QModelIndex, QObject, Qt, pyqtProperty, pyqtSignal,
    pyqtSlot
)

from .items import ListItem

NewItem = Union[ListItem, Mapping[str, Any], Sequence]


class ListModel(QAbstractListModel):
    changed      = pyqtSignal()
    countChanged = pyqtSignal(int)

    def __init__(self,
                 initial_data: Optional[List[NewItem]]        = None,
                 container:    Callable[..., MutableSequence]  = list,
                 parent:       Optional[QObject]               = None) -> None:
        super().__init__(parent)
        self._data: MutableSequence[ListItem] = container()

        if initial_data:
            self.extend(initial_data)


    def __repr__(self) -> str:
        return "%s(%r)" % (type(self).__name__, self._data)


    def __getitem__(self, index):
        return self._data[index]


    def __setitem__(self, index, value) -> None:
        self.set(index, value)


    def __delitem__(self, index) -> None:
        self.remove(index)


    def __len__(self) -> int:
        return len(self._data)


    def __iter__(self):
        return iter(self._data)


    @pyqtProperty(list, constant=True)
    def roles(self) -> Tuple[str, ...]:
        return self._data[0].roles if self._data else ()  # type: ignore


    def roleNames(self) -> Dict[int, bytes]:
        return {Qt.UserRole + i: bytes(f, "utf-8")
                for i, f in enumerate(self.roles, 1)} \
                if self._data else {}


    def data(self, index: QModelIndex, role: int = Qt.DisplayRole) -> Any:
        if role <= Qt.UserRole:
            return None

        return getattr(self._data[index.row()],
                       str(self.roleNames()[role], "utf8"))


    def rowCount(self, _: QModelIndex = QModelIndex()) -> int:
        return len(self)


    def _convert_new_value(self, value: NewItem) -> ListItem:
        def convert() -> ListItem:
            if self._data and isinstance(value, Mapping):
                if not set(value.keys()) <= set(self.roles):
                    raise ValueError(
                        f"{value}: must have all these keys: {self.roles}"
                    )

                return type(self._data[0])(**value)

            if not self._data and isinstance(value, Mapping):
                raise NotImplementedError("First item must be set from Python")

            if self._data and isinstance(value, type(self._data[0])):
                return value

            if not self._data and isinstance(value, ListItem):
                return value

            raise TypeError("%r: must be mapping or %s" % (
                value,
                type(self._data[0]).__name__ if self._data else "ListItem"
            ))

        value = convert()
        value.setParent(self)
        return value


    @pyqtProperty(int, notify=countChanged)
    def count(self) -> int:
        return len(self)


    @pyqtSlot(int, result="QVariant")
    def get(self, index: int) -> ListItem:
        return self._data[index]


    @pyqtSlot(str, "QVariant", result=int)
    def indexWhere(self, prop: str, is_value: Any) -> int:
        for i, item in enumerate(self._data):
            if getattr(item, prop) == is_value:
                return i

        raise ValueError(f"No item in model data with "
                         f"property {prop!r} set to {is_value!r}.")


    @pyqtSlot(str, "QVariant", result="QVariant")
    def getWhere(self, prop: str, is_value: Any) -> ListItem:
        return self.get(self.indexWhere(prop, is_value))


    @pyqtSlot(int, "QVariantMap")
    def insert(self, index: int, value: NewItem) -> None:
        value = self._convert_new_value(value)
        self.beginInsertRows(QModelIndex(), index, index)
        self._data.insert(index, value)
        self.endInsertRows()

        self.countChanged.emit(len(self))
        self.changed.emit()


    @pyqtSlot("QVariantMap")
    def append(self, value: NewItem) -> None:
        self.insert(len(self), value)


    @pyqtSlot(list)
    def extend(self, values: Iterable[NewItem]) -> None:
        for val in values:
            self.append(val)


    @pyqtSlot("QVariantMap")
    def update(self, index: int, value: NewItem) -> None:
        value = self._convert_new_value(value)

        for role in self.roles:
            if role in value.no_update:
                continue

            setattr(self._data[index], role, getattr(value, role))

        qidx = QAbstractListModel.index(self, index, 0)
        self.dataChanged.emit(qidx, qidx, self.roleNames())
        self.changed.emit()


    @pyqtSlot(str, "QVariant", "QVariantMap")
    def updateOrAppendWhere(
            self, prop: str, is_value: Any, update_with: NewItem
    ) -> None:
        try:
            index = self.indexWhere(prop, is_value)
            self.update(index, update_with)
        except ValueError:
            index = len(self)
            self.append(update_with)



    @pyqtSlot(int, list)
    def set(self, index: int, value: NewItem) -> None:
        qidx              = QAbstractListModel.index(self, index, 0)
        value             = self._convert_new_value(value)
        self._data[index] = value
        self.dataChanged.emit(qidx, qidx, self.roleNames())
        self.changed.emit()


    @pyqtSlot(int, str, "QVariant")
    def setProperty(self, index: int, prop: str, value: Any) -> None:
        setattr(self._data[index], prop, value)
        qidx = QAbstractListModel.index(self, index, 0)
        self.dataChanged.emit(qidx, qidx, self.roleNames())
        self.changed.emit()


    @pyqtSlot(int, int)
    @pyqtSlot(int, int, int)
    def move(self, from_: int, to: int, n: int = 1) -> None:
        # pylint: disable=invalid-name
        qlast = from_ + n - 1

        if (n <= 0) or (from_ == to) or (qlast == to) or \
           not (len(self) > qlast >= 0) or \
           not len(self) >= to >= 0:
            return

        qidx  = QModelIndex()
        qto   = min(len(self), to + n if to > from_ else to)
        # print(f"self.beginMoveRows(qidx, {from_}, {qlast}, qidx, {qto})")
        valid = self.beginMoveRows(qidx, from_, qlast, qidx, qto)

        if not valid:
            logging.warning("Invalid move operation - %r", locals())
            return

        last = from_ + n
        cut  = self._data[from_:last]
        del self._data[from_:last]
        self._data[to:to] = cut

        self.endMoveRows()
        self.changed.emit()


    @pyqtSlot(int)
    def remove(self, index: int) -> None:
        self.beginRemoveRows(QModelIndex(), index, index)
        del self._data[index]
        self.endRemoveRows()

        self.countChanged.emit(len(self))
        self.changed.emit()


    @pyqtSlot()
    def clear(self) -> None:
        # Reimplemented for performance reasons (begin/endRemoveRows)
        self.beginRemoveRows(QModelIndex(), 0, len(self))
        self._data.clear()
        self.endRemoveRows()

        self.countChanged.emit(len(self))
        self.changed.emit()
