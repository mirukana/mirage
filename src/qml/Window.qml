import QtQuick 2.12
import QtQuick.Controls 2.12
import "Base"

ApplicationWindow {
    id: window
    flags: Qt.WA_TranslucentBackground
    minimumWidth: theme ? theme.minimumSupportedWidth : 240
    minimumHeight: theme ? theme.minimumSupportedHeight : 120
    width: 640
    height: 480
    visible: true
    color: "transparent"

    // Note: For JS object variables, the corresponding method to notify
    // key/value changes must be called manually, e.g. settingsChanged().
    property var modelSources: ({})
    property var sidePaneModelSource: []

    property var mainUI: null

    property var settings: ({})
    onSettingsChanged: py.saveConfig("ui_settings", settings)

    property var uiState: ({})
    onUiStateChanged: py.saveConfig("ui_state", uiState)

    property var theme: null

    Python { id: py }

    HLoader {
        anchors.fill: parent
        source: py.ready ? "" : "LoadingScreen.qml"
    }

    HLoader {
        // true makes the initially loaded chat page invisible for some reason
        asynchronous: false

        id: uiLoader
        anchors.fill: parent
        scale: py.ready ? 1 : 0.5
        source: py.ready ? (Qt.application.arguments[1] || "UI.qml") : ""

        Behavior on scale { HNumberAnimation { overshoot: 5; factor: 1.2 } }
    }
}
