// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import ".."
import "../.."

QtObject {
    signal deviceUpdateSignal(string forAccount)


    function onExitRequested(exitCode) {
        Qt.exit(exitCode)
    }


    function onAlertRequested(highImportance) {
        const msec =
            highImportance ?
            window.settings.alertOnMentionForMsec :
            window.settings.alertOnMessageForMsec

        if (Qt.application.state !== Qt.ApplicationActive && msec !== 0) {
            window.alert(msec === -1 ? 0 : msec)  // -1 → 0 = no time out
        }
    }


    function onCoroutineDone(uuid, result, error, traceback) {
        const onSuccess = Globals.pendingCoroutines[uuid].onSuccess
        const onError   = Globals.pendingCoroutines[uuid].onError

        delete Globals.pendingCoroutines[uuid]
        Globals.pendingCoroutinesChanged()

        if (error) {
            const type = py.getattr(py.getattr(error, "__class__"), "__name__")
            const args = py.getattr(error, "args")

            if (type === "CancelledError") return

            onError ?
            onError(type, args, error, traceback, uuid) :
            utils.showError(type, traceback, "", uuid)

            return
        }

        if (onSuccess) onSuccess(result)
    }


    function onLoopException(message, error, traceback) {
        // No need to log these here, the asyncio exception handler does it
        const type = py.getattr(py.getattr(error, "__class__"), "__name__")
        utils.showError(type, traceback, message)
    }


    function onModelItemSet(syncId, indexThen, indexNow, changedFields){
        if (indexThen === undefined) {
            // print("insert", syncId, indexThen, indexNow,
                  // JSON.stringify(changedFields))
            ModelStore.get(syncId).insert(indexNow, changedFields)

        } else {
            // print("set", syncId, indexThen, indexNow,
                  // JSON.stringify(changedFields))
            const model = ModelStore.get(syncId)
            model.set(indexThen, changedFields)

            if (indexThen !== indexNow) model.move(indexThen, indexNow, 1)

            model.fieldsChanged(indexNow, changedFields)
        }
    }


    function onModelItemDeleted(syncId, index, count=1) {
        // print("delete", syncId, index, count)
        ModelStore.get(syncId).remove(index, count)
    }


    function onModelCleared(syncId) {
        // print("clear", syncId)
        ModelStore.get(syncId).clear()
    }


    function onDevicesUpdated(forAccount) {
        deviceUpdateSignal(forAccount)
    }
}
