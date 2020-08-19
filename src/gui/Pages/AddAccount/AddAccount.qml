// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import "../../Base"

SwipeView {
    id: swipeView
    clip: true
    interactive: serverBrowser.acceptedUrl
    onCurrentItemChanged:
        currentIndex === 0 ?
        serverBrowser.takeFocus() :
        signInLoader.takeFocus()

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

        enabled: swipeView.currentItem === this

        HTabbedBox {
            anchors.centerIn: parent
            width: Math.min(implicitWidth, tabPage.availableWidth)
            height: Math.min(implicitHeight, tabPage.availableHeight)

            header: HTabBar {
                shortcutsEnabled: visible && tabPage.enabled
                visible:
                    signInLoader.sourceComponent !== signInLoader.signInSso

                HTabButton { text: qsTr("Sign in") }
                HTabButton { text: qsTr("Register") }
                HTabButton { text: qsTr("Reset") }
            }

            HLoader {
                id: signInLoader

                readonly property Component signInPassword: SignInPassword {
                    serverUrl: serverBrowser.acceptedUrl
                    displayUrl: serverBrowser.acceptedUserUrl
                    onExitRequested: swipeView.currentIndex = 0
                }

                readonly property Component signInSso: SignInSso {
                    serverUrl: serverBrowser.acceptedUrl
                    displayUrl: serverBrowser.acceptedUserUrl
                    onExitRequested: swipeView.currentIndex = 0
                }

                function takeFocus() { if (item) item.takeFocus() }

                sourceComponent:
                    serverBrowser.loginFlows.includes("m.login.password") ?
                    signInPassword :

                    serverBrowser.loginFlows.includes("m.login.sso") &&
                    serverBrowser.loginFlows.includes("m.login.token") ?
                    signInSso :

                    null
            }

            Register {}
            Reset {}
        }
    }
}
