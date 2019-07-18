// Copyright 2019 miruka
// This file is part of harmonyqml, licensed under LGPLv3.

import QtQuick 2.12
import SortFilterProxyModel 0.2
import "../Base"

HListModel {
    function find(userId) {
        // Happens when SortFilterProxyModel ExpressionFilter/Sorter/Role tests
        // the expression with invalid data to establish property bindings
        if (! userId) { return }

        let found = getWhere({userId}, 1)
        if (found.length > 0) { return found[0] }

        py.callCoro("request_user_update_event", [userId])

        return {
            userId,
            displayName:   "",
            avatarUrl:     "",
            statusMessage: "",
        }
    }
}
