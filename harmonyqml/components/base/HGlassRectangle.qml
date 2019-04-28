import QtQuick 2.7
import QtGraphicalEffects 1.0

Item {
    default property alias children: rectangle.children
    property alias color: rectangle.color
    property alias gradient: rectangle.gradient
    property alias blurRadius: fastBlur.radius
    property alias border: rectangle.border
    property alias radius: rectangle.radius

    ShaderEffectSource {
        id: effectSource
        sourceItem: mainUIBackground
        anchors.fill: parent
        sourceRect: Qt.rect(
            pageStack.x + parent.x, pageStack.y + parent.y, width, height
        )
    }

    FastBlur {
        id: fastBlur
        cached: true
        anchors.fill: effectSource
        source: effectSource
        radius: 8
    }

    Rectangle {
        id: rectangle
        anchors.fill: parent
        color: HStyle.sidePane.background
    }
}
