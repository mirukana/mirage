// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../../Base"
import "../../Base/Buttons"

HFlickableColumnPage {
    function takeFocus() { resetButton.forceActiveFocus() }


    footer: AutoDirectionLayout {
        ApplyButton {
            id: resetButton
            text: qsTr("Reset password from Riot")
            icon.name: "reset-password"
            onClicked:
                Qt.openUrlExternally("https://riot.im/app/#/forgot_password")

            Layout.fillWidth: true
        }
    }


    HLabel {
        wrapMode: Text.Wrap
        horizontalAlignment: Qt.AlignHCenter
        text: qsTr(
            "Not implemented yet\n\n" +
            "You can reset your password from another client such as Riot."
        )

        Layout.fillWidth: true
    }
}
