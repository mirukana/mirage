// Copyright 2019 miruka
// This file is part of harmonyqml, licensed under LGPLv3.

import QtQuick 2.12
import "../../Base"
import "../utils.js" as ChatJS

Banner {
    color: theme.chat.unknownDevices.background

    avatar.visible: false
    icon.svgName: "unknown-devices-warning"
    labelText: "Unknown devices are present in this encrypted room."

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
