// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../../Base"

HPage {
    id: page

    HTabbedBox {
        anchors.centerIn: parent
        width: Math.min(implicitWidth, page.availableWidth)
        height: Math.min(implicitHeight, page.availableHeight)

        header: HTabBar {
            HTabButton { text: qsTr("Sign in") }
            HTabButton { text: qsTr("Register") }
            HTabButton { text: qsTr("Reset") }
        }

        SignIn {}
        Register {}
        Reset {}
    }
}
