// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import io.thp.pyotherside 1.5
import CppUtils 0.1
import "Privates"

Python {
    id: py


    readonly property QtObject privates: QtObject {
        function makeFuture(callback) {
            return Qt.createComponent("Future.qml")
                     .createObject(py, { bridge: py })
        }
    }


    function setattr(obj, attr, value, callback=null) {
        py.call(py.getattr(obj, "__setattr__"), [attr, value], callback)
    }

    function callCoro(name, args=[], onSuccess=null, onError=null) {
        const uuid   = name + "." + CppUtils.uuid()
        const future = privates.makeFuture()

        Globals.pendingCoroutines[uuid] = {future, onSuccess, onError}
        Globals.pendingCoroutinesChanged()

        call("BRIDGE.call_backend_coro", [name, uuid, args], pyFuture => {
            future.privates.pythonFuture = pyFuture
        })

        return future
    }

    function callClientCoro(
        accountId, name, args=[], onSuccess=null, onError=null
    ) {
        const future = privates.makeFuture()

        callCoro("get_client", [accountId], () => {
            const uuid = accountId + "." + name + "." + CppUtils.uuid()

            Globals.pendingCoroutines[uuid] = {onSuccess, onError}
            Globals.pendingCoroutinesChanged()

            const call_args = [accountId, name, uuid, args]

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
        const func = "load_settings"

        return callCoro(func, [], ([settings, uiState, history, theme]) => {
            window.settings = settings
            window.uiState  = uiState
            window.history  = history
            window.theme    = Qt.createQmlObject(theme, window, "theme")

            if (callback) { callback(settings, uiState, theme) }
        })
    }
}
