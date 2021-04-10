// Copyright Mirage authors & contributors <https://github.com/mirukana/mirage>
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

        showBackButton: mainUI.mainPane.normalOrForceCollapse
        backButton.icon.name: "go-back-to-main-pane"
        backButton.toolTip.text: qsTr("Back to main pane")
        backButton.onClicked: mainUI.mainPane.toggleFocus()

        tabBar: HTabBar {
            HTabButton { text: qsTr("General") }
            HTabButton { text: qsTr("Notifications") }
            HTabButton { text: qsTr("Security") }
        }

        General { userId: page.userId }
        Notifications { userId: page.userId }
        Security { userId: page.userId }
    }
}
