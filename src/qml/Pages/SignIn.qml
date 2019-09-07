import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../Base"

HPage {
    property string loginWith: "username"
    readonly property bool canLogin:
        serverField.text && idField.text && passwordField.text

    onFocusChanged: idField.forceActiveFocus()

    HBox {
        id: signInBox
        Layout.alignment: Qt.AlignCenter

        multiplyWidth: 0.85
        title: qsTr("Sign in")
        enterButtonTarget: "login"

        buttonModel: [
            { name: "register", text: qsTr("Register"), enabled: false },
            { name: "login", text: qsTr("Login"), enabled: canLogin },
            { name: "forgot", text: qsTr("Forgot?"), enabled: false },
        ]

        buttonCallbacks: ({
            register: button => {},

            login: button => {
                button.loading = true
                let args = [
                    idField.text, passwordField.text,
                    undefined, serverField.text,
                ]

                py.callCoro("login_client", args, ([success, data]) => {
                    if (! success) {
                        errorMessage.text = qsTr(data)
                        button.loading = false
                        return
                    }

                    py.callCoro(
                        "saved_accounts." +
                        (rememberAccount.checked ? "add": "delete"),
                        [data]
                    )
                    pageLoader.showPage(
                        "EditAccount/EditAccount", {userId: data}
                    )

                    errorMessage.text = ""
                    button.loading    = false
                })
            },

            forgot: button => {}
        })

        HRowLayout {
            spacing: signInBox.horizontalSpacing * 1.25
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: signInBox.verticalSpacing / 2
            Layout.bottomMargin: Layout.topMargin

            Repeater {
                model: ["username", "email", "phone"]

                HButton {
                    icon.name: modelData
                    iconItem.dimension: 24
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

            Layout.fillWidth: true
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
