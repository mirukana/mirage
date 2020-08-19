// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../.."
import "../../Base"
import "../../Base/Buttons"
import "../../PythonBridge"

HBox {
    id: box

    property string acceptedUserUrl: ""
    property string acceptedUrl: ""
    property var loginFlows: []

    property string saveName: "serverBrowser"
    property var saveProperties: ["acceptedUserUrl"]
    property string loadingIconStep: "server-ping-bad"

    property Future connectFuture: null
    property Future fetchServersFuture: null

    signal accepted()

    function takeFocus() { serverField.item.field.forceActiveFocus() }

    function fetchServers() {
        fetchServersFuture = py.callCoro("fetch_homeservers", [], () => {
            fetchServersFuture = null
        }, (type, args, error, traceback) => {
            fetchServersFuture = null
            // TODO
            print( traceback)
        })
    }

    function connect() {
        if (connectFuture) connectFuture.cancel()
        connectTimeout.restart()

        const args = [serverField.item.field.cleanText]

        connectFuture = py.callCoro("server_info", args, ([url, flows]) => {
            connectTimeout.stop()
            serverField.errorLabel.text = ""
            connectFuture               = null

            if (! (
                flows.includes("m.login.password") ||
                (
                    flows.includes("m.login.sso") &&
                    flows.includes("m.login.token")
                )
            )) {
                serverField.errorLabel.text =
                    qsTr("No supported sign-in method for this homeserver.")
                return
            }

            acceptedUrl     = url
            acceptedUserUrl = String(args[0])
            loginFlows      = flows
            accepted()

        }, (type, args, error, traceback, uuid) => {
            console.error(traceback)

            connectTimeout.stop()
            connectFuture = null

            let text = qsTr("Unexpected error: %1 [%2]").arg(type).arg(args)

            type === "MatrixNotFound" ?
            text = qsTr("Invalid homeserver address") :

            type.startsWith("Matrix") ?
            text = qsTr("Connection failed: %1(%2)").arg(type).arg(args) :

            py.showError(type, traceback, uuid)

            serverField.errorLabel.text = text
        })
    }


    padding: 0
    implicitWidth: theme.controls.box.defaultWidth * 1.25
    contentHeight: window.height

    header: HLabel {
        text: qsTr(
            "Choose a homeserver to create your account on, or the " +
            "server on which you made an account to sign in to:"
        )
        wrapMode: HLabel.Wrap
        padding: theme.spacing
    }

    footer: HLabeledItem {
        id: serverField

        readonly property bool knownServerChosen:
            serverList.model.find(item.cleanText) !== null

        label.text: qsTr("Homeserver address:")
        label.topPadding: theme.spacing
        label.leftPadding: label.topPadding
        label.rightPadding: label.topPadding
        errorLabel.leftPadding: label.topPadding
        errorLabel.rightPadding: label.topPadding
        errorLabel.bottomPadding: label.topPadding

        Layout.fillWidth: true
        Layout.margins: theme.spacing

        HRowLayout {
            readonly property alias field: field
            readonly property alias apply: apply

            width: parent.width

            HTextField {
                id: field

                readonly property string cleanText:
                    text.toLowerCase().trim().replace(/\/+$/, "")

                inputMethodHints: Qt.ImhUrlCharactersOnly
                defaultText: window.getState(
                    box, "acceptedUserUrl", "",
                )
                placeholderText: "example.org"

                onTextEdited: py.callCoro(
                    "set_substring_filter", ["filtered_homeservers", text],
                )

                Layout.fillWidth: true
                Layout.fillHeight: true

                Keys.onBacktabPressed: ev => Keys.onUpPressed(ev)
                Keys.onTabPressed: ev => Keys.onDownPressed(ev)
                Keys.onUpPressed: {
                    serverList.decrementCurrentIndex()
                    serverList.setFieldText(serverList.currentIndex)
                }
                Keys.onDownPressed: {
                    serverList.incrementCurrentIndex()
                    serverList.setFieldText(serverList.currentIndex)
                }
            }

            HButton {
                id: apply
                enabled: field.cleanText && ! field.error
                icon.name: "apply"
                icon.color: theme.colors.positiveBackground
                loading: box.connectFuture !== null
                disableWhileLoading: false
                onClicked: box.connect()

                Layout.fillHeight: true
            }
        }
    }

    onKeyboardAccept: if (serverField.item.apply.enabled) box.connect()
    onAccepted: window.saveState(this)

    Timer {
        id: connectTimeout
        interval: 30 * 1000
        onTriggered: {
            serverField.errorLabel.text =
                serverField.knownServerChosen ?

                qsTr("This homeserver seems unavailable. Verify your inter" +
                     "net connection or try again later.") :

                 qsTr("This homeserver seems unavailable. Verify the " +
                      "entered address, your internet connection or try " +
                      "again later.")
        }
    }

    Timer {
        interval: 1000
        running:
            fetchServersFuture === null &&
            ModelStore.get("homeservers").count === 0

        repeat: true
        triggeredOnStart: true
        onTriggered: box.fetchServers()
    }

    Timer {
        interval: theme.animationDuration * 2
        running: true
        repeat: true
        onTriggered:
            box.loadingIconStep = "server-ping-" + (
                box.loadingIconStep === "server-ping-bad" ? "medium" :
                box.loadingIconStep === "server-ping-medium" ? "good" :
                "bad"
            )
    }

    HListView {
        id: serverList

        function setFieldText(fromItemIndex) {
            serverField.item.field.text =
                model.get(fromItemIndex).id.replace(/^https:\/\//, "")
        }

        clip: true
        model: ModelStore.get("filtered_homeservers")

        delegate: ServerDelegate {
            width: serverList.width
            loadingIconStep: box.loadingIconStep
            onClicked: {
                setFieldText(model.index)
                serverField.item.apply.clicked()
            }
        }

        Layout.fillWidth: true
        Layout.fillHeight: true

        Rectangle {
            z: -10
            anchors.fill: parent
            color: theme.colors.strongBackground
        }
    }
}
