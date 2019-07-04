import QtQuick 2.7
import SortFilterProxyModel 0.2
import "../Base"

HListModel {
    sorters: FilterSorter {
        ValueFilter { roleName: "name"; value: "Invites" }
        ValueFilter { roleName: "name"; value: "Rooms" }
        ValueFilter { roleName: "name"; value: "Left" }
    }
}
