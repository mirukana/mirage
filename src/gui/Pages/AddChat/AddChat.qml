// Copyright Mirage authors & contributors <https://github.com/mirukana/mirage>
// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../../Base"

HPage {
    id: page

    property string userId

    HTabbedBox {
        anchors.centerIn: parent
        width: Math.min(implicitWidth, page.availableWidth)
        height: Math.min(implicitHeight, page.availableHeight)

        header: HTabBar {
            HTabButton { text: qsTr("Direct chat") }
            HTabButton { text: qsTr("Join room") }
            HTabButton { text: qsTr("Create room") }
        }

        DirectChat { userId: page.userId }
        JoinRoom { userId: page.userId }
        CreateRoom { userId: page.userId }
    }
}
