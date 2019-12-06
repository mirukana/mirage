import QtQuick 2.12
import QtQuick.Controls 2.12
import io.thp.pyotherside 1.5
import "event_handlers.js" as EventHandlers

Python {
    id: py

    property bool ready: false
    property bool startupAnyAccountsSaved: false
    property var pendingCoroutines: ({})

    function setattr(obj, attr, value, callback=null) {
        py.call(py.getattr(obj, "__setattr__"), [attr, value], callback)
    }

    function callSync(name, args=[]) {
        return call_sync("APP.backend." + name, args)
    }

    function callCoro(name, args=[], onSuccess=null, onError=null) {
        let uuid = name + "." + CppUtils.uuid()

        pendingCoroutines[uuid] = {onSuccess, onError}
        call("APP.call_backend_coro", [name, uuid, args])
    }

    function callClientCoro(
        accountId, name, args=[], onSuccess=null, onError=null
    ) {
        callCoro("wait_until_client_exists", [accountId], () => {
            let uuid = accountId + "." + name + "." + CppUtils.uuid()

            pendingCoroutines[uuid] = {onSuccess, onError}
            call("APP.call_client_coro", [accountId, name, uuid, args])
        })
    }

    function saveConfig(backend_attribute, data, callback=null) {
        if (! py.ready) { return }  // config not loaded yet
        callCoro(backend_attribute + ".write", [data], callback)
    }

    function loadSettings(callback=null) {
        callCoro("load_settings", [], ([settings, uiState, theme]) => {
            window.settings = settings
            window.uiState  = uiState
            window.theme    = Qt.createQmlObject(theme, window, "theme")

            if (callback) { callback(settings, uiState, theme) }
        })
    }

    Component.onCompleted: {
        for (var func in EventHandlers) {
            if (EventHandlers.hasOwnProperty(func)) {
                setHandler(func.replace(/^on/, ""), EventHandlers[func])
            }
        }

        addImportPath("src")
        addImportPath("qrc:/src")
        importNames("python", ["APP"], () => {
            loadSettings(() => {
                callCoro("saved_accounts.any_saved", [], any => {
                    if (any) { py.callCoro("load_saved_accounts", []) }

                    py.startupAnyAccountsSaved = any
                    py.ready                   = true
                })
            })
        })
    }
}
