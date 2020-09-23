// Copyright Mirage authors & contributors <https://github.com/mirukana/mirage>
// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import Qt.labs.platform 1.1

HFileDialogOpener {
    property string userId
    property string roomId
    property string replyToEventId: ""
    property bool destroyWhenDone: false

    signal replied()


    fill: false
    dialog.title: qsTr("Select a file to send")
    dialog.fileMode: FileDialog.OpenFiles

    onFilesPicked: {
        for (const file of files) {
            const path = Qt.resolvedUrl(file).replace(/^file:/, "")
            const args = [roomId, path, replyToEventId || undefined]

            py.callClientCoro(userId, "send_file", args, () => {
                if (destroyWhenDone) destroy()

            }, (type, args, error, traceback) => {
                console.error(`python:\n${traceback}`)
                if (destroyWhenDone) destroy()
            })

            if (replyToUserId) replied()
        }
    }

    onCancelled: if (destroyWhenDone) destroy()
}
