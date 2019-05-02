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


class _GetFail:
    pass


class _PopFail:
    pass


class ListModel(QAbstractListModel):
    rolesSet     = pyqtSignal()
    changed      = pyqtSignal()
    countChanged = pyqtSignal(int)

    def __init__(self,
                 initial_data: Optional[List[NewItem]]        = None,
                 container:    Callable[..., MutableSequence] = list,
                 parent:       QObject                        = None) -> None:
        super().__init__(parent)
        self._data: MutableSequence[ListItem] = container()

        if initial_data:
            self.extend(initial_data)


    def __repr__(self) -> str:
        return "%s(%r)" % (type(self).__name__, self._data)


    def __contains__(self, index: Index) -> bool:
        if isinstance(index, str):
            try:
                self.indexWhere(self.mainKey, index)
                return True
            except ValueError:
                return False

        return index in self._data


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
    @pyqtSlot(int, "QVariant", result="QVariant")
    @pyqtSlot(str, "QVariant", result="QVariant")
    def get(self, index: Index, default: Any = _GetFail()) -> ListItem:
        try:
            i_index: int = self.indexWhere(self.mainKey, index) \
                           if isinstance(index, str) else index

            return self._data[i_index]

        except (ValueError, IndexError):
            if isinstance(default, _GetFail):
                raise
            return default


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


    @pyqtSlot(int, "QVariantMap", result=int)
    @pyqtSlot(int, "QVariantMap", "QStringList", result=int)
    @pyqtSlot(str, "QVariantMap", result=int)
    @pyqtSlot(str, "QVariantMap", "QStringList", result=int)
    def update(self,
               index:        Index,
               value:        NewItem,
               ignore_roles: Sequence[str] = ()) -> int:
        value = self._convert_new_value(value)

        i_index: int = self.indexWhere(self.mainKey, index) \
                       if isinstance(index, str) else index

        to_update = self[i_index]

        for role in self.roles:
            if role not in ignore_roles:
                try:
                    setattr(to_update, role, getattr(value, role))
                except AttributeError:  # constant/not settable
                    pass

        qidx = QAbstractListModel.index(self, i_index, 0)
        self.dataChanged.emit(qidx, qidx, self.roleNames())
        self.changed.emit()
        return i_index


    @pyqtSlot(str, "QVariantMap")
    @pyqtSlot(str, "QVariantMap", int)
    @pyqtSlot(str, "QVariantMap", int, int)
    @pyqtSlot(str, "QVariantMap", int, int, "QStringList")
    def upsert(self,
               where_main_key_is:   Any,
               update_with:         NewItem,
               new_index_if_insert: Optional[int] = None,
               new_index_if_update: Optional[int] = None,
               ignore_roles:        Sequence[str] = ()) -> None:
        try:
            index = self.update(where_main_key_is, update_with, ignore_roles)
        except (IndexError, ValueError):
            self.insert(new_index_if_insert or len(self), update_with)
        else:
            if new_index_if_update:
                self.move(index, new_index_if_update)


    @pyqtSlot(int, list)
    @pyqtSlot(str, list)
    def set(self, index: Index, value: NewItem) -> None:
        i_index: int = self.indexWhere(self.mainKey, index) \
                       if isinstance(index, str) else index

        qidx                = QAbstractListModel.index(self, i_index, 0)
        value               = self._convert_new_value(value)
        self._data[i_index] = value
        self.dataChanged.emit(qidx, qidx, self.roleNames())
        self.changed.emit()


    @pyqtSlot(int, str, "QVariant")
    @pyqtSlot(str, str, "QVariant")
    def setProperty(self, index: Index, prop: str, value: Any) -> None:
        i_index: int = self.indexWhere(self.mainKey, index) \
                       if isinstance(index, str) else index

        setattr(self[i_index], prop, value)
        qidx = QAbstractListModel.index(self, i_index, 0)
        self.dataChanged.emit(qidx, qidx, self.roleNames())
        self.changed.emit()


    @pyqtSlot(int, int)
    @pyqtSlot(int, int, int)
    @pyqtSlot(str, int)
    @pyqtSlot(str, int, int)
    def move(self, from_: Index, to: int, n: int = 1) -> None:
        # pylint: disable=invalid-name
        i_from: int = self.indexWhere(self.mainKey, from_) \
                      if isinstance(from_, str) else from_

        qlast = i_from + n - 1

        if (n <= 0) or (i_from == to) or (qlast == to) or \
           not (len(self) > qlast >= 0) or \
           not len(self) >= to >= 0:
            return

        qidx  = QModelIndex()
        qto   = min(len(self), to + n if to > i_from else to)
        # print(f"self.beginMoveRows(qidx, {i_from}, {qlast}, qidx, {qto})")
        valid = self.beginMoveRows(qidx, i_from, qlast, qidx, qto)

        if not valid:
            logging.warning("Invalid move operation - %r", locals())
            return

        last = i_from + n
        cut  = self._data[i_from:last]
        del self._data[i_from:last]
        self._data[to:to] = cut

        self.endMoveRows()
        self.changed.emit()


    @pyqtSlot(int)
    @pyqtSlot(str)
    def remove(self, index: Index) -> None:
        i_index: int = self.indexWhere(self.mainKey, index) \
                       if isinstance(index, str) else index

        self.beginRemoveRows(QModelIndex(), i_index, i_index)
        del self._data[i_index]
        self.endRemoveRows()

        self.countChanged.emit(len(self))
        self.changed.emit()


    @pyqtSlot(int, result="QVariant")
    @pyqtSlot(str, result="QVariant")
    def pop(self, index: Index, default: Any = _PopFail()) -> ListItem:
        try:
            i_index: int = self.indexWhere(self.mainKey, index) \
                           if isinstance(index, str) else index
            item = self[i_index]

        except (ValueError, IndexError):
            if isinstance(default, _PopFail):
                raise
            return default

        self.beginRemoveRows(QModelIndex(), i_index, i_index)
        del self._data[i_index]
        self.endRemoveRows()

        self.countChanged.emit(len(self))
        self.changed.emit()
        return item


    @pyqtSlot()
    def clear(self) -> None:
        # Reimplemented for performance reasons (begin/endRemoveRows)
        self.beginRemoveRows(QModelIndex(), 0, len(self))
        self._data.clear()
        self.endRemoveRows()

        self.countChanged.emit(len(self))
        self.changed.emit()
