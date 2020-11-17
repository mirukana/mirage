// Copyright Mirage authors & contributors <https://github.com/mirukana/mirage>
// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import "."

PythonBridge {
    property bool ready: false
    property bool startupAnyAccountsSaved: false

    readonly property EventHandlers eventHandlers: EventHandlers {}

    Component.onCompleted: {
        for (var func in eventHandlers) {
            if (! eventHandlers.hasOwnProperty(func)) continue
            if (! func.startsWith("on")) continue
            setHandler(func.replace(/^on/, ""), eventHandlers[func])
        }

        addImportPath("src")
        addImportPath("qrc:/src")

        importNames("backend.qml_bridge", ["BRIDGE"], () => {
            callCoro("get_settings", [], ([settings, state, hist, theme, themeRules]) => {
                window.settings   = settings
                window.uiState    = state
                window.history    = hist
                window.theme      = Qt.createQmlObject(theme, window, "theme")
                utils.theme       = window.theme
                window.themeRules = themeRules

                callCoro("saved_accounts.any_saved", [], any => {
                    if (any) { callCoro("load_saved_accounts", []) }

                    startupAnyAccountsSaved = any
                    ready                   = true
                })
            })
        })
    }
}
