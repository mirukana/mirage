import QtQuick 2.12
import QtQuick.Controls 2.12
import "../utils.js" as Utils

CheckBox {
    id: box
    spacing: theme.spacing

    property bool highlight: enabled && (hovered || visualFocus)

    indicator: Rectangle {
        implicitWidth: implicitHeight
        implicitHeight: box.contentItem.font.pixelSize * 1.5
        x: box.leftPadding
        y: box.topPadding + box.availableHeight / 2 - height / 2
        radius: theme.radius / 1.5

        color: theme.controls.button.background
        border.color: Utils.hsluv(
            180, highlight ? 80 : 0, highlight ? 80 : 40, highlight ? 1 : 0.7
        )

        Behavior on border.color { HColorAnimation { factor: 0.5 } }

        HIcon {
            anchors.centerIn: parent
            dimension: parent.width - 2
            svgName: "check-mark"
            colorize: theme.colors.strongAccentBackground

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
        color: box.enabled ?
               theme.controls.button.text :
               theme.controls.button.disabledText

        // Set a width on CheckBox for wrapping to work, e.g. Layout.fillWidth
        wrapMode: Text.Wrap
        leftPadding: box.indicator.width + box.spacing
        verticalAlignment: Text.AlignVCenter
    }
}
