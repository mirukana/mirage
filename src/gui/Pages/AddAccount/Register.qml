// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../../Base"
import "../../Base/Buttons"

HFlickableColumnPage {
    function takeFocus() { registerButton.forceActiveFocus() }


    footer: AutoDirectionLayout {
        ApplyButton {
            id: registerButton
            text: qsTr("Register from Riot")
            icon.name: "register"
            onClicked: Qt.openUrlExternally("https://riot.im/app/#/register")

            Layout.fillWidth: true
        }
    }


    HLabel {
        wrapMode: Text.Wrap
        horizontalAlignment: Qt.AlignHCenter
        text: qsTr(
            "Not implemented yet\n\n" +
            "You can create a new account from another client such as Riot."
        )

        Layout.fillWidth: true
    }
}
