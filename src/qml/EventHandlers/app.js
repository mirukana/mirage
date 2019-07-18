// Copyright 2019 miruka
// This file is part of harmonyqml, licensed under LGPLv3.

function onExitRequested(exitCode) {
    Qt.exit(exitCode)
}

function onCoroutineDone(uuid, result) {
    py.pendingCoroutines[uuid](result)
    delete pendingCoroutines[uuid]
}
