// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import "../.."
import "../../Base"

HPage {
    id: page

    property string userId


    HTabbedBox {
        anchors.centerIn: parent
        width: Math.min(implicitWidth, page.availableWidth)
        height: Math.min(implicitHeight, page.availableHeight)

        header: HTabBar {
            HTabButton { text: qsTr("Account") }
            HTabButton { text: qsTr("Encryption") }
            HTabButton { text: qsTr("Sessions") }
        }

        Account { userId: page.userId }
        Encryption { userId: page.userId }
        Sessions { userId: page.userId }
    }
}
