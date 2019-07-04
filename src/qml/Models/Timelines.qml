import QtQuick 2.7
import SortFilterProxyModel 0.2
import "../Base"

HListModel {
    function lastEventOf(room_id) {
        // Return an event item or undefined if none found

        for (var i = 0; i < count; i++) {
            var item = get(i) // TODO: standardize
            if (item.roomId == room_id) { return item }
        }
    }

    sorters: RoleSorter {
        roleName: "date"
        sortOrder: Qt.DescendingOrder
    }
}
