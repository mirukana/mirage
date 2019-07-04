import QtQuick 2.7
import SortFilterProxyModel 0.2
import "../Base"

HListModel {
    sorters: StringSorter {
        roleName: "displayName"
    }
}
