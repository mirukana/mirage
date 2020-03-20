// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Layouts 1.12

Rectangle {
    width: page.width
    height: show ? theme.baseElementsHeight : 0
    visible: height > 0
    color: theme.controls.header.background


    property HPage page: parent
    property bool show: mainUI.mainPane.collapse


    Behavior on height { HNumberAnimation {} }

    HRowLayout {
        anchors.fill: parent

        HButton {
            id: goToMainPaneButton
            padded: false
            backgroundColor: "transparent"
            icon.name: "go-back-to-main-pane"
            toolTip.text: qsTr("Go back to main pane")

            onClicked: mainUI.mainPane.toggleFocus()

            Layout.preferredWidth: theme.baseElementsHeight
            Layout.fillHeight: true
        }

        HLabel {
            text: page.title
            elide: Text.ElideRight
            horizontalAlignment: Qt.AlignHCenter
            verticalAlignment: Qt.AlignVCenter

            Layout.fillWidth: true
            Layout.fillHeight: true
        }

        Item {
            Layout.preferredWidth: goToMainPaneButton.width
            Layout.fillHeight: true
        }
    }
}
