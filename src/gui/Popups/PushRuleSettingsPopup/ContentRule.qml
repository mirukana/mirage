import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../../Base"
import "../../Base/Buttons"

HColumnLayout {
    readonly property alias idField: idField

    HLabeledItem {
        // TODO: globbing explanation & do space works?
        label.text: qsTr("Word:")
        Layout.fillWidth: true

        HTextField {
            id: idField
            width: parent.width
            defaultText: rule.kind === "content" ? rule.pattern : ""
        }
    }
}
