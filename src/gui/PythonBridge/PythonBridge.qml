import QtQuick 2.12
import io.thp.pyotherside 1.5

Python {
    id: py
    Component.onCompleted: {
        for (var func in privates.eventHandlers) {
            if (! privates.eventHandlers.hasOwnProperty(func)) continue
            setHandler(func.replace(/^on/, ""), privates.eventHandlers[func])
        }

        addImportPath("src")
        addImportPath("qrc:/src")

        importNames("backend.qml_bridge", ["BRIDGE"], () => {
            loadSettings(() => {
                callCoro("saved_accounts.any_saved", [], any => {
                    if (any) { py.callCoro("load_saved_accounts", []) }

                    py.startupAnyAccountsSaved = any
                    py.ready                   = true
                })
            })
        })
    }


    property bool ready: false
    property bool startupAnyAccountsSaved: false

    readonly property QtObject privates: QtObject {
        readonly property var pendingCoroutines: ({})
        readonly property EventHandlers eventHandlers: EventHandlers {}

        function makeFuture(callback) {
            return Qt.createComponent("Future.qml")
                     .createObject(py, {bridge: py})
        }
    }


    function setattr(obj, attr, value, callback=null) {
        py.call(py.getattr(obj, "__setattr__"), [attr, value], callback)
    }


    function callSync(name, args=[]) {
        return call_sync("BRIDGE.backend." + name, args)
    }


    function callCoro(name, args=[], onSuccess=null, onError=null) {
        let uuid = name + "." + CppUtils.uuid()

        privates.pendingCoroutines[uuid] = {onSuccess, onError}

        let future = privates.makeFuture()

        call("BRIDGE.call_backend_coro", [name, uuid, args], pyFuture => {
            future.privates.pythonFuture = pyFuture
        })

        return future
    }


    function callClientCoro(
        accountId, name, args=[], onSuccess=null, onError=null
    ) {
        let future = privates.makeFuture()

        callCoro("wait_until_client_exists", [accountId], () => {
            let uuid = accountId + "." + name + "." + CppUtils.uuid()

            privates.pendingCoroutines[uuid] = {onSuccess, onError}

            let call_args = [accountId, name, uuid, args]

            call("BRIDGE.call_client_coro", call_args, pyFuture => {
                future.privates.pythonFuture = pyFuture
            })
        })

        return future
    }


    function saveConfig(backend_attribute, data, callback=null) {
        if (! py.ready) { return }  // config not loaded yet
        return callCoro(backend_attribute + ".write", [data], callback)
    }


    function loadSettings(callback=null) {
        let func = "load_settings"

        return callCoro(func, [], ([settings, uiState, history, theme]) => {
            window.settings = settings
            window.uiState  = uiState
            window.history  = history
            window.theme    = Qt.createQmlObject(theme, window, "theme")

            if (callback) { callback(settings, uiState, theme) }
        })
    }
}
