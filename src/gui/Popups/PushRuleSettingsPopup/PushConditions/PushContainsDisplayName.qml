import QtQuick 2.12
import ".."
import "../../../Base"

CustomLabel {
    readonly property var matrixObject: ({kind: "contains_display_name"})

    text: qsTr("Message contains my display name")
}
