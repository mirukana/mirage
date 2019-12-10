import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../../Base"

HDrawer {
    id: roomSidePane
    edge: Qt.RightEdge
    preferredSize: buttonRepeater.childrenImplicitWidth
    minimumSize:
        buttonRepeater.count > 0 ? buttonRepeater.itemAt(0).implicitWidth : 0

    background: HColumnLayout{
        Rectangle {
            color: theme.chat.roomSidePaneButtons.background

            Layout.fillWidth: true
            Layout.preferredHeight: theme.baseElementsHeight
        }

        Rectangle {
            color: theme.chat.roomSidePane.background

            Layout.fillWidth: true
            Layout.fillHeight: true
        }
    }

    HColumnLayout {
        anchors.fill: parent

        HFlow {
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
                    autoExclusive: true
                    checked: modelData === "members"
                    enabled: modelData === "members"
                    toolTip.text: qsTr(
                        modelData.charAt(0).toUpperCase() + modelData.slice(1)
                    )
                }
            }
        }

        MembersView {
            Layout.fillWidth: true
            Layout.fillHeight: true
        }
    }
}
