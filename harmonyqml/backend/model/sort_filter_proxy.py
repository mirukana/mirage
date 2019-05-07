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

        self.ascending = ascending

        self.sortByRoleChanged.connect(self._set_sort_role)

        self.setSourceModel(source_model)
        source_model.rolesSet.connect(self._set_sort_role)
        source_model.countChanged.connect(self.countChanged.emit)
        source_model.changed.connect(self._sort)

        self._sort_by_role = sort_by_role
        self._set_sort_role()


    @pyqtProperty(str, notify=sortByRoleChanged)
    def sortByRole(self) -> str:
        return self._sort_by_role


    @sortByRole.setter  # type: ignore
    def sortByRole(self, role: str) -> None:
        self._sort_by_role = role
        self.sortByRoleChanged.emit()


    def _set_sort_role(self) -> None:
        numbers = self.sourceModel().roleNumbers()
        try:
            self.setSortRole(numbers[self._sort_by_role])
        except KeyError:
            pass  # Model doesn't have its roles set yet (empty model)


    def __repr__(self) -> str:
        return "%s(sortByRole=%r, sourceModel=%r)" % (
            type(self).__name__, self.sortByRole, self.sourceModel(),
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
