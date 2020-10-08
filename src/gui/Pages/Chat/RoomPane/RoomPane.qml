// Copyright Mirage authors & contributors <https://github.com/mirukana/mirage>
// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import "../../../Base"
import "../../.."
import "MemberView"

MultiviewPane {
    id: roomPane

    readonly property QtObject accountModel:
        ModelStore.get("accounts").find(chat.roomInfo.for_account)

    function toggleFocus() {
        if (roomPane.activeFocus) {
            if (roomPane.collapse) roomPane.close()
            pageLoader.takeFocus()
            return
        }

        roomPane.forceCollapse = false
        roomPane.open()
        swipeView.currentItem.keybindFocusItem.forceActiveFocus()
    }


    saveName: "roomPane"
    edge: Qt.RightEdge

    defaultSize:
        (buttonRepeater.count - (roomPane.collapse ? 0 : 1)) * buttonWidth

    buttonWidth:
        buttonRepeater.count >= 1 ? buttonRepeater.itemAt(1).implicitWidth : 0

    requireDefaultSize:
        swipeView.currentIndex !== 0 ||
        swipeView.currentItem.viewDepth > 1 ||
        swipeView.currentItem.filterField.activeFocus

    buttonsBackgroundColor: theme.chat.roomPane.topBar.background
    background: Rectangle { color: theme.chat.roomPane.background }


    buttonRepeater.model: [
        "back", "members", "files", "notifications", "history", "settings"
    ]

    buttonRepeater.delegate: HButton {
        visible: width > 0
        width: modelData === "back" && ! roomPane.collapse ? 0 : implicitWidth
        height: theme.baseElementsHeight

        backgroundColor: "transparent"
        icon.name:
            modelData === "back" ?
            "go-back-to-chat-from-room-pane" : "room-view-" + modelData

        toolTip.text:
            modelData === "back" ?
            qsTr("Go back to chat") :
            qsTr(modelData.charAt(0).toUpperCase() + modelData.slice(1))

        autoExclusive: true
        checked: swipeView.currentIndex === 0 && index === 1 ||
                 swipeView.currentIndex === 1 && index === 5

        enabled: ["back", "members", "settings"].includes(modelData)

        onClicked:
            modelData === "back" ?
            roomPane.toggleFocus() :

            (modelData === "members" && swipeView.currentIndex === 0) ||
            (modelData === "settings" && swipeView.currentIndex === 1) ?
            roomPane.forceCollapse = true :

            modelData === "members" ?
            swipeView.currentIndex = 0 :

            swipeView.currentIndex = 1

        Behavior on width {
            enabled: modelData === "back"
            HNumberAnimation {}
        }
    }

    Connections {
        target: swipeView
        onCurrentItemChanged:
            roomPane.swipeView.currentItem.keybindFocusItem.forceActiveFocus()
    }

    Connections {
        target: pageLoader
        onAboutToRecycle: roomPane.swipeView.currentIndex = 0
    }

    MemberView {}

    SettingsView {
        enabled: accountModel.presence !== "offline"
    }

    HShortcut {
        sequences: window.settings.Keys.Chat.focus_room_pane
        onActivated: roomPane.toggleFocus()
    }

    HShortcut {
        sequences: window.settings.Keys.Chat.hide_room_pane
        onActivated: roomPane.forceCollapse = ! roomPane.forceCollapse
    }
}
