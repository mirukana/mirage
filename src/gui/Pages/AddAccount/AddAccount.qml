// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../../Base"

HSwipeView {
    id: swipeView
    clip: true
    interactive: currentIndex !== 0 || signIn.serverUrl
    onCurrentItemChanged: if (currentIndex === 0) serverBrowser.takeFocus()
    Component.onCompleted: serverBrowser.takeFocus()

    HPage {
        id: serverPage

        ServerBrowser {
            id: serverBrowser
            anchors.centerIn: parent
            width: Math.min(implicitWidth, serverPage.availableWidth)
            height: Math.min(implicitHeight, serverPage.availableHeight)
            onAccepted: swipeView.currentIndex = 1
        }
    }

    HPage {
        id: tabPage

        HTabbedBox {
            anchors.centerIn: parent
            width: Math.min(implicitWidth, tabPage.availableWidth)
            height: Math.min(implicitHeight, tabPage.availableHeight)

            header: HTabBar {
                HTabButton { text: qsTr("Sign in") }
                HTabButton { text: qsTr("Register") }
                HTabButton { text: qsTr("Reset") }
            }

            SignIn {
                id: signIn
                serverUrl: serverBrowser.acceptedUrl
                displayUrl: serverBrowser.acceptedUserUrl
                onExitRequested: swipeView.currentIndex = 0
            }

            Register {}
            Reset {}
        }
    }
}
