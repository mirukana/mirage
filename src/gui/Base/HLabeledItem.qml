// Copyright Mirage authors & contributors <https://github.com/mirukana/mirage>
// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Layouts 1.12

HColumnLayout {
    default property alias insideData: itemHolder.data

    property bool loading: false
    property real elementsOpacity: item.opacity

    readonly property Item item: itemHolder.children[0]
    readonly property alias label: label
    readonly property alias errorLabel: errorLabel


    spacing: theme.spacing / 2

    HRowLayout {
        spacing: theme.spacing

        HLabel {
            id: label
            opacity: elementsOpacity
            wrapMode: HLabel.Wrap

            Layout.fillWidth: true
        }

        HLoader {
            source: "HBusyIndicator.qml"
            active: loading
            visible: height > 0

            Layout.preferredWidth: height
            Layout.preferredHeight: active ? label.height : 0

            Behavior on Layout.preferredHeight { HNumberAnimation {} }
        }
    }

    Item {
        id: itemHolder
        // implicitWidth: childrenRect.width
        implicitHeight: childrenRect.height

        Layout.fillWidth: true
    }

    HLabel {
        id: errorLabel
        opacity: elementsOpacity
        visible: Layout.maximumHeight > 0
        wrapMode: HLabel.Wrap
        color: theme.colors.errorText

        Layout.maximumHeight: text ? implicitHeight : 0
        Layout.fillWidth: true

        Behavior on Layout.maximumHeight { HNumberAnimation {} }
    }
}
