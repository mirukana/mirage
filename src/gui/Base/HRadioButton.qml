// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12

RadioButton {
    id: button

    property alias mainText: mainText
    property alias subtitle: subtitleText
    property bool defaultChecked: false
    readonly property bool changed: checked !== defaultChecked

    function reset() { checked = defaultChecked }


    checked: defaultChecked
    spacing: contentItem.visible ? theme.spacing : 0
    padding: 0

    indicator: Rectangle {
        opacity: button.enabled ? 1 : theme.disabledElementsOpacity + 0.2
        implicitWidth: theme.controls.checkBox.boxSize
        implicitHeight: implicitWidth
        x: button.leftPadding
        y: button.topPadding + button.availableHeight / 2 - height / 2
        radius: width / 2

        color: theme.controls.checkBox.boxBackground
        border.color:
            button.enabled && button.pressed ?
            theme.controls.checkBox.boxPressedBorder :

            (button.enabled && button.hovered) || button.activeFocus ?
            theme.controls.checkBox.boxHoveredBorder :

            theme.controls.checkBox.boxBorder

        Behavior on border.color { HColorAnimation { factor: 0.5 } }

        Rectangle {
            anchors.centerIn: parent
            width: parent.width * 0.5  // XXX theme
            height: width
            radius: parent.radius
            color: theme.controls.checkBox.checkIconColorize
            scale: button.checked ? 1 : 0

            Behavior on scale {
                HNumberAnimation {
                    overshoot: 4
                    easing.type: Easing.InOutBack
                    factor: 0.5
                }
            }
        }
    }

    contentItem: HColumnLayout {
        visible: mainText.text || subtitleText.text
        opacity: button.enabled ? 1 : theme.disabledElementsOpacity

        HLabel {
            id: mainText
            text: button.text
            color: theme.controls.checkBox.text

            // Set a width on RadioButton for wrapping to work,
            // e.g. by using Layout.fillWidth
            wrapMode: HLabel.Wrap
            leftPadding: button.indicator.width + button.spacing
            verticalAlignment: Text.AlignVCenter

            Layout.fillWidth: true
        }

        HLabel {
            id: subtitleText
            visible: Boolean(text)
            color: theme.controls.checkBox.subtitle
            font.pixelSize: theme.fontSize.small

            wrapMode: mainText.wrapMode
            leftPadding: mainText.leftPadding
            verticalAlignment: mainText.verticalAlignment

            Layout.fillWidth: true
        }
    }

    Behavior on opacity { HNumberAnimation { factor: 2 } }
}
