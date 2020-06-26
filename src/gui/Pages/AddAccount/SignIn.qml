// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../../Base"
import "../../Base/ButtonLayout"

HFlickableColumnPage {
    id: page


    property var loginFuture: null

    property string signInWith: "username"

    readonly property bool canSignIn:
        serverField.item.text.trim() && idField.item.text.trim() &&
        passwordField.item.text && ! serverField.item.error


    function takeFocus() { idField.item.forceActiveFocus() }

    function signIn() {
        if (page.loginFuture) page.loginFuture.cancel()

        signInTimeout.restart()

        errorMessage.text = ""

        const args = [
            idField.item.text.trim(), passwordField.item.text,
            undefined, serverField.item.text.trim(),
        ]

        page.loginFuture = py.callCoro("login_client", args, userId => {
            signInTimeout.stop()
            errorMessage.text = ""
            page.loginFuture  = null

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
            signInTimeout.stop()

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
        if (! page.loginFuture) return

        signInTimeout.stop()
        page.loginFuture.cancel()
        page.loginFuture = null
    }


    footer: ButtonLayout {
        ApplyButton {
            enabled: page.canSignIn
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

    onKeyboardAccept: page.signIn()
    onKeyboardCancel: page.cancel()


    Timer {
        id: signInTimeout
        interval: 30 * 1000
        onTriggered: {
            errorMessage.text =
                serverField.knownServerChosen ?

                qsTr("This server seems unavailable. Verify your inter" +
                     "net connection or try again in a few minutes.") :

                 qsTr("This server seems unavailable. Verify the " +
                      "entered URL, your internet connection or try " +
                      "again in a few minutes.")
        }
    }

    HRowLayout {
        visible: false  // TODO
        spacing: theme.spacing * 1.25
        Layout.alignment: Qt.AlignHCenter

        Layout.topMargin: theme.spacing
        Layout.bottomMargin: Layout.topMargin

        Repeater {
            model: ["username", "email", "phone"]

            HButton {
                icon.name: modelData
                circle: true
                checked: page.signInWith === modelData
                enabled: modelData === "username"
                autoExclusive: true
                onClicked: page.signInWith = modelData
            }
        }
    }

    HLabeledItem {
        id: idField
        label.text: qsTr(
            page.signInWith === "email" ? "Email:" :
            page.signInWith === "phone" ? "Phone:" :
            "Username:"
        )

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

    HLabeledItem {
        id: serverField

        // 2019-11-11 https://www.hello-matrix.net/public_servers.php
        readonly property var knownServers: [
            "https://matrix.org",
            "https://chat.weho.st",
            "https://tchncs.de",
            "https://chat.privacytools.io",
            "https://hackerspaces.be",
            "https://matrix.allmende.io",
            "https://feneas.org",
            "https://junta.pl",
            "https://perthchat.org",
            "https://matrix.tedomum.net",
            "https://converser.eu",
            "https://ru-matrix.org",
            "https://matrix.sibnsk.net",
            "https://alternanet.fr",
        ]

        readonly property bool knownServerChosen:
            knownServers.includes(item.cleanText)

        label.text: qsTr("Homeserver:")

        Layout.fillWidth: true

        HTextField {
            width: parent.width
            text: "https://matrix.org"
            error: ! /.+:\/\/.+/.test(cleanText)

            readonly property string cleanText: text.toLowerCase().trim()
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
        Layout.bottomMargin: Layout.topMargin
    }

    HLabel {
        id: errorMessage
        wrapMode: Text.Wrap
        horizontalAlignment: Text.AlignHCenter
        color: theme.colors.errorText

        visible: Layout.maximumHeight > 0
        Layout.maximumHeight: text ? implicitHeight : 0
        Behavior on Layout.maximumHeight { HNumberAnimation {} }

        Layout.fillWidth: true
    }
}
