import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import "../SidePane"

Popup {
    id: popup
    anchors.centerIn: Overlay.overlay
    modal: true
    padding: 0

    onOpened: passwordField.forceActiveFocus()


    property bool validateWhileTyping: false

    property string acceptedPassword: ""
    property var passwordValid: null
    property bool okClicked: false

    property alias label: popupLabel
    property alias field: passwordField


    function verifyPassword(pass) {
        // Implement me when using this component
        return false
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

    contentItem: HInterfaceBox {
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

                if (verifyPassword(password)) {
                    passwordValid          = true
                    popup.acceptedPassword = password
                    popup.close()
                } else {
                    passwordValid = false
                }

                button.loading = false
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
    }
}
