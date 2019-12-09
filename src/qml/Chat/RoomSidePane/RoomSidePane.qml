import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../../Base"

HDrawer {
    id: roomSidePane
    color: theme.chat.roomSidePane.background
    edge: Qt.RightEdge
    normalWidth: buttonRepeater.childrenImplicitWidth
    minNormalWidth:
        buttonRepeater.count > 0 ? buttonRepeater.itemAt(0).implicitWidth : 0

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
