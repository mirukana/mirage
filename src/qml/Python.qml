import QtQuick 2.12
import io.thp.pyotherside 1.5

Python {
    id: py


    property bool ready: false
    property bool startupAnyAccountsSaved: false
    property var pendingCoroutines: ({})

    property EventHandlers eventHandlers: EventHandlers {}


    function newQmlFuture() {
        return {
            _pyFuture: null,

            get pyFuture() { return this._pyFuture },

            set pyFuture(value) {
                this._pyFuture = value
                if (this.cancelPending) this.cancel()
            },

            cancelPending: false,

            cancel: function() {
                if (! this.pyFuture) {
                    this.cancelPending = true
                    return
                }

                py.call(py.getattr(this.pyFuture, "cancel"))
            },
        }
    }

    function setattr(obj, attr, value, callback=null) {
        py.call(py.getattr(obj, "__setattr__"), [attr, value], callback)
    }

    function callSync(name, args=[]) {
        return call_sync("APP.backend." + name, args)
    }

    function callCoro(name, args=[], onSuccess=null, onError=null) {
        let uuid = name + "." + CppUtils.uuid()

        pendingCoroutines[uuid] = {onSuccess, onError}

        let qmlFuture = py.newQmlFuture()

        call("APP.call_backend_coro", [name, uuid, args], pyFuture => {
            qmlFuture.pyFuture = pyFuture
        })

        return qmlFuture
    }

    function callClientCoro(
        accountId, name, args=[], onSuccess=null, onError=null
    ) {
        let qmlFuture = py.newQmlFuture()

        callCoro("wait_until_client_exists", [accountId], () => {
            let uuid = accountId + "." + name + "." + CppUtils.uuid()

            pendingCoroutines[uuid] = {onSuccess, onError}

            let call_args = [accountId, name, uuid, args]

            call("APP.call_client_coro", call_args, pyFuture => {
                qmlFuture.pyFuture = pyFuture
            })
        })

        return qmlFuture
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

    Component.onCompleted: {
        for (var func in eventHandlers) {
            if (eventHandlers.hasOwnProperty(func)) {
                setHandler(func.replace(/^on/, ""), eventHandlers[func])
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
