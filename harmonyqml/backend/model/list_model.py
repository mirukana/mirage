import logging
from typing import (
    Any, Callable, Dict, Iterable, List, Mapping, MutableSequence, Optional,
    Sequence, Tuple, Union
)

from PyQt5.QtCore import (
    QAbstractListModel, QModelIndex, QObject, Qt, pyqtProperty, pyqtSignal,
    pyqtSlot
)

from .list_item import ListItem

Index   = Union[int, str]
NewItem = Union[ListItem, Mapping[str, Any], Sequence]


class ListModel(QAbstractListModel):
    rolesSet     = pyqtSignal()
    changed      = pyqtSignal()
    countChanged = pyqtSignal(int)

    def __init__(self,
                 parent:       QObject,
                 initial_data: Optional[List[NewItem]]        = None,
                 container:    Callable[..., MutableSequence]  = list) -> None:
        super().__init__(parent)
        self._data: MutableSequence[ListItem] = container()

        if initial_data:
            self.extend(initial_data)


    def __repr__(self) -> str:
        return "%s(%r)" % (type(self).__name__, self._data)


    def __getitem__(self, index: Index) -> ListItem:
        return self.get(index)


    def __setitem__(self, index: Index, value: NewItem) -> None:
        self.set(index, value)


    def __delitem__(self, index: Index) -> None:
        self.remove(index)


    def __len__(self) -> int:
        return len(self._data)


    def __iter__(self) -> Iterable[NewItem]:
        return iter(self._data)


    @pyqtSlot(result=str)
    def repr(self) -> str:
        return self.__repr__()


    @pyqtProperty("QStringList", notify=rolesSet)
    def roles(self) -> Tuple[str, ...]:
        return self._data[0].roles if self._data else ()  # type: ignore


    @pyqtProperty("QVariant", notify=rolesSet)
    def mainKey(self) -> Optional[str]:
        return self._data[0].mainKey if self._data else None



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


    @pyqtSlot(str, "QVariant", result=int)
    def indexWhere(self, prop: str, is_value: Any) -> int:
        for i, item in enumerate(self._data):
            if getattr(item, prop) == is_value:
                return i

        raise ValueError(f"No item in model data with "
                         f"property {prop!r} set to {is_value!r}.")


    @pyqtSlot(int, result="QVariant")
    @pyqtSlot(str, result="QVariant")
    def get(self, index: Index) -> ListItem:
        if isinstance(index, str):
            index = self.indexWhere(self.mainKey, index)

        return self._data[index]  # type: ignore


    @pyqtSlot(int, "QVariantMap")
    def insert(self, index: int, value: NewItem) -> None:
        value = self._convert_new_value(value)

        self.beginInsertRows(QModelIndex(), index, index)

        had_data = bool(self._data)
        self._data.insert(index, value)
        if not had_data:
            self.rolesSet.emit()

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


    @pyqtSlot(int, "QVariantMap")
    @pyqtSlot(int, "QVariantMap", "QStringList")
    @pyqtSlot(str, "QVariantMap")
    @pyqtSlot(str, "QVariantMap", "QStringList")
    def update(self,
               index:        Index,
               value:        NewItem,
               ignore_roles: Sequence[str] = ()) -> None:
        value = self._convert_new_value(value)

        if isinstance(index, str):
            index = self.indexWhere(self.mainKey or value.mainKey, index)

        to_update = self._data[index]  # type: ignore

        for role in self.roles:
            if role not in ignore_roles:
                try:
                    setattr(to_update, role, getattr(value, role))
                except AttributeError:  # constant/not settable
                    pass

        qidx = QAbstractListModel.index(self, index, 0)
        self.dataChanged.emit(qidx, qidx, self.roleNames())
        self.changed.emit()


    @pyqtSlot(str, "QVariantMap")
    @pyqtSlot(str, "QVariantMap", int)
    @pyqtSlot(str, "QVariantMap", int, "QStringList")
    def upsert(self,
               where_main_key_is_value: Any,
               update_with:             NewItem,
               index_if_insert:         Optional[int] = None,
               ignore_roles:            Sequence[str] = ()) -> None:
        try:
            self.update(where_main_key_is_value, update_with, ignore_roles)
        except (IndexError, ValueError):
            self.insert(index_if_insert or len(self), update_with)



    @pyqtSlot(int, list)
    @pyqtSlot(str, list)
    def set(self, index: Index, value: NewItem) -> None:
        if isinstance(index, str):
            index = self.indexWhere(self.mainKey, index)

        qidx              = QAbstractListModel.index(self, index, 0)
        value             = self._convert_new_value(value)
        self._data[index] = value  # type: ignore
        self.dataChanged.emit(qidx, qidx, self.roleNames())
        self.changed.emit()


    @pyqtSlot(int, str, "QVariant")
    @pyqtSlot(str, str, "QVariant")
    def setProperty(self, index: Index, prop: str, value: Any) -> None:
        if isinstance(index, str):
            index = self.indexWhere(self.mainKey, index)

        setattr(self._data[index], prop, value)  # type: ignore
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
    @pyqtSlot(str)
    def remove(self, index: Index) -> None:
        if isinstance(index, str):
            index = self.indexWhere(self.mainKey, index)

        self.beginRemoveRows(QModelIndex(), index, index)
        del self._data[index]  # type: ignore
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
