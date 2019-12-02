// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../.."
import "../../Base"

HPage {
    id: addChatPage


    property string userId

    readonly property QtObject account: ModelStore.get("accounts").find(userId)


    HTabContainer {
        tabModel: [
            qsTr("Direct chat"), qsTr("Join room"), qsTr("Create room"),
        ]

        DirectChat { Component.onCompleted: forceActiveFocus() }
        JoinRoom {}
        CreateRoom {}
    }
}
