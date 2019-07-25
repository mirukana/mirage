// Copyright 2019 miruka
// This file is part of harmonyqml, licensed under LGPLv3.

import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import "../SidePane"

Popup {
    id: popup
    width: window.width
    anchors.centerIn: Overlay.overlay
    modal: true

    onOpened: passwordField.forceActiveFocus()

    property alias label: popupLabel
    property alias field: passwordField
    property string password: ""

    background: HRectangle {
        color: theme.controls.popup.background
    }

    HColumnLayout {
        width: parent.width
        spacing: theme.spacing

        HLabel {
            id: popupLabel
            wrapMode: Text.Wrap

            Layout.alignment: Qt.AlignCenter
            Layout.minimumWidth: theme.minimumSupportedWidth
            Layout.maximumWidth:
                Math.min(480, window.width - theme.spacing * 2)
        }

        HTextField {
            id: passwordField
            echoMode: TextInput.Password
            focus: true
            onAccepted: {
                popup.password = text
                popup.close()
            }

            Layout.alignment: Qt.AlignCenter
            Layout.fillWidth: true

            Layout.preferredWidth: popupLabel.width
            Layout.maximumWidth: popupLabel.width
        }
    }
}
