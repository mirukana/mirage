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
        onWillLoadAccounts: will => {
            pageStack.showPage(will ? "Default": "SignIn")
            if (will) { initialRoomTimer.start() }
        }
    }

    property bool accountsPresent:
        accounts.count > 0 || py.loadingAccounts

    HImage {
        id: mainUIBackground
        fillMode: Image.PreserveAspectCrop
        source: "../images/background.jpg"
        sourceSize.width: Screen.width
        sourceSize.height: Screen.height
        anchors.fill: parent
        asynchronous: false
    }

    HSplitView {
        id: uiSplitView
        anchors.fill: parent

        onAnyResizingChanged: if (anyResizing) {
            sidePane.manuallyResizing = true
        } else {
            sidePane.manuallyResizing = false
            sidePane.manuallyResized = true
            sidePane.manualWidth = sidePane.width
        }

        SidePane {
            id: sidePane

            // Initial width until user manually resizes
            width: implicitWidth
            Layout.minimumWidth: reduce ? 0 : theme.sidePane.collapsedWidth
            Layout.maximumWidth:
                window.width -theme.minimumSupportedWidthPlusSpacing

            Behavior on Layout.minimumWidth { HNumberAnimation {} }
        }

        StackView {
            id: pageStack

            function showPage(name, properties={}) {
                pageStack.replace("Pages/" + name + ".qml", properties)
            }

            function showRoom(userId, category, roomId) {
                let info = rooms.getWhere({userId, roomId, category}, 1)[0]
                pageStack.replace("Chat/Chat.qml", {"roomInfo": info})
            }

            Timer {
                // TODO: remove this, debug
                id: initialRoomTimer
                interval: 4000
                repeat: false
                // onTriggered: pageStack.showRoom(
                    // "@test_mary:matrix.org",
                    // "Rooms",
                    // "!TSXGsbBbdwsdylIOJZ:matrix.org"  // st
                    // "!VDSsFIzQnXARSCVNxS:matrix.org"  // hs
                    // "Invites",
                    // "!xjqvLOGhMVutPXpAqi:matrix.org"
                // )
                onTriggered: pageStack.showPage(
                    "EditAccount/EditAccount",
                    {"userId": "@test_mary:matrix.org"}
                )
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
