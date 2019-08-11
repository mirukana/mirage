import QtQuick 2.12
import "Base"
import "utils.js" as Utils

HRectangle {
    color: theme ? theme.controls.box.background : "#0f1222"
    Behavior on color { HNumberAnimation {} }

    HBusyIndicator {
        anchors.centerIn: parent
    }
}
