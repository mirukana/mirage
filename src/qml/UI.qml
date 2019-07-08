// Copyright 2019 miruka
// This file is part of harmonyqml, licensed under LGPLv3.

import QtQuick 2.7
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtQuick.Window 2.7
import "Base"
import "SidePane"

Item {
    id: mainUI

    Connections {
        target: py
        onWillLoadAccounts: function(will) {
            pageStack.showPage(will ? "Default" : "SignIn")
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
            visible: accountsPresent
            collapsed: width < Layout.minimumWidth + normalSpacing

            property int parentWidth: parent.width
            property int collapseBelow: 120

            function set_width() {
                width = parent.width * 0.3 < collapseBelow ?
                        Layout.minimumWidth : Math.min(parent.width * 0.3, 300)
            }

            onParentWidthChanged: if (uiSplitView.canAutoSize) { set_width() }

            width: set_width()  // Initial width
            Layout.minimumWidth: theme.avatar.size
            Layout.maximumWidth: parent.width

            Behavior on width {
                HNumberAnimation {
                    // Don't slow down the user manually resizing
                    duration:
                        (uiSplitView.canAutoSize &&
                        parent.width * 0.3 < sidePane.collapseBelow * 1.2) ?
                        theme.animationDuration : 0
                }
            }
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

            Component.onCompleted: initialRoomTimer.start()
            Timer {
                // TODO: remove this, debug
                id: initialRoomTimer
                interval: 3000
                repeat: false
                onTriggered: pageStack.showRoom(
                    "@test_mary:matrix.org",
                    "Rooms",
                    "!TSXGsbBbdwsdylIOJZ:matrix.org"
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
