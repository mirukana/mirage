import QtQuick 2.7
import QtQuick.Layouts 1.3
import SortFilterProxyModel 0.2
import "../Base"
import "../utils.js" as Utils

HListView {
    property string userId: ""
    property string category: ""

    id: roomList
    spacing: sidePane.collapsed ? 0 : sidePane.normalSpacing

    model: SortFilterProxyModel {
        sourceModel: rooms
        filters: AllOf {
            ValueFilter {
                roleName: "category"
                value: category
            }

            ValueFilter {
                roleName: "userId"
                value: userId
            }

            ExpressionFilter {
                // Utils... won't work directly in expression?
                function filterIt(filter, text) {
                    return Utils.filterMatches(filter, text)
                }
                expression: filterIt(paneToolBar.roomFilter, displayName)
            }
        }
    }

    delegate: RoomDelegate {}
}
