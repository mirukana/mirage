// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12

HRowLayout {
    id: buttonContent
    spacing: button.spacing
    opacity: loading ? theme.loadingElementsOpacity :
             enabled ? 1 : theme.disabledElementsOpacity


    property var button
    property QtObject buttonTheme

    readonly property alias icon: icon
    readonly property alias label: label


    Behavior on opacity { HNumberAnimation {} }


    Item {
        visible: button.icon.name || button.loading

        Layout.preferredWidth:
            button.loading ? busyIndicatorLoader.width : icon.width

        Layout.fillHeight: true
        Layout.alignment: Qt.AlignCenter

        HIcon {
            id: icon
            anchors.centerIn: parent
            width: svgName ? implicitWidth : 0
            visible: width > 0
            opacity: button.loading ? 0 : 1

            colorize: button.icon.color
            svgName: button.icon.name

            // cache: button.icon.cache  // TODO: need Qt 5.13+

            Behavior on opacity { HNumberAnimation {} }
        }

        HLoader {
            id: busyIndicatorLoader
            anchors.centerIn: parent
            width: height
            height: parent.height
            opacity: button.loading ? 1 : 0

            active: opacity > 0
            sourceComponent: HBusyIndicator {}

            Behavior on opacity { HNumberAnimation {} }
        }
    }

    HLabel {
        id: label
        text: button.text
        visible: Boolean(text)
        color: buttonTheme.text
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight

        Layout.fillWidth: true
        Layout.fillHeight: true
    }
}
