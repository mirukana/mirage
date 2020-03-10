// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../../Base"

HBox {
    id: signInBox
    clickButtonOnEnter: "ok"

    buttonModel: [
        { name: "ok", text: qsTr("Register from Riot"), iconName: "register" },
    ]

    buttonCallbacks: ({
        ok: button => {
            Qt.openUrlExternally("https://riot.im/app/#/register")
        }
    })


    HLabel {
        wrapMode: Text.Wrap
        horizontalAlignment: Qt.AlignHCenter
        text: qsTr(
            "Not yet implemented\n\nYou can create a new " +
            "account from another client such as Riot."
        )

        Layout.fillWidth: true
    }
}
