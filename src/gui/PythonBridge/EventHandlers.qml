// Copyright Mirage authors & contributors <https://github.com/mirukana/mirage>
// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import "../.."
import ".."

QtObject {
    signal deviceUpdateSignal(string forAccount)

    function onExitRequested(exitCode) {
        Qt.exit(exitCode)
    }

    function onNotificationRequested(id, title, body, image, highImportance) {
        const level = window.notificationLevel

        if (level === Window.NotificationLevel.None) return
        if (level === Window.MentionsKeywords && ! highImportance) return
        if (window.notifiedIds.has(id)) return

        window.notifiedIds.add(id)
        window.notifiedIdsChanged()

        if (Qt.application.state === Qt.ApplicationActive) return

        py.callCoro("desktop_notify", [title, body, image])

        const msec =
            highImportance ?
            window.settings.Notifications.urgent_alert_time * 1000 :
            window.settings.Notifications.alert_time * 1000

        if (msec) window.alert(msec === -1 ? 0 : msec)  // -1 → 0 = no time out
    }

    function onCoroutineDone(uuid, result, error, traceback) {
        if (! Globals.pendingCoroutines[uuid]) return

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
            py.showError(type, traceback, "", uuid)

            return
        }

        if (onSuccess) onSuccess(result)
    }

    function onLoopException(message, error, traceback) {
        // No need to log these here, the asyncio exception handler does it
        const type = py.getattr(py.getattr(error, "__class__"), "__name__")
        py.showError(type, traceback, "", message)
    }

    function onUserFileChanged(type, newData) {
        if (type === "Theme") {
            window.theme = Qt.createQmlObject(newData, window, "theme")
            utils.theme  = window.theme
            return
        }

        type === "Settings" ? window.settings = newData :
        type === "NewTheme" ? window.themeRules = newData :
        type === "UIState" ? window.uiState = newData :
        type === "History" ? window.history = newData :
        null
    }

    function onModelItemSet(syncId, indexThen, indexNow, changedFields) {
        const model = ModelStore.get(syncId)

        if (indexThen === undefined) {
            // print("insert", syncId, indexThen, indexNow,
                  // JSON.stringify(changedFields))
            model.insert(indexNow, changedFields)
            model.idToItems[changedFields.id] = model.get(indexNow)
            model.idToItemsChanged()

        } else {
            // print("set", syncId, indexThen, indexNow,
                  // JSON.stringify(changedFields))
            model.set(indexThen, changedFields)

            if (indexThen !== indexNow) model.move(indexThen, indexNow, 1)

            model.fieldsChanged(indexNow, changedFields)
        }
    }

    function onModelItemDeleted(syncId, index, count=1, ids=[]) {
        // print("delete", syncId, index, count, ids)
        const model = ModelStore.get(syncId)
        model.remove(index, count)

        for (let i = 0; i < ids.length; i++) {
            delete model.idToItems[ids[i]]
        }

        if (ids.length) model.idToItemsChanged()
    }

    function onModelCleared(syncId) {
        // print("clear", syncId)
        const model = ModelStore.get(syncId)
        model.clear()
        model.idToItems = {}
    }

    function onDevicesUpdated(forAccount) {
        deviceUpdateSignal(forAccount)
    }

    function onInvalidAccessToken(userId) {
        window.makePopup("Popups/InvalidAccessTokenPopup.qml", {userId})
    }
}
