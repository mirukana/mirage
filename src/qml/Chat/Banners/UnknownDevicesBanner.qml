import QtQuick 2.7
import "../../Base"
import "../utils.js" as ChatJS

Banner {
    color: theme.chat.unknownDevices.background

    avatar.visible: false
    icon.svgName: "unknown_devices_warning"
    labelText: "Unknown devices are present in this encrypted room."

    buttonModel: [
        {
            name: "inspect",
            text: qsTr("Inspect"),
            iconName: "unknown_devices_inspect",
        }
    ]

    buttonCallbacks: {
        "inspect": function(button) {
            print("show")
        },
    }
}
