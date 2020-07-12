// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../../Base"
import "../../Base/Buttons"

HFlickableColumnPage {
    id: page


    property string userId


    function takeFocus() { exportButton.forceActiveFocus() }


    footer: AutoDirectionLayout {
        GroupButton {
            id: exportButton
            text: qsTr("Export")
            icon.name: "export-keys"

            onClicked: utils.makeObject(
                "Dialogs/ExportKeys.qml",
                page,
                { userId: page.userId },
                obj => {
                    loading = Qt.binding(() => obj.exporting)
                    obj.dialog.open()
                }
            )
        }

        GroupButton {
            text: qsTr("Import")
            icon.name: "import-keys"

            onClicked: utils.makeObject(
                "Dialogs/ImportKeys.qml",
                page,
                { userId: page.userId },
                obj => { obj.dialog.open() }
            )
        }
    }

    HLabel {
        wrapMode: Text.Wrap
        text: qsTr(
            "The decryption keys for messages received in encrypted rooms " +
            "<b>until present time</b> can be saved " +
            "to a passphrase-protected file.<br><br>" +

            "You can then import this file on any Matrix account or " +
            "client, to be able to decrypt these messages again."
        )
        textFormat: Text.StyledText

        Layout.fillWidth: true
    }
}
