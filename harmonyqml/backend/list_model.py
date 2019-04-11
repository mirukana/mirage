import logging
from collections.abc import MutableSequence
from typing import Any, Dict, List, Mapping, Optional, Sequence, Tuple, Union

from namedlist import namedlist
from PyQt5.QtCore import (
    QAbstractListModel, QModelIndex, Qt, pyqtProperty, pyqtSlot
)

NewValue = Union[Mapping[str, Any], Sequence]


class _QtListModel(QAbstractListModel):
    def __init__(self) -> None:
        super().__init__()
        self._ref_namedlist          = None
        self._roles: Tuple[str, ...] = ()
        self._list:  list            = []

    def roleNames(self) -> Dict[int, bytes]:
        return {Qt.UserRole + i: bytes(f, "utf-8")
                for i, f in enumerate(self._roles, 1)}


    def data(self, index: QModelIndex, role: int = Qt.DisplayRole) -> Any:
        if role <= Qt.UserRole:
            return None

        return self._list[index.row()][role - Qt.UserRole - 1]


    def rowCount(self, _: QModelIndex = QModelIndex()) -> int:
        return len(self._list)


    def _convert_new_value(self, value: NewValue) -> Any:
        if isinstance(value, Mapping):
            if not self._ref_namedlist:
                self._ref_namedlist = namedlist("ListItem", value.keys())
                self._roles         = tuple(value.keys())

            return self._ref_namedlist(**value)  # type: ignore

        if isinstance(value, Sequence):
            if not self._ref_namedlist:
                try:
                    self._ref_namedlist = namedlist(
                        value.__class__.__name__, value._fields  # type: ignore
                    )
                    self._roles = tuple(value._fields)  # type: ignore
                except AttributeError:
                    raise TypeError(
                        "Need a mapping/dict, namedtuple or namedlist as "
                        "first value to set allowed keys/fields."
                    )

            return self._ref_namedlist(*value)  # type: ignore


        raise TypeError("Value must be a mapping or sequence.")


    @pyqtSlot(int, result="QVariantMap")
    def get(self, index: int) -> Dict[str, Any]:
        return self._list[index]._asdict()


    @pyqtSlot(int, list)
    def insert(self, index: int, value: NewValue) -> None:
        value = self._convert_new_value(value)
        self.beginInsertRows(QModelIndex(), index, index)
        self._list.insert(index, value)
        self.endInsertRows()


    @pyqtProperty(int)
    def count(self) -> int:
        return self.rowCount()


    @pyqtSlot(list)
    def append(self, value: NewValue) -> None:
        self.insert(self.rowCount(), value)


    @pyqtSlot(int, list)
    def set(self, index: int, value: NewValue) -> None:
        qidx              = self.index(index, 0)
        value             = self._convert_new_value(value)
        self._list[index] = value
        self.dataChanged.emit(qidx, qidx, self.roleNames())


    @pyqtSlot(int, str, "QVariant")
    def setProperty(self, index: int, prop: str, value: Any) -> None:
        self._list[index][self._roles.index(prop)] = value
        qidx = self.index(index, 0)
        self.dataChanged.emit(qidx, qidx, self.roleNames())


    # pylint: disable=invalid-name
    @pyqtSlot(int, int)
    @pyqtSlot(int, int, int)
    def move(self, from_: int, to: int, n: int = 1) -> None:
        qlast = from_ + n - 1

        if (n <= 0) or (from_ == to) or (qlast == to) or \
           not (self.rowCount() > qlast >= 0) or \
           not self.rowCount() >= to >= 0:
            logging.warning("No need for move or out of range")
            return

        qidx  = QModelIndex()
        qto   = min(self.rowCount(), to + n if to > from_ else to)
        # print(f"self.beginMoveRows(qidx, {from_}, {qlast}, qidx, {qto})")
        valid = self.beginMoveRows(qidx, from_, qlast, qidx, qto)

        if not valid:
            logging.warning("Invalid move operation")
            return

        last = from_ + n
        cut  = self._list[from_:last]
        del self._list[from_:last]
        self._list[to:to] = cut

        self.endMoveRows()


    @pyqtSlot(int)
    def remove(self, index: int) -> None:
        self.beginRemoveRows(QModelIndex(), index, index)
        del self._list[index]
        self.endRemoveRows()


    @pyqtSlot()
    def clear(self) -> None:
        # Reimplemented for performance reasons (begin/endRemoveRows)
        self.beginRemoveRows(QModelIndex(), 0, self.rowCount())
        self._list.clear()
        self.endRemoveRows()


class ListModel(MutableSequence):
    def __init__(self, initial_data: Optional[List[NewValue]] = None) -> None:
        super().__init__()
        self.qt_model = _QtListModel()

        if initial_data:
            self.extend(initial_data)


    def __repr__(self) -> str:
        return "%s[%s]" % (type(self).__name__,
                           ", ".join((repr(i) for i in self)))

    def __getitem__(self, index):
        # pylint: disable=protected-access
        return self.qt_model._list[index]


    def __setitem__(self, index, value) -> None:
        self.qt_model.set(index, value)


    def __delitem__(self, index) -> None:
        self.qt_model.remove(index)


    def __len__(self) -> int:
        return self.qt_model.rowCount()


    def insert(self, index: int, value: NewValue) -> None:
        self.qt_model.insert(index, value)


    def setProperty(self, index: int, prop: str, value: Any) -> None:
        "Set role of the item at *index* to *value*."
        self.qt_model.setProperty(index, prop, value)


    # pylint: disable=invalid-name
    def move(self, from_: int, to: int, n: int = 1) -> None:
        "Move *n* items *from_* index *to* another."
        self.qt_model.move(from_, to, n)


    def clear(self) -> None:
        self.qt_model.clear()
