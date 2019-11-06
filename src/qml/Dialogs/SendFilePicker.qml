import QtQuick 2.12

HFileDialogOpener {
    fill: false
    dialog.title: qsTr("Select a file to send")

    onFilePicked: {
        let path = Qt.resolvedUrl(file).replace(/^file:/, "")
        py.callClientCoro(userId, "send_file", [roomId, path], () => {
            if (destroyWhenDone) destroy()
        })
    }

    onCancelled: if (destroyWhenDone) destroy()


    property string userId
    property string roomId
    property bool destroyWhenDone: false
}
