// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../Base"

Rectangle {
    clip: true
    implicitHeight: theme.baseElementsHeight
    color: theme.mainPaneTopBar.background

    HRowLayout {
        anchors.fill: parent

        HButton {
            backgroundColor: "transparent"
            icon.name: "settings"
            toolTip.text: qsTr("Open config folder")

            onClicked: py.callCoro("get_config_dir", [], Qt.openUrlExternally)

            Layout.fillHeight: true
        }

        HButton {
            backgroundColor: "transparent"

            text: qsTr("%1 %2")
                  .arg(Qt.application.displayName).arg(Qt.application.version)
            label.color: theme.mainPaneTopBar.nameVersionLabel
            toolTip.text: qsTr("Open project repository")

            onClicked:
                Qt.openUrlExternally("https://github.com/mirukana/mirage")

            Layout.fillWidth: true
            Layout.fillHeight: true
        }

        HButton {
            backgroundColor: "transparent"
            icon.name: "reload-config-files"
            toolTip.text: qsTr("Reload config files")

            onClicked: mainUI.reloadSettings()

            Layout.fillHeight: true
        }

        HButton {
            visible: Layout.preferredWidth > 0
            backgroundColor: "transparent"
            icon.name: "go-back-to-chat-from-main-pane"
            toolTip.text: qsTr("Go back to room")

            onClicked: mainPane.toggleFocus()

            Layout.preferredWidth: mainPane.collapse ? implicitWidth : 0
            Layout.fillHeight: true

            Behavior on Layout.preferredWidth { HNumberAnimation {} }
        }
    }
}
