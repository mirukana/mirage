import QtQuick 2.7
import QtQuick.Controls 2.2

ApplicationWindow {
    visible: true
    width: 640
    height: 700
    title: "Harmony QML"

    Loader {
        anchors.fill: parent
        source: "UI.qml"
        objectName: "UILoader"
    }
}
