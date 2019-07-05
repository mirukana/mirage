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

    sorters: ExpressionSorter {
        expression: modelLeft.isLocalEcho && ! modelRight.isLocalEcho ?
                    true :
                    ! modelLeft.isLocalEcho && modelRight.isLocalEcho ?
                    false :
                    modelLeft.date > modelRight.date // descending order
    }
}
