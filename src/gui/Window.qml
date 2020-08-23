// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Controls 2.12
import "Base"
import "PythonBridge"

ApplicationWindow {
    id: window

    // FIXME: Qt 5.13.1 bug, this randomly stops updating after the cursor
    // leaves the window until it's clicked again.

    readonly property bool hidden:
        Qt.application.state === Qt.ApplicationSuspended ||
        Qt.application.state === Qt.ApplicationHidden ||
        window.visibility === window.Minimized ||
        window.visibility === window.Hidden

    property var mainUI: null
    property var settings: ({})
    property var uiState: ({})
    property var history: ({})
    property var theme: null

    readonly property var visibleMenus: ({})
    readonly property var visiblePopups: ({})
    readonly property bool anyMenu: Object.keys(visibleMenus).length > 0
    readonly property bool anyPopup: Object.keys(visiblePopups).length > 0
    readonly property bool anyPopupOrMenu: anyMenu || anyPopup


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
            const props = uiState[obj.saveName][obj.saveId || "ALL"]
            return property in props ? props[property] : defaultValue
        } catch(err) {
            return defaultValue
        }
    }

    function makePopup(
        urlComponent, properties={}, callback=null, autoDestruct=true,
    ) {
        utils.makePopup(
            urlComponent, window, properties, callback, autoDestruct,
        )
    }



    flags: Qt.WA_TranslucentBackground
    minimumWidth: theme ? theme.minimumSupportedWidth : 240
    minimumHeight: theme ? theme.minimumSupportedHeight : 120
    width: Math.min(screen.width, 1152)
    height: Math.min(screen.height, 768)
    visible: true
    color: "transparent"

    // NOTE: For JS object variables, the corresponding method to notify
    // key/value changes must be called manually, e.g. settingsChanged().
    onSettingsChanged: py.saveConfig("ui_settings", settings)
    onUiStateChanged: py.saveConfig("ui_state", uiState)
    onHistoryChanged: py.saveConfig("history", history)

    PythonRootBridge { id: py }

    Utils { id: utils }

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

        Behavior on scale { HNumberAnimation { overshoot: 3; factor: 1.2 } }
    }
}
