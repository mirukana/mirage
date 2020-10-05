// Copyright Mirage authors & contributors <https://github.com/mirukana/mirage>
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

    property string loginFutureId: ""

    readonly property int security:
        serverUrl.startsWith("https://") ?
        SignInBase.Security.Secure :

        ["//localhost", "//127.0.0.1", "//:1"].includes(
            serverUrl.split(":")[1],
        ) ?
        SignInBase.Security.LocalHttp :

        SignInBase.Security.Insecure

    default property alias innerData: inner.data
    readonly property alias rememberAccount: rememberAccount
    readonly property alias errorMessage: errorMessage
    readonly property alias applyButton: applyButton

    signal exitRequested()

    function finishSignIn(receivedUserId) {
        errorMessage.text  = ""
        page.loginFutureId = ""

        py.callCoro(
            rememberAccount.checked ?
            "saved_accounts.add":
            "saved_accounts.forget",

            [receivedUserId]
        )

        pageLoader.show(
            "Pages/AccountSettings/AccountSettings.qml",
            {userId: receivedUserId},
        )
    }

    function cancel() {
        if (! page.loginFutureId) {
            page.exitRequested()
            return
        }

        py.cancelCoro(page.loginFutureId)
        page.loginFutureId = ""
    }


    flickable.topMargin: theme.spacing * 1.5
    flickable.bottomMargin: flickable.topMargin

    footer: AutoDirectionLayout {
        ApplyButton {
            id: applyButton

            text: qsTr("Sign in")
            icon.name: "sign-in"
            loading: page.loginFutureId !== ""
            disableWhileLoading: false
        }

        CancelButton {
            onClicked: page.cancel()
        }
    }

    onKeyboardAccept: if (applyButton.enabled) applyButton.clicked()
    onKeyboardCancel: page.cancel()
    Component.onDestruction: if (loginFutureId) py.cancelCoro(loginFutureId)

    HButton {
        icon.name: "sign-in-" + (
            page.security === SignInBase.Security.Insecure ? "insecure" :
            page.security === SignInBase.Security.LocalHttp ? "local-http" :
            "secure"
        )

        icon.color:
            page.security === SignInBase.Security.Insecure ?
            theme.colors.negativeBackground :

            page.security === SignInBase.Security.LocalHttp ?
            theme.colors.middleBackground :

            theme.colors.positiveBackground

        text:
            page.security === SignInBase.Security.Insecure ?
            page.serverUrl :
            page.displayUrl.replace(/^(https?:\/\/)?(www\.)?/, "")

        onClicked: page.exitRequested()

        Layout.alignment: Qt.AlignCenter
        Layout.maximumWidth: parent.width
    }

    HColumnLayout {
        id: inner
        spacing: page.column.spacing
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
