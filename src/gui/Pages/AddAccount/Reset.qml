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
        text: qsTr(
            "Account recovery is not implemented yet. You can reset your " +
            "password using a client that supports it, like Riot."
        )

        Layout.fillWidth: true
    }
}
