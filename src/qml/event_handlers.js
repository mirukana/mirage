"use strict"


function onExitRequested(exitCode) {
    Qt.exit(exitCode)
}


function onAlertRequested() {
    if (Qt.application.state != Qt.ApplicationActive) {
		window.alert(window.settings.alertOnMessageForMsec)
	}
}


function onCoroutineDone(uuid, result, error, traceback) {
    let onSuccess = py.pendingCoroutines[uuid].onSuccess
    let onError   = py.pendingCoroutines[uuid].onError

    if (error) {
        let type = py.getattr(py.getattr(error, "__class__"), "__name__")
        let args = py.getattr(error, "args")

        onError ?
            onError(type, args, error, traceback) :
            console.error("python: " + uuid + "\n" + traceback)

    } else if (onSuccess) { onSuccess(result) }

    delete pendingCoroutines[uuid]
}


function onModelUpdated(syncId, data, serializedSyncId) {
    if (serializedSyncId == ["Account"] || serializedSyncId[0] == "Room") {
        py.callCoro("get_flat_sidepane_data", [], data => {
            window.sidePaneModelSource = data
        })
    }

    window.modelSources[serializedSyncId] = data
    window.modelSourcesChanged()
}
