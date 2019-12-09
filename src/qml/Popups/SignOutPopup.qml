import QtQuick 2.12
import "../utils.js" as Utils

BoxPopup {
    id: popup
    summary.text: qsTr("Backup your decryption keys before signing out?")
    details.text: qsTr(
        "Signing out will delete your device's information and the keys " +
        "required to decrypt messages in encrypted rooms.\n\n" +

        "You can export your keys to a passphrase-protected file " +
        "before signing out.\n\n" +

        "This will allow you to restore access to your messages when " +
        "you sign in again, by importing this file in your account settings."
    )

    box.focusButton: "ok"
    box.buttonModel: [
        { name: "ok", text: qsTr("Export keys"), iconName: "export-keys" },
        { name: "signout", text: qsTr("Sign out now"), iconName: "sign-out",
          iconColor: theme.colors.middleBackground },
        { name: "cancel", text: qsTr("Cancel"), iconName: "cancel" },
    ]

    box.buttonCallbacks: ({
        ok: button => {
            Utils.makeObject(
                "Dialogs/ExportKeys.qml",
                mainUI,
                { userId },
                obj => {
                    button.loading = Qt.binding(() => obj.exporting)
                    obj.done.connect(() => {
                        box.buttonCallbacks["signout"](button)
                    })
                    obj.dialog.open()
                }
            )
        },

        signout: button => {
            okClicked = true
            popup.ok()

            if ((modelSources["Account"] || []).length < 2) {
                pageLoader.showPage("AddAccount/AddAccount")
            } else if (window.uiState.pageProperties.userId === userId) {
                pageLoader.showPage("Default")
            }

            py.callCoro("logout_client", [userId])
            popup.close()
        },

        cancel: button => { okClicked = false; popup.cancel(); popup.close() },
    })


    property string userId: ""
}
