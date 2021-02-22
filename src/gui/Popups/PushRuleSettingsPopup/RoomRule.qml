import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../../Base"
import "../../Base/Buttons"

HColumnLayout {
    readonly property alias idField: idField

    HLabeledItem {
        label.text: qsTr("Room ID:")
        Layout.fillWidth: true

        HTextField {
            id: idField
            width: parent.width
            defaultText: rule.kind === "room" ? rule.rule_id : ""
            placeholderText: qsTr("!room:example.org")
            maximumLength: 255
        }
    }
}
