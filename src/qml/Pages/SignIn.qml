import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../Base"

Item {
    property string loginWith: "username"
    readonly property bool canLogin: idField.text && passwordField.text

    onFocusChanged: idField.forceActiveFocus()

    HInterfaceBox {
        id: signInBox
        title: "Sign in"
        anchors.centerIn: parent

        enterButtonTarget: "login"

        buttonModel: [
            { name: "register", text: qsTr("Register"), enabled: false },
            { name: "login", text: qsTr("Login"), enabled: canLogin },
            { name: "forgot", text: qsTr("Forgot?"), enabled: false }
        ]

        buttonCallbacks: ({
            register: button => {},

            login: button => {
                button.loading = true
                let args = [idField.text, passwordField.text]

                py.callCoro("login_client", args, ([success, data]) => {
                    if (success) {
                        // data = userId
                        errorMessage.text = ""
                        pageStack.showPage("RememberAccount", {loginWith,data})
                    } else {
                        errorMessage.text = qsTr(data)
                    }
                    button.loading = false
                })
            },

            forgot: button => {}
        })

        HRowLayout {
            spacing: signInBox.margins * 1.25
            Layout.margins: signInBox.margins
            Layout.alignment: Qt.AlignHCenter

            Repeater {
                model: ["username", "email", "phone"]

                HUIButton {
                    iconName: modelData
                    circle: true
                    checked: loginWith == modelData
                    enabled: modelData == "username"
                    autoExclusive: true
                    checkedLightens: true
                    onClicked: loginWith = modelData
                }
            }
        }

        HTextField {
            id: idField
            placeholderText: qsTr(
                loginWith === "email" ? "Email" :
                loginWith === "phone" ? "Phone" :
                "Username"
            )
            onAccepted: signInBox.clickEnterButtonTarget()

            Layout.fillWidth: true
            Layout.margins: signInBox.margins
        }

        HTextField {
            id: passwordField
            placeholderText: qsTr("Password")
            echoMode: HTextField.Password
            onAccepted: signInBox.clickEnterButtonTarget()

            Layout.fillWidth: true
            Layout.margins: signInBox.margins
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
            Layout.margins: signInBox.margins
        }
    }
}
