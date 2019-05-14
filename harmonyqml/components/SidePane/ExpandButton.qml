import QtQuick 2.7
import QtQuick.Layouts 1.3
import "../Base"

HButton {
    property var expandableItem: null

    id: expandButton
    iconName: "expand"
    iconDimension: 16
    backgroundColor: "transparent"
    onClicked: expandableItem.expanded = ! expandableItem.expanded

    iconTransform: Rotation {
        origin.x: expandButton.iconDimension / 2
        origin.y: expandButton.iconDimension / 2
        angle: expandableItem.expanded ? 90 : 180
        Behavior on angle {
            NumberAnimation { duration: HStyle.animationDuration }
        }
    }
}
