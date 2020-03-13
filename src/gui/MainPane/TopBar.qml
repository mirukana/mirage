// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../Base"

Rectangle {
    clip: true
    color: theme.mainPane.topBar.background

    HRowLayout {
        anchors.fill: parent

        HButton {
            backgroundColor: "transparent"
            icon.name: "placeholder-logo"
            icon.color: theme.mainPane.topBar.placeholderLogo

            text: qsTr("%1 %2")
                  .arg(Qt.application.displayName).arg(Qt.application.version)
            label.color: theme.mainPane.topBar.nameVersionLabel
            label.horizontalAlignment: Text.AlignLeft
            toolTip.text: qsTr("Open project repository")

            onClicked:
                Qt.openUrlExternally("https://github.com/mirukan/mirage")

            Layout.fillWidth: true
            Layout.fillHeight: true
        }

        HButton {
            backgroundColor: "transparent"
            icon.name: "developper-console"
            toolTip.text: qsTr("Developper console")

            onClicked: mainUI.shortcuts.toggleConsole()  // FIXME

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
            backgroundColor: "transparent"
            icon.name: "settings"
            toolTip.text: qsTr("Open config folder")

            onClicked: py.callCoro("get_config_dir", [], Qt.openUrlExternally)

            Layout.fillHeight: true
        }
    }
}
