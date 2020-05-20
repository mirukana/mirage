// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../../Base"

Rectangle {
    implicitHeight: label.text ? rowLayout.height : 0
    opacity: implicitHeight ? 1 : 0


    readonly property alias icon: icon
    readonly property alias label: label
    default property alias rowLayoutData: rowLayout.data


    Behavior on implicitHeight { HNumberAnimation {} }

    HRowLayout {
        id: rowLayout
        width: parent.width
        spacing: theme.spacing

        HIcon {
            id: icon

            Layout.fillHeight: true
            Layout.leftMargin: rowLayout.spacing / 2
        }

        HLabel {
            id: label
            elide: Text.ElideRight

            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.topMargin: rowLayout.spacing / 4
            Layout.bottomMargin: rowLayout.spacing / 4
            Layout.leftMargin: rowLayout.spacing / 2
            Layout.rightMargin: rowLayout.spacing / 2
        }
    }
}
