import QtQuick 2.7
import SortFilterProxyModel 0.2
import "Base"

QtObject {
    property HListModel accounts: HListModel {
        sorters: StringSorter {
            roleName: "userId"
            numericMode: true  // human numeric sort
        }
    }

    property HListModel users: HListModel {
        function getUser(user_id) {
            var found = users.getWhere({"userId": user_id}, 1)
            if (found.length > 0) { return found[0] }

            users.append({
                "userId":        user_id,
                "displayName":   "",
                "avatarUrl":     "",
                "statusMessage": ""
            })

            py.callCoro("request_user_update_event", [user_id])

            return users.getWhere({"userId": user_id}, 1)[0]
        }
    }

    property HListModel devices: HListModel {}

    property HListModel roomCategories: HListModel {
        sorters: FilterSorter {
            ValueFilter { roleName: "name"; value: "Invites" }
            ValueFilter { roleName: "name"; value: "Rooms" }
            ValueFilter { roleName: "name"; value: "Left" }
        }
    }

    property HListModel rooms: HListModel {}

    property HListModel timelines: HListModel {
        function lastEventOf(room_id) {
            // Return an event item or undefined if none found

            for (var i = 0; i < timelines.count; i++) {
                var item = timelines.get(i) // TODO: standardize
                if (item.roomId == room_id) { return item }
            }
        }

        sorters: RoleSorter {
            roleName: "date"
            sortOrder: Qt.DescendingOrder
        }
    }
}
