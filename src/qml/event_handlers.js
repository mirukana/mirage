"use strict"


function onExitRequested(exitCode) {
    Qt.exit(exitCode)
}


function onAlertRequested() {
    if (Qt.application.state != Qt.ApplicationActive) {
		window.alert(window.settings.alertOnMessageForMsec)
	}
}


function onCoroutineDone(uuid, result) {
    py.pendingCoroutines[uuid](result)
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
