import QtQuick 2.12
import "../Base"

HUIButton {
    property var expandableItem: null

    id: expandButton
    iconName: "expand"
    iconDimension: 16
    backgroundColor: "transparent"
    onClicked: expandableItem.expanded = ! expandableItem.expanded

    visible: opacity > 0
    opacity: expandableItem.forceExpand ? 0 : 1
    Behavior on opacity { HNumberAnimation {} }

    iconTransform: Rotation {
        origin.x: expandButton.iconDimension / 2
        origin.y: expandButton.iconDimension / 2
        angle: expandableItem.expanded || expandableItem.forceExpand ? 90 : 180
        Behavior on angle { HNumberAnimation {} }
    }
}
