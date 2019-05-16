from typing import Callable, Dict, Optional

from PyQt5.QtCore import (
    QModelIndex, QObject, QSortFilterProxyModel, Qt, pyqtProperty, pyqtSignal,
    pyqtSlot
)

from .list_model import ListModel
from .list_item import ListItem

SortCallable   = Callable[["SortFilterProxy", ListItem, ListItem], bool]
FilterCallable = Callable[["SortFilterProxy", ListItem], bool]

class SortFilterProxy(QSortFilterProxyModel):
    sortByRoleChanged   = pyqtSignal()
    filterByRoleChanged = pyqtSignal()
    filterChanged       = pyqtSignal()
    countChanged        = pyqtSignal(int)

    def __init__(self,
                 source_model:   ListModel,
                 sort_by_role:   str                      = "",
                 filter_by_role: str                      = "",
                 sort_func:      Optional[SortCallable]   = None,
                 filter_func:    Optional[FilterCallable] = None,
                 reverse:        bool                     = False,
                 parent:         QObject                  = None) -> None:

        error = "{} and {}: only one can be set"
        if (sort_by_role and sort_func):
            raise TypeError(error.format("sort_by_role", "sort_func"))
        if (filter_by_role and filter_func):
            raise TypeError(error.format("filter_by_role", "filter_func"))

        super().__init__(parent)
        self.setDynamicSortFilter(False)

        self.setSourceModel(source_model)
        source_model.countChanged.connect(self.countChanged.emit)
        source_model.changed.connect(self._apply_sort)
        source_model.changed.connect(self.invalidateFilter)

        self.sortByRole   = sort_by_role
        self.filterByRole = filter_by_role
        self.sort_func    = sort_func
        self.filter_func  = filter_func
        self.reverse      = reverse

        self._filter = None


    @pyqtProperty(str, notify=filterChanged)
    def filter(self) -> str:
        return self._filter


    @filter.setter  # type: ignore
    def filter(self, pattern: str) -> None:
        self._filter = pattern
        self.invalidateFilter()
        self.filterChanged.emit()
        self.countChanged.emit(self.rowCount())


    # Sorting/filtering methods override

    def lessThan(self, index_left: QModelIndex, index_right: QModelIndex
                ) -> bool:
        left  = self.sourceModel()[index_left.row()]
        right = self.sourceModel()[index_right.row()]

        if self.sort_func:
            return self.sort_func(self, left, right)

        role = self.sortByRole
        try:
            return getattr(left, role) < getattr(right, role)
        except TypeError:  # comparison between the two types not supported
            return False


    def filterAcceptsRow(self, row_index: int, _: QModelIndex) -> bool:
        item = self.sourceModel()[row_index]

        if self.filter_func:
            return self.filter_func(self, item)

        return self.filterMatches(getattr(item, self.filterByRole))


    # Implementations


    def _apply_sort(self) -> None:
        order = Qt.DescendingOrder if self.reverse else Qt.AscendingOrder
        self.sort(0, order)


    def filterMatches(self, string: str) -> bool:
        if not self.filter:
            return True

        string = string.lower()
        return all(word in string for word in self.filter.lower().split())


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
