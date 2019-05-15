from typing import Any, Callable, Dict, Optional

from PyQt5.QtCore import (
    QModelIndex, QObject, QSortFilterProxyModel, Qt, pyqtProperty, pyqtSignal,
    pyqtSlot
)

from .list_model import ListModel


class SortFilterProxy(QSortFilterProxyModel):
    sortByRoleChanged   = pyqtSignal()
    filterByRoleChanged = pyqtSignal()
    filterChanged       = pyqtSignal()
    countChanged        = pyqtSignal(int)

    def __init__(self,
                 source_model:   ListModel,
                 sort_by_role:   str  = "",
                 filter_by_role: str  = "",
                 ascending:      bool = True,
                 sort_func:      Optional[Callable[[Any, Any], bool]] = None,
                 parent:         QObject = None) -> None:
        super().__init__(parent)
        self.setDynamicSortFilter(False)
        self.setFilterCaseSensitivity(Qt.CaseInsensitive)

        self.setSourceModel(source_model)
        source_model.rolesSet.connect(self._set_internal_sort_filter_role)
        source_model.countChanged.connect(self.countChanged.emit)
        source_model.changed.connect(self._apply_sort)

        self.sort_func = sort_func

        self._sort_by_role = ""
        self.sortByRole    = sort_by_role
        self.ascending     = ascending

        self._filter_by_role = ""
        self.filterByRole    = filter_by_role

        self._filter = None
        self.filterChanged.connect(
            lambda: self.countChanged.emit(self.rowCount())
        )


    # Sorting and filtering

    @pyqtProperty(str, notify=sortByRoleChanged)
    def sortByRole(self) -> str:
        return self._sort_by_role


    @sortByRole.setter  # type: ignore
    def sortByRole(self, role: str) -> None:
        self._sort_by_role = role
        self._set_internal_sort_filter_role()
        self.sortByRoleChanged.emit()


    @pyqtProperty(str, notify=filterByRoleChanged)
    def filterByRole(self) -> str:
        return self._filter_by_role


    @filterByRole.setter  # type: ignore
    def filterByRole(self, role: str) -> None:
        self._filter_by_role = role
        self._set_internal_sort_filter_role()
        self.filterByRoleChanged.emit()


    @pyqtProperty(str, notify=filterChanged)
    def filter(self) -> str:
        return self._filter


    @filter.setter  # type: ignore
    def filter(self, pattern: str) -> None:
        self._filter = pattern
        self.setFilterWildcard(pattern or "*")
        self.filterChanged.emit()


    def _set_internal_sort_filter_role(self) -> None:
        numbers = self.sourceModel().roleNumbers()
        try:
            self.setSortRole(numbers[self.sortByRole])
        except (AttributeError, KeyError):
            # Model doesn't have its roles set yet (empty model), or no
            # self.sortByRole passed
            pass

        try:
            self.setFilterRole(numbers[self.filterByRole])
        except (AttributeError, KeyError):
            pass


    def _apply_sort(self) -> None:
        order = Qt.AscendingOrder if self.ascending else Qt.DescendingOrder
        self.sort(0, order)


    # Sorting/filtering implementations


    def lessThan(self, source_left: QModelIndex, source_right: QModelIndex
                ) -> bool:
        left  = self.sourceModel()[source_left.row()]
        right = self.sourceModel()[source_right.row()]

        if self.sort_func:
            return self.sort_func(left, right)

        role = self.sortByRole
        try:
            return getattr(left, role) < getattr(right, role)
        except TypeError:  # comparison between the two types not supported
            return False


    # The rest

    def __repr__(self) -> str:
        return \
        "%s(sortByRole=%r, filterByRole=%r, filter=%r, sourceModel=%s)" % (
            type(self).__name__,
            self.sortByRole,
            self.filterByRole,
            self.filter,
            "<%s at %s>" % (
                type(self.sourceModel()).__name__,
                hex(id(self.sourceModel())),
            )
        )


    @pyqtSlot(result=str)
    def repr(self) -> str:
        return self.__repr__()


    @pyqtProperty(int, notify=countChanged)
    def count(self) -> int:
        return self.rowCount()


    def roleNames(self) -> Dict[int, bytes]:
        return self.sourceModel().roleNames()
