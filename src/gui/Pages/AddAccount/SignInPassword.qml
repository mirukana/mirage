// Copyright Mirage authors & contributors <https://github.com/mirukana/mirage>
// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../../Base"
import "../../Base/Buttons"

SignInBase {
    id: page

    function takeFocus() { idField.item.forceActiveFocus() }

    function signIn() {
        if (page.loginFutureId) page.loginFutureId = ""

        errorMessage.text = ""

        page.loginFutureId = py.callCoro(
            "password_auth",
            [idField.item.text.trim(), passField.item.text, page.serverUrl],
            page.finishSignIn,

            (type, args, error, traceback, uuid) => {
                page.loginFutureId = ""

                let txt = qsTr(
                    "Invalid request, login type or unknown error: %1",
                ).arg(type)

                type === "MatrixForbidden" ?
                txt = qsTr("Invalid username or password") :

                type === "MatrixUserDeactivated" ?
                txt = qsTr("This account was deactivated") :

                py.showError(type, traceback, uuid)

                page.errorMessage.text = txt
            },
        )
    }

    applyButton.enabled: idField.item.text.trim() && passField.item.text
    applyButton.onClicked: page.signIn()

    HLabeledItem {
        id: idField
        label.text: qsTr("Username:")

        Layout.fillWidth: true

        HTextField {
            width: parent.width
        }
    }

    HLabeledItem {
        id: passField
        label.text: qsTr("Password:")

        Layout.fillWidth: true

        HTextField {
            width: parent.width
            echoMode: HTextField.Password
        }
    }
}
