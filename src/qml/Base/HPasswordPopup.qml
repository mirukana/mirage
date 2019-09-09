import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import "../SidePane"

HBoxPopup {
    id: popup

    onAboutToShow: {
        okClicked         = false
        acceptedPassword  = ""
        passwordValid     = null
        errorMessage.text = ""
    }
    onOpened: passwordField.forceActiveFocus()


    property bool validateWhileTyping: false

    property string acceptedPassword: ""
    property var passwordValid: null

    property alias field: passwordField


    function verifyPassword(pass, callback) {
        // Can be reimplemented when using this component.
        // Pass to the callback true on success, false on invalid password, or
        // a [error message, translated] array for any other error.
        callback(true)
    }


    box.buttonCallbacks: ({
        ok: button => {
            let password   = passwordField.text
            okClicked      = true
            button.loading = true

            verifyPassword(password, result => {
                if (result === true) {
                    passwordValid          = true
                    popup.acceptedPassword = password
                    popup.close()
                } else if (result === false) {
                    passwordValid = false
                } else {
                    let [msg, translated] = result
                    errorMessage.text     = translated ? msg : qsTr(msg)
                }

                button.loading = false
            })
        },
        cancel: button => { popup.close() },
    })


    HRowLayout {
        spacing: box.horizontalSpacing

        HTextField {
            id: passwordField
            placeholderText: qsTr("Passphrase")
            echoMode: TextInput.Password
            focus: true
            error: passwordValid === false

            onTextChanged: passwordValid =
                validateWhileTyping ? verifyPassword(text) : null

            Layout.fillWidth: true
        }

        HIcon {
            visible: Layout.preferredWidth > 0
            svgName: passwordValid ? "ok" : "cancel"
            colorize: passwordValid ?
                      theme.colors.positiveBackground :
                      theme.colors.negativeBackground

            Layout.preferredWidth:
                passwordValid == null ||
                (validateWhileTyping && ! okClicked && ! passwordValid) ?
                0 :implicitWidth

            Behavior on Layout.preferredWidth { HNumberAnimation {} }
        }
    }

    HLabel {
        id: errorMessage
        wrapMode: Text.Wrap
        color: theme.colors.errorText

        visible: Layout.maximumHeight > 0
        Layout.maximumHeight: text ? implicitHeight : 0
        Behavior on Layout.maximumHeight { HNumberAnimation {} }

        Layout.fillWidth: true
    }
}
