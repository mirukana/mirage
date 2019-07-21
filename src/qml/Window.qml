// Copyright 2019 miruka
// This file is part of harmonyqml, licensed under LGPLv3.

import QtQuick 2.12
import QtQuick.Controls 2.12
import "Base"
import "Models"

ApplicationWindow {
    id: window
    minimumWidth: theme.minimumSupportedWidth
    minimumHeight: theme.minimumSupportedHeight
    width: 640
    height: 480
    visible: true
    title: "Harmony QML"
    color: "black"

    Component.onCompleted: {
        Qt.application.organization = "harmonyqml"
        Qt.application.name         = "harmonyqml"
        Qt.application.displayName  = "Harmony QML"
        Qt.application.version      = "0.1.0"
        window.ready                = true
    }

    property bool debug: false
    property bool ready: false

    // Note: settingsChanged(), uiStateChanged(), etc must be called manually
    property var settings: ({})
    onSettingsChanged: py.saveConfig("ui_settings", settings)

    property var uiState: ({})
    onUiStateChanged: py.saveConfig("ui_state", uiState)

    Theme     { id: theme }
    Shortcuts { id: shortcuts}
    Python    { id: py }

    // Models
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
