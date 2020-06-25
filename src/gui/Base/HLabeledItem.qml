// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Layouts 1.12

HColumnLayout {
    spacing: theme.spacing / 2


    default property alias insideData: itemHolder.data

    readonly property Item item: itemHolder.children[0]
    readonly property alias label: label
    readonly property alias errorLabel: errorLabel
    readonly property alias toolTip: toolTip


    HRowLayout {
        spacing: parent.spacing

        HLabel {
            id: label
            opacity: item.opacity
            wrapMode: Text.Wrap

            Layout.fillWidth: true
        }

        HIcon {
            svgName: "field-tooltip-available"
            opacity: item.opacity
            visible: toolTip.text

            Binding on colorize {
                value: theme.colors.accentElement
                when: hoverHandler.hovered || toolTip.visible
            }
        }

        HoverHandler {
            id: hoverHandler
            enabled: toolTip.text
        }

        TapHandler {
            onTapped: toolTip.instantShow()
            enabled: toolTip.text
        }

        HToolTip {
            id: toolTip
            visible: toolTip.text && hoverHandler.hovered
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
        opacity: item.opacity
        visible: Layout.maximumHeight > 0
        wrapMode: Text.Wrap
        color: theme.colors.errorText

        Layout.maximumHeight: text ? implicitHeight : 0
        Layout.fillWidth: true

        Behavior on Layout.maximumHeight { HNumberAnimation {} }
    }
}
