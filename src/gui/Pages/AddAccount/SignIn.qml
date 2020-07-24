// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../../Base"
import "../../Base/Buttons"

HFlickableColumnPage {
    id: page

    enum Security { Insecure, LocalHttp, Secure }

    property string serverUrl
    property string displayUrl: serverUrl
    property var loginFuture: null

    signal exitRequested()

    readonly property int security:
        serverUrl.startsWith("https://") ?
        SignIn.Security.Secure :

        ["//localhost", "//127.0.0.1", "//:1"].includes(
            serverUrl.split(":")[1],
        ) ?
        SignIn.Security.LocalHttp :

        SignIn.Security.Insecure

    function takeFocus() { idField.item.forceActiveFocus() }

    function signIn() {
        if (page.loginFuture) page.loginFuture.cancel()

        errorMessage.text = ""

        const args = [
            idField.item.text.trim(), passwordField.item.text,
            undefined, page.serverUrl,
        ]

        page.loginFuture = py.callCoro("login_client", args, userId => {
            errorMessage.text = ""
            page.loginFuture  = null

            print(rememberAccount.checked)
            py.callCoro(
                rememberAccount.checked ?
                "saved_accounts.add": "saved_accounts.delete",

                [userId]
            )

            pageLoader.showPage(
                "AccountSettings/AccountSettings", {userId}
            )

        }, (type, args, error, traceback, uuid) => {
            page.loginFuture = null

            let txt = qsTr(
                "Invalid request, login type or unknown error: %1",
            ).arg(type)

            type === "MatrixForbidden" ?
            txt = qsTr("Invalid username or password") :

            type === "MatrixUserDeactivated" ?
            txt = qsTr("This account was deactivated") :

            utils.showError(type, traceback, uuid)

            errorMessage.text = txt
        })
    }

    function cancel() {
        if (! page.loginFuture) {
            page.exitRequested()
            return
        }

        page.loginFuture.cancel()
        page.loginFuture = null
    }


    flickable.topMargin: theme.spacing * 1.5
    flickable.bottomMargin: flickable.topMargin

    footer: AutoDirectionLayout {
        ApplyButton {
            id: applyButton
            enabled: idField.item.text.trim() && passwordField.item.text
            text: qsTr("Sign in")
            icon.name: "sign-in"
            loading: page.loginFuture !== null
            disableWhileLoading: false
            onClicked: page.signIn()
        }

        CancelButton {
            onClicked: page.cancel()
        }
    }

    onKeyboardAccept: if (applyButton.enabled) page.signIn()
    onKeyboardCancel: page.cancel()

    HButton {
        icon.name: "sign-in-" + (
            page.security === SignIn.Security.Insecure ? "insecure" :
            page.security === SignIn.Security.LocalHttp ? "local-http" :
            "secure"
        )

        icon.color:
            page.security === SignIn.Security.Insecure ?
            theme.colors.negativeBackground :

            page.security === SignIn.Security.LocalHttp ?
            theme.colors.middleBackground :

            theme.colors.positiveBackground

        text:
            page.security === SignIn.Security.Insecure ?
            page.serverUrl :
            page.displayUrl.replace(/^(https?:\/\/)?(www\.)?/, "")

        onClicked: page.exitRequested()

        Layout.alignment: Qt.AlignCenter
        Layout.maximumWidth: parent.width
    }

    HLabeledItem {
        id: idField
        label.text: qsTr("Username:")

        Layout.fillWidth: true

        HTextField {
            width: parent.width
        }
    }

    HLabeledItem {
        id: passwordField
        label.text: qsTr("Password:")

        Layout.fillWidth: true

        HTextField {
            width: parent.width
            echoMode: HTextField.Password
        }
    }

    HCheckBox {
        id: rememberAccount
        checked: true
        text: qsTr("Remember my account")
        subtitle.text: qsTr(
            "An access token will be stored on this device to " +
            "automatically sign you in."
        )

        Layout.fillWidth: true
        Layout.topMargin: theme.spacing / 2
    }

    HLabel {
        id: errorMessage
        wrapMode: HLabel.Wrap
        horizontalAlignment: Text.AlignHCenter
        color: theme.colors.errorText

        visible: Layout.maximumHeight > 0
        Layout.maximumHeight: text ? implicitHeight : 0
        Behavior on Layout.maximumHeight { HNumberAnimation {} }

        Layout.fillWidth: true
    }
}
