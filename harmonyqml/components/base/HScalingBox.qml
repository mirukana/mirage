import QtQuick 2.7

HGlassRectangle {
    property real widthForHeight: 0.75
    property int baseHeight: 300
    property int startScalingUpAboveHeight: 1080

    readonly property int baseWidth: baseHeight * widthForHeight
    readonly property int margins: baseHeight * 0.03

    color: HStyle.box.background
    height: Math.min(parent.height, baseHeight)
    width: Math.min(parent.width, baseWidth)
    scale: Math.max(1, parent.height / startScalingUpAboveHeight)
}
