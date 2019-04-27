import QtQuick 2.7

Rectangle {
    property var container: parent

    property real widthForHeight: 0.75
    property int baseHeight: 300
    property int startScalingUpAboveHeight: 1080

    readonly property int baseWidth: baseHeight * widthForHeight
    readonly property int margins: baseHeight * 0.03

    color: Qt.hsla(1, 1, 1, 0.3)
    height: Math.min(container.height, baseHeight)
    width: Math.min(container.width, baseWidth)
    scale: Math.max(1, container.height / startScalingUpAboveHeight)
}
