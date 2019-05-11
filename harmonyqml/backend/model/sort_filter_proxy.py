from typing import Dict

from PyQt5.QtCore import (
    QObject, QSortFilterProxyModel, Qt, pyqtProperty, pyqtSignal, pyqtSlot
)

from .list_model import ListModel


class SortFilterProxy(QSortFilterProxyModel):
    sortByRoleChanged = pyqtSignal()
    countChanged      = pyqtSignal(int)

    def __init__(self,
                 source_model: ListModel,
                 sort_by_role: str,
                 ascending:    bool = True,
                 parent:       QObject = None) -> None:
        super().__init__(parent)
        self.setDynamicSortFilter(False)
        self.setFilterCaseSensitivity(Qt.CaseInsensitive)

        self.setSourceModel(source_model)
        source_model.rolesSet.connect(self._set_internal_sort_role)
        source_model.countChanged.connect(self.countChanged.emit)
        source_model.changed.connect(self._sort)

        self._sort_by_role = ""
        self.sortByRole    = sort_by_role
        self.ascending     = ascending


    @pyqtProperty(str, notify=sortByRoleChanged)
    def sortByRole(self) -> str:
        return self._sort_by_role


    @sortByRole.setter  # type: ignore
    def sortByRole(self, role: str) -> None:
        self._sort_by_role = role
        self._set_internal_sort_role()
        self.sortByRoleChanged.emit()


    def _set_internal_sort_role(self) -> None:
        numbers = self.sourceModel().roleNumbers()
        try:
            self.setSortRole(numbers[self._sort_by_role])
        except KeyError:
            pass  # Model doesn't have its roles set yet (empty model)


    def __repr__(self) -> str:
        return "%s(sortByRole=%r, sourceModel=%s)" % (
            type(self).__name__,
            self.sortByRole,
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


    def _sort(self) -> None:
        order = Qt.AscendingOrder if self.ascending else Qt.DescendingOrder
        self.sort(0, order)
