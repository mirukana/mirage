import QtQuick 2.7
import QtQuick.Layouts 1.3
import "../Base"

Item {
    property string loginWith: "username"
    onFocusChanged: idField.forceActiveFocus()

    HInterfaceBox {
        id: signInBox
        title: "Sign in"
        anchors.centerIn: parent

        enterButtonTarget: "login"

        buttonModel: [
            { name: "register", text: qsTr("Register") },
            { name: "login", text: qsTr("Login") },
            { name: "forgot", text: qsTr("Forgot?") }
        ]

        buttonCallbacks: {
            "register": function(button) {},

            "login": function(button) {
                button.loading = true
                var args = [idField.text, passwordField.text]

                py.callCoro("login_client", args, {}, function(user_id) {
                    pageStack.showPage(
                        "RememberAccount",
                        {"loginWith": loginWith, "userId": user_id}
                    )
                    button.loading = false
                })
            },

            "forgot": function(button) {}
        }

        HRowLayout {
            spacing: signInBox.margins * 1.25
            Layout.margins: signInBox.margins
            Layout.alignment: Qt.AlignHCenter

            Repeater {
                model: ["username", "email", "phone"]

                HButton {
                    iconName: modelData
                    circle: true
                    checked: loginWith == modelData
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
    }
}
