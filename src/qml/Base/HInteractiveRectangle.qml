import QtQuick 2.12

HRectangle {
    id: rectangle

    property bool checkable: false  // TODO
    property bool checked: false
    property bool hovered: false
    readonly property alias pressed: tap.pressed

    readonly property QtObject _ir: theme.controls.interactiveRectangle
    color: _ir.background

    HRectangle {
        anchors.fill: parent

        visible: opacity > 0
        Behavior on opacity { HNumberAnimation { factor: 0.5 } }

        opacity: pressed ? _ir.pressedOpacity :
                 checked ? _ir.checkedOpacity :
                 hovered ? _ir.hoveredOpacity :
                 0

        color: pressed ? _ir.pressedOverlay :
               checked ? _ir.checkedOverlay :
               hovered ? _ir.hoveredOverlay :
               "transparent"
    }

    HoverHandler {
        id: hover
        onHoveredChanged: rectangle.hovered = hovered
    }

    TapHandler { id: tap }
}
