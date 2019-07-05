import QtQuick 2.7
import QtQuick.Layouts 1.3
import SortFilterProxyModel 0.2
import "../Base"

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
                expression: {
                    var filter = paneToolBar.roomFilter.toLowerCase()
                    var words = filter.split(" ")
                    var room_name = displayName.toLowerCase()

                    for (var i = 0; i < words.length; i++) {
                        if (words[i] && room_name.indexOf(words[i]) == -1) {
                            return false
                        }
                    }
                    return true
                }
            }
        }
    }

    delegate: RoomDelegate {}
}
