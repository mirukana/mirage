// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12

CheckBox {
    id: box

    property alias mainText: mainText
    property alias subtitle: subtitleText
    property bool defaultChecked: false
    readonly property bool changed: checked !== defaultChecked

    property bool previousDefaultChecked: false  // private

    function reset() { checked = defaultChecked }


    checked: defaultChecked
    spacing: contentItem.visible ? theme.spacing : 0
    padding: 0

    indicator: Rectangle {
        opacity: box.enabled ? 1 : theme.disabledElementsOpacity + 0.2
        implicitWidth: theme.controls.checkBox.boxSize
        implicitHeight: implicitWidth
        x: box.leftPadding
        y: box.topPadding + box.availableHeight / 2 - height / 2
        radius: theme.radius

        color: theme.controls.checkBox.boxBackground
        border.color:
            box.enabled && box.pressed ?
            theme.controls.checkBox.boxPressedBorder :

            (box.enabled && box.hovered) || box.activeFocus ?
            theme.controls.checkBox.boxHoveredBorder :

            theme.controls.checkBox.boxBorder

        Behavior on border.color { HColorAnimation { factor: 0.5 } }

        HIcon {
            anchors.centerIn: parent
            dimension: parent.width - 2
            colorize: theme.controls.checkBox.checkIconColorize
            svgName:
                box.checkState === Qt.PartiallyChecked ?
                "check-mark-partial" :
                "check-mark"

            scale: box.checkState === Qt.Unchecked ? 0 : 1

            Behavior on scale {
                HNumberAnimation {
                    overshoot: 3
                    easing.type: Easing.InOutBack
                    factor: 0.5
                }
            }
        }
    }

    contentItem: HColumnLayout {
        visible: mainText.text || subtitleText.text
        opacity: box.enabled ? 1 : theme.disabledElementsOpacity

        HLabel {
            id: mainText
            text: box.text
            color: theme.controls.checkBox.text

            // Set a width on CheckBox for wrapping to work,
            // e.g. by using Layout.fillWidth
            wrapMode: HLabel.Wrap
            leftPadding: box.indicator.width + box.spacing
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

    onDefaultCheckedChanged: {
        if (checked === previousDefaultChecked)
            checked = Qt.binding(() => defaultChecked)

        previousDefaultChecked = defaultChecked
    }

    // Break binding
    Component.onCompleted: previousDefaultChecked = previousDefaultChecked

    Behavior on opacity { HNumberAnimation { factor: 2 } }
}
