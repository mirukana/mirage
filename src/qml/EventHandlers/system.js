function onAppExitRequested(exit_code) {
    Qt.exit(exit_code)
}

function onCoroutineDone(uuid, result) {
    py.pendingCoroutines[uuid](result)
    delete pendingCoroutines[uuid]
}
