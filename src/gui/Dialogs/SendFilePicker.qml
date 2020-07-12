// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import Qt.labs.platform 1.1

HFileDialogOpener {
    property string userId
    property string roomId
    property bool destroyWhenDone: false


    fill: false
    dialog.title: qsTr("Select a file to send")
    dialog.fileMode: FileDialog.OpenFiles

    onFilesPicked: {
        for (const file of files) {
            const path = Qt.resolvedUrl(file).replace(/^file:/, "")

            utils.sendFile(userId, roomId, path, () => {
                if (destroyWhenDone) destroy()
            },
            (type, args, error, traceback) => {
                console.error(`python:\n${traceback}`)
                if (destroyWhenDone) destroy()
            })
        }
    }

    onCancelled: if (destroyWhenDone) destroy()
}
