import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../Base"

HPage {
    property string loginWith: "username"
    readonly property bool canLogin:
        serverField.text && idField.text && passwordField.text &&
        ! serverField.error

    onFocusChanged: idField.forceActiveFocus()

    HBox {
        id: signInBox
        Layout.alignment: Qt.AlignCenter

        title: qsTr("Sign in")
        clickButtonOnEnter: "login"

        buttonModel: [
            { name: "register", text: qsTr("Register"), enabled: false },
            { name: "login", text: qsTr("Login"), enabled: canLogin,
              disableWhileLoading: false },
            { name: "forgot", text: qsTr("Forgot?"), enabled: false },
        ]

        buttonCallbacks: ({
            register: button => {},

            login: button => {
                button.loading    = true
                errorMessage.text = ""

                let args = [
                    idField.text, passwordField.text,
                    undefined, serverField.text,
                ]

                loginTimeout.restart()

                py.callCoro("login_client", args, userId => {
                    loginTimeout.stop()
                    errorMessage.text = ""
                    button.loading    = false

                    py.callCoro(
                        rememberAccount.checked ?
                        "saved_accounts.add": "saved_accounts.delete",

                        [userId]
                    )

                    pageLoader.showPage(
                        "AccountSettings/AccountSettings", {userId}
                    )

                }, type => {
                    if (type === "CancelledError") return

                    loginTimeout.stop()
                    let txt = qsTr("Invalid request or login type")

                    if (type === "MatrixForbidden")
                        txt = qsTr("Invalid username or password")

                    if (type === "MatrixUserDeactivated")
                        txt = qsTr("This account was deactivated")

                    errorMessage.text = txt
                    button.loading    = false
                })
            },

            forgot: button => {}
        })

        Timer {
            id: loginTimeout
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
            spacing: signInBox.horizontalSpacing * 1.25
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: signInBox.verticalSpacing / 2
            Layout.bottomMargin: Layout.topMargin

            Repeater {
                model: ["username", "email", "phone"]

                HButton {
                    icon.name: modelData
                    circle: true
                    checked: loginWith == modelData
                    enabled: modelData == "username"
                    autoExclusive: true
                    onClicked: loginWith = modelData
                }
            }
        }

        HTextField {
            id: serverField
            placeholderText: qsTr("Homeserver URL")
            text: "https://matrix.org"
            error: ! /.+:\/\/.+/.test(cleanText)

            Layout.fillWidth: true


            readonly property string cleanText: text.toLowerCase().trim()

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
                knownServers.includes(cleanText)
        }

        HTextField {
            id: idField
            placeholderText: qsTr(
                loginWith === "email" ? "Email" :
                loginWith === "phone" ? "Phone" :
                "Username"
            )

            Layout.fillWidth: true
        }

        HTextField {
            id: passwordField
            placeholderText: qsTr("Password")
            echoMode: HTextField.Password

            Layout.fillWidth: true
        }

        HCheckBox {
            id: rememberAccount
            text: qsTr("Automatically sign in")
            checked: true
            spacing: signInBox.horizontalSpacing

            Layout.maximumWidth: parent.width
            Layout.alignment: Qt.AlignHCenter
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
}
