import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Shapes 1.12

BusyIndicator {
    id: indicator
    implicitWidth: theme ? theme.controls.loader.defaultDimension : 96
    implicitHeight: implicitWidth

    contentItem: HIcon {
        svgName: "loader"
        dimension: indicator.width
        property var pr: dimension
        colorize: theme ? theme.controls.loader.colorize : "white"
        mipmap: true

        RotationAnimation on rotation {
            id: rotationAnimation
            from: 0
            to: 360
            running: true
            loops: Animation.Infinite
            duration: theme ? (theme.animationDuration * 6) : 600
            easing.type: Easing.Linear
        }
    }
}
