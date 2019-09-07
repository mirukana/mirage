import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import "../SidePane"

Popup {
    id: popup
    anchors.centerIn: Overlay.overlay
    modal: true
    padding: 0

    onAboutToShow: {
        acceptedPassword  = ""
        passwordValid     = null
        okClicked         = false
        errorMessage.text = ""
    }
    onOpened: passwordField.forceActiveFocus()

    property bool validateWhileTyping: false

    property string acceptedPassword: ""
    property var passwordValid: null
    property bool okClicked: false

    property alias label: popupLabel
    property alias field: passwordField


    function verifyPassword(pass, callback) {
        // Can be reimplemented when using this component.
        // Pass to the callback true on success, false on invalid password, or
        // a [error message, translated] array for any other error.
        callback(true)
    }


    enter: Transition {
        HNumberAnimation { property: "scale"; from: 0; to: 1; overshoot: 4 }
    }

    exit: Transition {
        HNumberAnimation { property: "scale"; to: 0 }
    }

    background: Rectangle {
        color: theme.controls.popup.background
    }

    contentItem: HBox {
        id: box
        implicitWidth: theme.minimumSupportedWidthPlusSpacing
        enterButtonTarget: "ok"
        buttonModel: [
            { name: "ok", text: qsTr("OK"), iconName: "ok",
              enabled: passwordField.text &&
                       (validateWhileTyping ? passwordValid : true) },
            { name: "cancel", text: qsTr("Cancel"), iconName: "cancel" },
        ]
        buttonCallbacks: ({
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


        HLabel {
            id: popupLabel
            wrapMode: Text.Wrap

            Layout.fillWidth: true
        }

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
                svgName: passwordValid ? "ok" : "cancel"
                visible: Layout.preferredWidth > 0

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
}
