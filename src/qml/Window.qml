import QtQuick 2.7
import QtQuick.Controls 2.2
import "Base"
import "Models"

ApplicationWindow {
    id: window
    width: 640
    height: 480
    visible: true
    color: "black"
    title: "Harmony QML"

    property bool debug: false
    property bool ready: false

    Component.onCompleted: {
        Qt.application.name        = "harmonyqml"
        Qt.application.displayName = "Harmony QML"
        Qt.application.version     = "0.1.0"
        window.ready = true
    }

    Python { id: py }

    Accounts       { id: accounts }
    Devices        { id: devices }
    RoomCategories { id: roomCategories }
    Rooms          { id: rooms }
    Timelines      { id: timelines }
    Users          { id: users }

    LoadingScreen {
        id: loadingScreen
        anchors.fill: parent
        visible: uiLoader.scale < 1
    }

    Loader {
        id: uiLoader
        anchors.fill: parent

        property bool ready: window.ready && py.ready
        scale: uiLoader.ready ? 1 : 0.5
        source: uiLoader.ready ? "UI.qml" : ""

        Behavior on scale { HNumberAnimation {} }
    }
}
