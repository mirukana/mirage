import QtQuick 2.12
import QtQuick.Controls 2.12

Slider {
    id: slider
    leftPadding: 0
    rightPadding: leftPadding
    topPadding: 0
    bottomPadding: topPadding

    property bool enableRadius: true
    property bool fullHeight: false
    property color backgroundColor: theme.controls.slider.background
    property color foregroundColor: theme.controls.slider.foreground

    property alias toolTip: toolTip
    property alias mouseArea: mouseArea

    background: Rectangle {
        color: backgroundColor
        x: slider.leftPadding
        y: slider.topPadding + slider.availableHeight / 2 - height / 2

        implicitWidth: 200
        implicitHeight: theme.controls.slider.height
        width: slider.availableWidth
        height: fullHeight ? slider.height : implicitHeight
        radius: enableRadius ? theme.controls.slider.radius : 0

        Rectangle {
            width: slider.visualPosition * parent.width
            height: parent.height
            color: foregroundColor
            radius: parent.radius
        }
    }

    handle: Rectangle {
        x: slider.leftPadding + slider.visualPosition *
           (slider.availableWidth - width)
        y: slider.topPadding + slider.availableHeight / 2 - height / 2

        implicitWidth: theme.controls.slider.handle.size
        implicitHeight: implicitWidth
        radius: implicitWidth / 2

        color: slider.pressed ?
               theme.controls.slider.handle.pressedInside :
               theme.controls.slider.handle.inside

        border.color: slider.pressed ?
                      theme.controls.slider.handle.pressedBorder :
                      theme.controls.slider.handle.border

        Behavior on color { HColorAnimation {} }
        Behavior on border.color { HColorAnimation {} }
    }

    HToolTip {
        id: toolTip
        parent: slider.handle
        visible: slider.pressed && text
        delay: 0
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        cursorShape: slider.hovered ? Qt.PointingHandCursor : Qt.ArrowCursor
    }
}
