// Copyright Mirage authors & contributors <https://github.com/mirukana/mirage>
// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import io.thp.pyotherside 1.5
import CppUtils 0.1
import "."

Python {
    id: py

    readonly property var pendingCoroutines: Globals.pendingCoroutines

    function makeFuture(callback) {
        return Qt.createComponent("Future.qml").createObject(py, {bridge: py})
    }

    function setattr(obj, attr, value, callback=null) {
        py.call(py.getattr(obj, "__setattr__"), [attr, value], callback)
    }

    function callCoro(name, args=[], onSuccess=null, onError=null) {
        const uuid   = name + "." + CppUtils.uuid()
        const future = makeFuture()

        Globals.pendingCoroutines[uuid] = {future, onSuccess, onError}
        Globals.pendingCoroutinesChanged()
        // if (name  === "models.ensure_exists_from_qml") { print("r");  return}

        call("BRIDGE.call_backend_coro", [name, uuid, args], pyFuture => {
            future.privates.pythonFuture = pyFuture
        })

        return future
    }

    function callClientCoro(
        accountId, name, args=[], onSuccess=null, onError=null
    ) {
        const future = makeFuture()

        callCoro("get_client", [accountId, [name, args]], () => {
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
            utils.theme     = window.theme

            if (callback) { callback(settings, uiState, theme) }
        })
    }

    function showError(type, traceback, sourceIndication="", message="") {
        console.error(`python: ${sourceIndication}\n${traceback}`)

        if (Globals.hideErrorTypes.has(type)) {
            console.info("Not showing popup for ignored error type " + type)
            return
        }

        window.makePopup(
            "Popups/UnexpectedErrorPopup.qml",
            { errorType: type, message, traceback },
        )
    }
}
