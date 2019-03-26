import QtQuick 2.7
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.4

Rectangle {
    id: sidePane
    color: "gray"
    clip: true  // Avoid artifacts when resizing pane width to minimum

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        AccountList {
            Layout.fillWidth: true
            Layout.fillHeight: true
        }

        ButtonsBar {}
    }
}
