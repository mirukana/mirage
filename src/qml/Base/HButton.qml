import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12

Button {
    id: button
    spacing: theme.spacing
    leftPadding: spacing / 1.5
    rightPadding: spacing / 1.5
    topPadding: spacing / 2
    bottomPadding: spacing / 2
    opacity: enabled ? 1 : theme.disabledElementsOpacity
    onVisibleChanged: if (! visible) loading = false


    readonly property alias ico: ico
    readonly property alias label: label

    property string iconName: ""
    property color backgroundColor: theme.controls.button.background
    property bool loading: false
    property bool circle: false


    Behavior on opacity { HNumberAnimation {} }


    background: HRectangle {
        radius: circle ? height : 0
        color: backgroundColor

        HRectangle {
            anchors.fill: parent
            radius: parent.radius
            color: button.checked ?
                   theme.controls.button.checkedOverlay :

                   button.enabled && button.pressed ?
                   theme.controls.button.pressedOverlay :

                   (button.enabled && button.hovered) || button.visualFocus ?
                   theme.controls.button.hoveredOverlay :

                   "transparent"

            Behavior on color { HColorAnimation { factor: 0.5 } }
        }
    }

    contentItem: HRowLayout {
        spacing: button.spacing

        HIcon {
            id: ico
            x: button.leftPadding
            y: button.topPadding + button.availableHeight / 2 - height / 2
            svgName: loading ? "hourglass" : iconName
        }

        HLabel {
            id: label
            text: button.text
            visible: Boolean(text)
            color: theme.controls.button.text
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter

            Layout.fillWidth: true
        }
    }
}
