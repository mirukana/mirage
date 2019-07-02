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
        function getUser(as_account_id, wanted_user_id) {
            wanted_user_id = wanted_user_id || as_account_id

            var found = users.getWhere({"userId": wanted_user_id}, 1)
            if (found.length > 0) { return found[0] }

            users.append({
                "userId":        wanted_user_id,
                "displayName":   "",
                "avatarUrl":     "",
                "statusMessage": ""
            })

            py.callClientCoro(
                as_account_id, "request_user_update_event", [wanted_user_id]
            )

            return users.getWhere({"userId": wanted_user_id}, 1)[0]
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
        sorters: RoleSorter {
            roleName: "date"
            sortOrder: Qt.DescendingOrder
        }
    }
}
