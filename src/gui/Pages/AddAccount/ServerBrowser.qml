// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../.."
import "../../Base"
import "../../Base/Buttons"
import "../../PythonBridge"
import "../../ShortcutBundles"

HBox {
    id: box

    property bool knownHttps: window.getState(box, "knownHttps", false)
    property string acceptedUserUrl: ""
    property string acceptedUrl: ""
    property var loginFlows: []

    property string saveName: "serverBrowser"
    property var saveProperties: ["acceptedUserUrl", "knownHttps"]
    property string loadingIconStep: "server-ping-bad"

    property Future connectFuture: null
    property Future fetchServersFuture: null

    signal accepted()

    function takeFocus() { serverField.item.field.forceActiveFocus() }

    function fetchServers() {
        if (fetchServersFuture) fetchServersFuture.cancel()

        fetchServersFuture = py.callCoro("fetch_homeservers", [], () => {
            fetchServersFuture = null
        }, (type, args, error, traceback) => {
            fetchServersFuture = null
            print( traceback)  // TODO: display error graphically
        })
    }

    function connect() {
        if (connectFuture) connectFuture.cancel()
        connectTimeout.restart()

        const typedUrl = serverField.item.field.cleanText
        const args     = [typedUrl]

        if (box.knownHttps)
            args[0] = args[0].replace(/^(https?:\/\/)?/, "https://")

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
            acceptedUserUrl = typedUrl
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

    header: HColumnLayout {
        HLabel {
            text: qsTr(
                "Choose a homeserver to create an account on, or the " +
                "homeserver where you have an account to sign in to:"
            )
            wrapMode: HLabel.Wrap
            padding: theme.spacing

            Layout.fillWidth: true
        }

        HRowLayout {
            Repeater {
                model: [
                    qsTr("Ping"),
                    qsTr("Name & location"),
                    qsTr("Stability"),
                    qsTr("Site"),
                ]

                HLabel {
                    text: modelData
                    elide: HLabel.ElideRight
                    topPadding: theme.spacing / 2
                    bottomPadding: topPadding
                    leftPadding: theme.spacing / (model.index === 0 ? 2 : 3)
                    rightPadding: theme.spacing / (model.index === 3 ? 1.5 : 3)

                    background: Rectangle {
                        color: theme.controls.button.background
                    }

                    Layout.fillWidth: model.index === 1
                }
            }
        }
    }

    footer: HLabeledItem {
        id: serverField

        readonly property bool knownServerChosen:
            serverList.model.find(item.cleanText) !== null

        label.text: qsTr("Homeserver address:")
        label.topPadding: theme.spacing / 2
        label.bottomPadding: label.topPadding / 4
        label.leftPadding: theme.spacing
        label.rightPadding: label.leftPadding
        errorLabel.leftPadding: label.leftPadding
        errorLabel.rightPadding: label.leftPadding
        errorLabel.bottomPadding: label.leftPadding

        HRowLayout {
            readonly property alias field: field
            readonly property alias apply: apply

            width: parent.width

            HTextField {
                id: field

                readonly property string cleanText:
                    text.toLowerCase().trim().replace(/\/+$/, "")

                inputMethodHints: Qt.ImhUrlCharactersOnly
                defaultText: window.getState(box, "acceptedUserUrl", "")
                placeholderText: "example.org"

                onTextEdited: {
                    py.callCoro(
                        "set_string_filter", ["filtered_homeservers", text],
                    )
                    knownHttps              = false
                    serverList.currentIndex = -1
                }

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
                icon.name: "server-connect-to-address"
                icon.color: theme.colors.positiveBackground
                loading: box.connectFuture !== null
                disableWhileLoading: false
                onClicked: box.connect()

                Layout.fillHeight: true
            }
        }
    }

    onKeyboardAccept:
        if (serverField.item.apply.enabled) serverField.item.apply.clicked()

    onAccepted: window.saveState(this)

    Component.onDestruction:
        if (fetchServersFuture) fetchServersFuture.cancel()

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

    FlickShortcuts {
        flickable: serverList
        active: ! mainUI.debugConsole.visible
    }

    HListView {
        id: serverList

        function setFieldText(fromItemIndex) {
            const url                   = model.get(fromItemIndex).id
            box.knownHttps              = /^https:\/\//.test(url)
            serverField.item.field.text = url.replace(/^https:\/\//, "")
        }

        clip: true
        model: ModelStore.get("filtered_homeservers")

        delegate: ServerDelegate {
            width: serverList.width
            loadingIconStep: box.loadingIconStep
            onClicked: {
                serverList.setFieldText(model.index)
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

        HLoader {
            id: busyIndicatorLoader
            anchors.centerIn: parent
            width: 96 * theme.uiScale
            height: width

            source: "../../Base/HBusyIndicator.qml"
            active: box.fetchServersFuture && ! serverList.count
            opacity: active ? 1 : 0

            Behavior on opacity { HNumberAnimation { factor: 2 } }
        }
    }
}
