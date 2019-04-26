import QtQuick 2.7
import QtQuick.Controls 2.2
import QtQuick.Window 2.7

ApplicationWindow {
    visible: true
    width: Math.min(Screen.width, 1152)
    height: Math.min(Screen.height, 768)

    Loader {
        anchors.fill: parent
        source: Backend.clientManager.clientCount < 1 ?
                "pages/LoginPage.qml" : "pages/MainUI.qml"
        objectName: "UILoader"
    }
}
