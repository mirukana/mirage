// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import "../../../Base"

Banner {
    color: theme.chat.unknownDevices.background

    avatar.visible: false
    icon.svgName: "unknown-devices-warning"
    labelText: qsTr("Unknown devices are present in this encrypted room")

    buttonModel: [
        {
            name: "inspect",
            text: qsTr("Inspect"),
            iconName: "unknown-devices-inspect",
        }
    ]

    buttonCallbacks: ({
        inspect: button => {
            print("show")
        }
    })
}
