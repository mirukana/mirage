import QtQuick 2.7
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.4
import "../base" as Base

Image {
    id: loginBackground
    asynchronous: true
    fillMode: Image.PreserveAspectCrop
    cache: false
    source: "../../images/login_background.jpg"

    Rectangle {
        color: Qt.hsla(1, 1, 1, 0.3)

        id: loginBox

        property real widthForHeight: 0.75
        property int baseHeight: 300
        property int baseWidth: baseHeight * widthForHeight
        property int startScalingUpAboveHeight: 1080

        anchors.centerIn: parent
        height: Math.min(parent.height, baseHeight)
        width: Math.min(parent.width, baseWidth)
        scale: Math.max(1, parent.height / startScalingUpAboveHeight)

        Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter

        ColumnLayout {
            anchors.fill: parent
            id: mainColumn

            property int hMargin: loginBox.baseWidth * 0.05
            property int vMargin: hMargin * loginBox.widthForHeight

            Base.HRowLayout {
                Layout.alignment: Qt.AlignHCenter
                Layout.margins: mainColumn.hMargin
                Layout.topMargin: mainColumn.vMargin
                Layout.bottomMargin: mainColumn.vMargin

                Base.HLabel {
                    text: "Sign in"
                    font.pixelSize: Base.HStyle.fontSize.big
                }
            }

            Item { Layout.fillHeight: true }

            Base.HRowLayout {
                Layout.margins: mainColumn.hMargin
                Layout.topMargin: mainColumn.vMargin
                Layout.bottomMargin: mainColumn.vMargin
                Layout.alignment: Qt.AlignHCenter
                spacing: mainColumn.hMargin * 1.25

                Base.HButton {
                    id: loginWithUsernameButton
                    iconName: "username"
                    circle: true
                    checked: true
                    checkable: true
                    autoExclusive: true
                }
                Base.HButton {
                    id: loginWithEmailButton
                    iconName: "email"
                    circle: true
                    checkable: true
                    autoExclusive: true
                }
                Base.HButton {
                    id: loginWithPhoneButton
                    iconName: "phone"
                    circle: true
                    checkable: true
                    autoExclusive: true
                }
            }

            Base.HTextField {
                placeholderText: qsTr(
                    loginWithEmailButton.checked ? "Email" :
                    loginWithPhoneButton.checked ? "Phone" :
                    "Username"
                )

                Layout.fillWidth: true
                Layout.margins: mainColumn.hMargin
                Layout.topMargin: mainColumn.vMargin
                Layout.bottomMargin: mainColumn.vMargin
            }

            Base.HTextField {
                placeholderText: qsTr("Password")

                Layout.fillWidth: true
                Layout.margins: mainColumn.hMargin
                Layout.topMargin: mainColumn.vMargin
                Layout.bottomMargin: mainColumn.vMargin
            }

            Item { Layout.fillHeight: true }

            Base.HRowLayout {
                Base.HButton {
                    text: qsTr("Register")
                    Layout.fillWidth: true
                }
                Base.HButton {
                    text: qsTr("Login")
                    Layout.fillWidth: true

                }
                Base.HButton {
                    text: qsTr("Forgot?")
                    Layout.fillWidth: true
                }
            }
        }
    }
}
