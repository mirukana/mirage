// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import ".."
import "../.."

QtObject {
    function onExitRequested(exitCode) {
        Qt.exit(exitCode)
    }


    function onAlertRequested() {
        if (Qt.application.state !== Qt.ApplicationActive) {
            window.alert(window.settings.alertOnMessageForMsec)
        }
    }


    function onCoroutineDone(uuid, result, error, traceback) {
        let onSuccess = Globals.pendingCoroutines[uuid].onSuccess
        let onError   = Globals.pendingCoroutines[uuid].onError

        delete Globals.pendingCoroutines[uuid]

        if (error) {
            const type = py.getattr(py.getattr(error, "__class__"), "__name__")
            const args = py.getattr(error, "args")

            if (type === "CancelledError") {
                console.warn(`python: cancelled: ${uuid}`)
                return
            }

            if (onError) {
                onError(type, args, error, traceback)
                return
            }

            console.error(`python: ${uuid}\n${traceback}`)

            if (window.hideErrorTypes.has(type)) {
                console.warn(
                    "Not showing error popup for this type due to user choice"
                )
                return
            }

            utils.makePopup(
                "Popups/UnexpectedErrorPopup.qml",
                window,
                { errorType: type, traceback },
            )
        }

        if (onSuccess) onSuccess(result)
    }


    function onLoopException(message, error, traceback) {
        // No need to log these here, the asyncio exception handler does it
        const type = py.getattr(py.getattr(error, "__class__"), "__name__")

        if (window.hideErrorTypes.has(type)) {
            console.warn(
                "Not showing error popup for this type due to user choice"
            )
            return
        }

        utils.makePopup(
            "Popups/UnexpectedErrorPopup.qml",
            window,
            { errorType: type, message, traceback },
        )
    }


    function onModelItemInserted(syncId, index, item) {
        // print("insert", syncId, index, item)
        ModelStore.get(syncId).insert(index, item)
    }


    function onModelItemFieldChanged(syncId, oldIndex, newIndex, field, value){
        const model = ModelStore.get(syncId)
        model.setProperty(oldIndex, field, value)

        if (oldIndex !== newIndex) model.move(oldIndex, newIndex, 1)
    }


    function onModelItemDeleted(syncId, index) {
        // print("del", syncId, index)
        ModelStore.get(syncId).remove(index)
    }


    function onModelCleared(syncId) {
        // print("clear", syncId)
        ModelStore.get(syncId).clear()
    }
}
