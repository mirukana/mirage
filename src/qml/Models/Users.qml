import QtQuick 2.7
import SortFilterProxyModel 0.2
import "../Base"

HListModel {
    function getUser(user_id) {
        var found = getWhere({"userId": user_id}, 1)
        if (found.length > 0) { return found[0] }

        py.callCoro("request_user_update_event", [user_id])

        return {
            "userId":        user_id,
            "displayName":   "",
            "avatarUrl":     "",
            "statusMessage": ""
        }
    }
}
