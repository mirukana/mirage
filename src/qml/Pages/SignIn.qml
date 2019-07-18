// Copyright 2019 miruka
// This file is part of harmonyqml, licensed under LGPLv3.

import QtQuick 2.12
import QtQuick.Layouts 1.12
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

        buttonCallbacks: ({
            register: button => {},

            login: button => {
                button.loading = true
                var args = [idField.text, passwordField.text]

                py.callCoro("login_client", args, user_id => {
                    pageStack.showPage("RememberAccount", {loginWith, user_id})
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
