// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Layouts 1.12

HColumnLayout {
    spacing: theme.spacing / 2


    property alias label: label
    property alias errorLabel: errorLabel
    property alias field: field
    property alias toolTip: toolTip


    HRowLayout {
        HLabel {
            id: label

            Layout.fillWidth: true
        }

        HIcon {
            svgName: "field-tooltip-available"
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

    HTextField {
        id: field
        radius: 2

        Layout.fillWidth: true
    }

    HLabel {
        id: errorLabel
        visible: Layout.maximumHeight > 0
        wrapMode: Text.Wrap
        color: theme.colors.errorText

        Layout.maximumHeight: text ? implicitHeight : 0
        Layout.fillWidth: true

        Behavior on Layout.maximumHeight { HNumberAnimation {} }
    }
}
