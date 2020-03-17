// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import "../../../Base"
import "../../.."

MultiviewPane {
    id: roomPane
    saveName: "roomPane"
    edge: Qt.RightEdge

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
            swipeView.currentIndex = Math.min(index, 1)

        Behavior on width {
            enabled: modelData === "back"
            HNumberAnimation {}
        }
    }


    function toggleFocus() {
        if (swipeView.currentItem.keybindFocusItem.activeFocus) {
            if (roomPane.collapse) roomPane.close()
            pageLoader.takeFocus()
            return
        }

        roomPane.open()
        swipeView.currentItem.keybindFocusItem.forceActiveFocus()
    }


    Connections {
        target: swipeView

        onCurrentItemChanged:
            swipeView.currentItem.keybindFocusItem.forceActiveFocus()
    }

    MemberView {}
    SettingsView { fillAvailableHeight: true }
}
