import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import "../utils.js" as Utils

CheckBox {
    id: box
    spacing: theme.spacing
    leftPadding: spacing / 1.5
    rightPadding: spacing / 1.5
    topPadding: spacing / 2
    bottomPadding: spacing / 2
    opacity: enabled ? 1 : theme.disabledElementsOpacity


    property alias mainText: mainText
    property alias subtitle: subtitleText


    Behavior on opacity { HOpacityAnimator { factor: 2 } }


    indicator: Rectangle {
        implicitWidth: implicitHeight
        implicitHeight: mainText.font.pixelSize * 1.5
        x: box.leftPadding
        y: box.topPadding + box.availableHeight / 2 - height / 2
        radius: theme.radius / 1.5

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
            svgName: "check-mark"
            colorize: theme.controls.checkBox.checkIconColorize

            scale: box.checked ? 1 : 0

            // FIXME: HScaleAnimator won't work here?
            Behavior on scale {
                HNumberAnimation {
                    overshoot: 4
                    easing.type: Easing.InOutBack
                }
            }
        }
    }

    contentItem: HColumnLayout {
        HLabel {
            id: mainText
            text: box.text
            color: theme.controls.checkBox.text

            // Set a width on CheckBox for wrapping to work,
            // e.g. by using Layout.fillWidth
            wrapMode: Text.Wrap
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
}
