// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import "../../../Base"

HDrawer {
    id: roomPane
    saveName: "roomPane"

    edge: Qt.RightEdge
    defaultSize: buttonRepeater.summedImplicitWidth
    minimumSize:
        buttonRepeater.count > 0 ? buttonRepeater.itemAt(0).implicitWidth : 0

    background: HColumnLayout{
        Rectangle {
            color: theme.chat.roomPaneButtons.background

            Layout.fillWidth: true
            Layout.preferredHeight: buttonFlow.height

            Behavior on Layout.preferredHeight { HNumberAnimation {} }
        }

        Rectangle {
            color: theme.chat.roomPane.background

            Layout.fillWidth: true
            Layout.fillHeight: true
        }
    }


    readonly property alias buttonRepeater: buttonRepeater
    readonly property alias swipeView: swipeView


    HColumnLayout {
        anchors.fill: parent

        HFlow {
            id: buttonFlow
            populate: null

            Layout.fillWidth: true

            HRepeater {
                id: buttonRepeater
                model: [
                    "members", "files", "notifications", "history", "settings"
                ]

                HButton {
                    height: theme.baseElementsHeight
                    backgroundColor: "transparent"
                    icon.name: "room-view-" + modelData
                    toolTip.text: qsTr(
                        modelData.charAt(0).toUpperCase() + modelData.slice(1)
                    )

                    autoExclusive: true
                    checked: swipeView.currentIndex === 0 && index === 0 ||
                             swipeView.currentIndex === 1 && index === 4

                    enabled: ["members", "settings"].includes(modelData)

                    onClicked: swipeView.currentIndex = Math.min(index, 1)
                }
            }
        }

        HSwipeView {
            id: swipeView
            clip: true
            interactive: ! roomPane.collapsed

            saveName: "roomPaneView"
            saveId: chat.roomId

            Layout.fillWidth: true
            Layout.fillHeight: true

            MemberView {}
            SettingsView { fillAvailableHeight: true }
        }
    }
}
