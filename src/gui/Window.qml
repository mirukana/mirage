// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Controls 2.12
import "Base"
import "PythonBridge"

ApplicationWindow {
    id: window
    flags: Qt.WA_TranslucentBackground
    minimumWidth: theme ? theme.minimumSupportedWidth : 240
    minimumHeight: theme ? theme.minimumSupportedHeight : 120
    width: Math.min(screen.width, 1152)
    height: Math.min(screen.height, 768)
    visible: true
    color: "transparent"


    // FIXME: Qt 5.13.1 bug, this randomly stops updating after the cursor
    // leaves the window until it's clicked again.
    readonly property alias hovered: windowHover.hovered

    readonly property bool hidden:
        Qt.application.state === Qt.ApplicationSuspended ||
        Qt.application.state === Qt.ApplicationHidden ||
        window.visibility === window.Minimized ||
        window.visibility === window.Hidden

    // NOTE: For JS object variables, the corresponding method to notify
    // key/value changes must be called manually, e.g. settingsChanged().

    property var mainUI: null

    property var settings: ({})
    onSettingsChanged: py.saveConfig("ui_settings", settings)

    property var uiState: ({})
    onUiStateChanged: py.saveConfig("ui_state", uiState)

    property var history: ({})
    onHistoryChanged: py.saveConfig("history", history)

    property var theme: null

    property var hideErrorTypes: new Set()

    readonly property var visibleMenus: ({})
    readonly property var visiblePopups: ({})
    readonly property bool anyPopupOrMenu:
        Object.keys(window.visibleMenus).length > 0 ||
        Object.keys(window.visiblePopups).length > 0


    function saveState(obj) {
        if (! obj.saveName || ! obj.saveProperties ||
            obj.saveProperties.length < 1) return

        const propertyValues = {}

        for (const prop of obj.saveProperties) {
            propertyValues[prop] = obj[prop]
        }

        utils.objectUpdateRecursive(uiState, {
            [obj.saveName]: { [obj.saveId || "ALL"]: propertyValues },
        })

        uiStateChanged()
    }

    function getState(obj, property, defaultValue=undefined) {
        try {
            return uiState[obj.saveName][obj.saveId || "ALL"][property]
        } catch(err) {
            return defaultValue
        }
    }


    PythonRootBridge { id: py }

    Utils { id: utils }

    HoverHandler { id: windowHover }

    HLoader {
        anchors.fill: parent
        source: py.ready ? "" : "LoadingScreen.qml"
    }

    HLoader {
        // true makes the initially loaded chat page invisible for some reason
        asynchronous: false

        anchors.fill: parent
        focus: true
        scale: py.ready ? 1 : 0.5
        source: py.ready ? (Qt.application.arguments[1] || "UI.qml") : ""

        Behavior on scale { HNumberAnimation { overshoot: 5; factor: 1.2 } }
    }
}
