// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../../Base"
import "../../Base/Buttons"
import "../../PythonBridge"

HBox {
    id: page

    property string acceptedUserUrl: ""
    property string acceptedUrl: ""
    property var loginFlows: []

    property string saveName: "serverBrowser"
    property var saveProperties: ["acceptedUserUrl"]
    property Future connectFuture: null

    signal accepted()

    function takeFocus() { serverField.item.forceActiveFocus() }

    function connect() {
        if (connectFuture) connectFuture.cancel()
        connectTimeout.restart()

        const args = [serverField.item.cleanText]

        connectFuture = py.callCoro("server_info", args, ([url, flows]) => {
            connectTimeout.stop()
            errorMessage.text = ""
            connectFuture     = null

            if (! (
                flows.includes("m.login.password") ||
                (
                    flows.includes("m.login.sso") &&
                    flows.includes("m.login.token")
                )
            )) {
                errorMessage.text =
                    qsTr("No supported sign-in method for this homeserver.")
                return
            }

            acceptedUrl     = url
            acceptedUserUrl = String(args[0])
            loginFlows      = flows
            accepted()

        }, (type, args, error, traceback, uuid) => {
            connectTimeout.stop()
            connectFuture = null

            let text = qsTr("Unexpected error: %1 [%2]").arg(type).arg(args)

            type === "MatrixNotFound" ?
            text = qsTr("Invalid homeserver address") :

            type.startsWith("Matrix") ?
            text = qsTr("Error contacting server: %1").arg(type) :

            py.showError(type, traceback, uuid)

            errorMessage.text = text
        })
    }

    function cancel() {
        if (page.connectFuture) return

        connectTimeout.stop()
        connectFuture.cancel()
        connectFuture = null
    }


    footer: AutoDirectionLayout {
        ApplyButton {
            id: applyButton
            enabled: serverField.item.cleanText && ! serverField.item.error
            text: qsTr("Connect")
            icon.name: "server-connect"
            loading: page.connectFuture !== null
            disableWhileLoading: false
            onClicked: page.connect()
        }

        CancelButton {
            id: cancelButton
            enabled: page.connectFuture !== null
            onClicked: page.cancel()
        }
    }

    onKeyboardAccept: if (applyButton.enabled) page.connect()
    onKeyboardCancel: if (cancelButton.enabled) page.cancel()
    onAccepted: window.saveState(this)

    Timer {
        id: connectTimeout
        interval: 30 * 1000
        onTriggered: {
            errorMessage.text =
                serverField.knownServerChosen ?

                qsTr("This homeserver seems unavailable. Verify your inter" +
                     "net connection or try again in a few minutes.") :

                 qsTr("This homeserver seems unavailable. Verify the " +
                      "entered address, your internet connection or try " +
                      "again in a few minutes.")
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
            readonly property string cleanText:
                text.toLowerCase().trim().replace(/\/+$/, "")

            width: parent.width
            error: ! /https?:\/\/.+/.test(cleanText)
            defaultText:
                window.getState(page, "acceptedUserUrl", "https://matrix.org")
        }
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
