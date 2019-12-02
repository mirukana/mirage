// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import ".."
import "../Base"

Column {
    id: delegate


    property string userId: model.id
    readonly property HListView view: ListView.view


    Account {
        id: account
        width: parent.width
        view: delegate.view
    }

    HListView {
        id: roomList
        width: parent.width
        height: contentHeight * opacity
        opacity: account.collapsed ? 0 : 1
        visible: opacity > 0
        interactive: false

        model: ModelStore.get(delegate.userId, "rooms")
        // model: HSortFilterProxy {
        //     model: ModelStore.get(delegate.userId, "rooms")
        //     comparator: (a, b) =>
        //         // Sort by membership, then last event date (most recent first)
        //         // then room display name or ID.
        //         // Invited rooms are first, then joined rooms, then left rooms.

        //         // Left rooms may still have an inviter_id, so check left first
        //         [
        //             a.left,
        //             b.inviter_id,

        //             b.last_event && b.last_event.date ?
        //             b.last_event.date.getTime() : 0,

        //             (a.display_name || a.id).toLocaleLowerCase(),
        //         ] < [
        //             b.left,
        //             a.inviter_id,

        //             a.last_event && a.last_event.date ?
        //             a.last_event.date.getTime() : 0,

        //             (b.display_name || b.id).toLocaleLowerCase(),
        //         ]
        // }

        delegate: Room {
            width: roomList.width
            userId: delegate.userId
        }

        Behavior on opacity {
            HNumberAnimation { easing.type: Easing.InOutCirc }
        }
    }
}
