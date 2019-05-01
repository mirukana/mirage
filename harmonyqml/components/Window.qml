import QtQuick 2.7
import QtQuick.Controls 2.2
import QtQuick.Window 2.7

ApplicationWindow {
    id: appWindow
    visible: true
    width: Math.min(Screen.width, 1152)
    height: Math.min(Screen.height, 768)

    onClosing: Backend.clientManager.deleteAll()

    Loader {
        anchors.fill: parent
        source: "UI.qml"
        objectName: "UILoader"
    }
}
