// Copyright 2019 miruka
// This file is part of harmonyqml, licensed under LGPLv3.

import QtQuick 2.12
import SortFilterProxyModel 0.2
import "../Base"

HListModel {
    sorters: StringSorter {
        roleName: "displayName"
    }

    readonly property ListModel _emptyModel: ListModel {}

    function find(userId, category, roomId) {
        if (! userId) { return }

        let found = rooms.getWhere({userId, roomId, category}, 1)[0]
        if (found) { return found }

        return {
            userId, category, roomId,
            displayName: "",
            avatarUrl:   "",
            topic:       "",
            members:     _emptyModel,
            typingText:  "",
            inviterId:   "",
            loading:     true,
        }
    }
}
