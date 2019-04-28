import QtQuick 2.7
import QtGraphicalEffects 1.0

Item {
    property bool isPageStackDescendant: true

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
            (isPageStackDescendant ? pageStack.x : 0) + parent.x,
            (isPageStackDescendant ? pageStack.y : 0) + parent.y,
            width,
            height
        )
    }

    FastBlur {
        id: fastBlur
        anchors.fill: effectSource
        source: effectSource
        radius: rectangle.color == "#00000000" ? 0 : 8
    }

    Rectangle {
        id: rectangle
        anchors.fill: parent
        color: HStyle.sidePane.background
    }
}
