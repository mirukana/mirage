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
            if (! will) {
                pageStack.showPage("SignIn")
                return
            }

            let page  = window.uiState.page
            let props = window.uiState.pageProperties

            if (page == "Chat/Chat.qml") {
                pageStack.showRoom(props.userId, props.category, props.roomId)
            } else {
                pageStack.show(page, props)
            }
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
            property bool isWide: width > theme.contentIsWideAbove

            function show(componentUrl, properties={}) {
                pageStack.replace(componentUrl, properties)
            }

            function showPage(name, properties={}) {
                let path = "Pages/" + name + ".qml"
                show(path, properties)

                window.uiState.page           = path
                window.uiState.pageProperties = properties
                window.uiStateChanged()
            }

            function showRoom(userId, category, roomId) {
                let roomInfo = rooms.find(userId, category, roomId)
                show("Chat/Chat.qml", {roomInfo})

                window.uiState.page           = "Chat/Chat.qml"
                window.uiState.pageProperties = {userId, category, roomId}
                window.uiStateChanged()
            }

            onCurrentItemChanged: if (currentItem) {
                currentItem.forceActiveFocus()
            }

            // Buggy
            replaceExit: null
            popExit: null
            pushExit: null
        }
    }
}
