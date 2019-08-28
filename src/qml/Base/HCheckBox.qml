import QtQuick 2.12
import QtQuick.Controls 2.12
import "../utils.js" as Utils

CheckBox {
    id: box
    spacing: theme.spacing
    leftPadding: spacing / 1.5
    rightPadding: spacing / 1.5
    topPadding: spacing / 2
    bottomPadding: spacing / 2
    opacity: enabled ? 1 : theme.disabledElementsOpacity


    Behavior on opacity { HNumberAnimation { factor: 2 } }


    indicator: Rectangle {
        implicitWidth: implicitHeight
        implicitHeight: box.contentItem.font.pixelSize * 1.5
        x: box.leftPadding
        y: box.topPadding + box.availableHeight / 2 - height / 2
        radius: theme.radius / 1.5

        color: theme.controls.checkBox.boxBackground
        border.color:
            box.enabled && box.pressed ?
            theme.controls.checkBox.boxPressedBorder :

            (box.enabled && box.hovered) || box.visualFocus ?
            theme.controls.checkBox.boxHoveredBorder :

            theme.controls.checkBox.boxBorder

        Behavior on border.color { HColorAnimation { factor: 0.5 } }

        HIcon {
            anchors.centerIn: parent
            dimension: parent.width - 2
            svgName: "check-mark"
            colorize: theme.controls.checkBox.checkIconColorize

            visible: scale > 0
            scale: box.checked ? 1 : 0
            Behavior on scale {
                HNumberAnimation {
                    overshoot: 4
                    easing.type: Easing.InOutBack
                }
            }
        }
    }

    contentItem: HLabel {
        text: box.text
        color: theme.controls.checkBox.text

        // Set a width on CheckBox for wrapping to work, e.g. Layout.fillWidth
        wrapMode: Text.Wrap
        leftPadding: box.indicator.width + box.spacing
        verticalAlignment: Text.AlignVCenter
    }
}
