// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../Base"
import "../Base/Buttons"

HFlickableColumnPopup {
    id: popup

    property bool validateWhileTyping: false

    property string acceptedPassword: ""
    property var passwordValid: null
    property bool okClicked: false

    readonly property alias summary: summary
    readonly property alias details: details
    readonly property alias validateButton: validateButton

    signal cancelled()

    function verifyPassword(pass, callback) {
        // Can be reimplemented when using this component.
        // Pass to the callback true on success, false on invalid password,
        // or a custom error message string.
        callback(true)
    }

    function validate() {
        const password         = passwordField.text
        okClicked              = true
        validateButton.loading = true
        errorMessage.text      = ""

        verifyPassword(password, result => {
            if (result === true) {
                passwordValid          = true
                popup.acceptedPassword = password
                popup.close()
            } else if (result === false) {
                passwordValid = false
            } else {
                errorMessage.text = result
            }

            validateButton.loading = false
        })
    }


    page.footer: AutoDirectionLayout {
        ApplyButton {
            id: validateButton
            text: qsTr("Confirm")
            enabled: Boolean(passwordField.text)
            onClicked: validate()
        }

        CancelButton {
            onClicked: {
                popup.close()
                cancelled()
            }
        }
    }

    onAboutToShow: {
        okClicked         = false
        acceptedPassword  = ""
        passwordValid     = null
        errorMessage.text = ""
    }

    onOpened: passwordField.forceActiveFocus()
    onKeyboardAccept: popup.validate()

    SummaryLabel { id: summary }

    DetailsLabel { id: details }

    HRowLayout {
        spacing: theme.spacing

        HTextField {
            id: passwordField
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
                passwordValid === null ||
                (validateWhileTyping && ! okClicked && ! passwordValid) ?
                0 :
                implicitWidth

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
