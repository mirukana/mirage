// Copyright 2019 miruka
// This file is part of harmonyqml, licensed under LGPLv3.

import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtQuick.Window 2.7
import "Base"
import "SidePane"

Item {
    id: mainUI

    Connections {
        target: py
        onWillLoadAccounts: function(will) {
            pageStack.showPage(will ? "Default": "SignIn")
            if (will) {initialRoomTimer.start()}
        }
    }

    property bool accountsPresent:
        accounts.count > 0 || py.loadingAccounts

    HImage {
        id: mainUIBackground
        fillMode: Image.PreserveAspectCrop
        source: "../images/login_background.jpg"
        sourceSize.width: Screen.width
        sourceSize.height: Screen.height
        anchors.fill: parent
        asynchronous: false
    }

    HSplitView {
        id: uiSplitView
        anchors.fill: parent

        SidePane {
            id: sidePane
            canAutoSize: uiSplitView.canAutoSize

            width: implicitWidth  // Initial width
            Layout.minimumWidth: theme.sidePane.collapsedWidth
            Layout.maximumWidth: parent.width
        }

        StackView {
            id: pageStack

            function showPage(name, properties) {
                pageStack.replace("Pages/" + name + ".qml", properties || {})
            }

            function showRoom(userId, category, roomId) {
                var info = rooms.getWhere({
                    "userId": userId,
                    "roomId": roomId,
                    "category": category
                }, 1)[0]

                pageStack.replace("Chat/Chat.qml", {"roomInfo": info})
            }

            Timer {
                // TODO: remove this, debug
                id: initialRoomTimer
                interval: 5000
                repeat: false
                onTriggered: pageStack.showRoom(
                    "@test_mary:matrix.org",
                    // "Rooms",
                    // "!TSXGsbBbdwsdylIOJZ:matrix.org"
                    "Invites",
                    "!xjqvLOGhMVutPXpAqi:matrix.org"
                )
                // onTriggered: pageStack.showPage(
                //     "EditAccount/EditAccount",
                //     {"userId": "@test_mary:matrix.org"}
                // )
            }

            onCurrentItemChanged: if (currentItem) {
                currentItem.forceActiveFocus()
            }

            // Buggy
            replaceExit: null
            popExit: null
            pushExit: null
        }

        Keys.onEscapePressed: if (window.debug) { py.call("APP.pdb") }
    }
}
