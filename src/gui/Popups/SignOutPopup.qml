// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import ".."
import "../Base"
import "../Base/Buttons"

HFlickableColumnPopup {
    id: popup


    property string userId: ""


    page.footer: AutoDirectionLayout {
        PositiveButton {
            id: exportButton
            text: qsTr("Export keys")
            icon.name: "export-keys"

            onClicked: utils.makeObject(
                "Dialogs/ExportKeys.qml",
                window.mainUI,
                { userId },
                obj => {
                    loading = Qt.binding(() => obj.exporting)
                    obj.done.connect(signOutButton.clicked)
                    obj.dialog.open()
                }
            )
        }

        MiddleButton {
            id: signOutButton
            text: qsTr("Sign out now")
            icon.name: "sign-out"

            onClicked: {
                if (ModelStore.get("accounts").count < 2 ||
                    window.uiState.pageProperties.userId === userId)
                {
                    window.mainUI.pageLoader.showPage("AddAccount/AddAccount")
                }

                py.callCoro("logout_client", [userId])
                popup.close()
            }
        }

        CancelButton {
            onClicked: popup.close()
        }
    }

    onOpened: exportButton.forceActiveFocus()


    SummaryLabel {
        text: qsTr("Backup your decryption keys before signing out?")
    }

    DetailsLabel {
        text: qsTr(
            "Signing out will delete your device's information and the keys " +
            "required to decrypt messages in encrypted rooms.\n\n" +

            "You can export your keys to a passphrase-protected file " +
            "before signing out.\n\n" +

            "This will allow you to restore access to your messages when " +
            "you sign in again, by importing this file in your account " +
            "settings."
        )
    }
}
