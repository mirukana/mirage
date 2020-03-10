// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../../Base"

HBox {
    id: signInBox
    clickButtonOnEnter: "ok"

    buttonModel: [
        {
            name: "ok",
            text: qsTr("Reset password from Riot"),
            iconName: "reset-password"
        },
    ]

    buttonCallbacks: ({
        ok: button => {
            Qt.openUrlExternally("https://riot.im/app/#/forgot_password")
        }
    })


    HLabel {
        wrapMode: Text.Wrap
        horizontalAlignment: Qt.AlignHCenter
        text: qsTr(
            "Not yet implemented\n\nYou can reset your " +
            "password using another client such as Riot."
        )

        Layout.fillWidth: true
    }
}
