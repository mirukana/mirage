import QtQuick 2.7
import QtQuick.Controls 2.0
import QtQuick.Layouts 1.4

Row {
    readonly property string displayName:
        Backend.getUser(section).display_name

    id: row
    width: roomListView.width
    height: Math.max(accountLabel.height + statusEdit.height, avatar.height)

    Avatar { id: avatar; username: displayName; dimmension: 32 }

    Rectangle {
        color: "#111"
        width: parent.width - avatar.width
        height: parent.height

        ColumnLayout {
            anchors.fill: parent
            spacing: 1

            PlainLabel {
                id: accountLabel
                text: displayName
                color: "#CCC"
                elide: Text.ElideRight
                maximumLineCount: 1
                Layout.fillWidth: true

                topPadding: -2
                bottomPadding: -2
                leftPadding: 5
                rightPadding: 5
            }
            TextField {
                id: statusEdit
                placeholderText: qsTr("Set status message")
                background: Rectangle { color: "#333" }
                color: "#CCC"
                selectByMouse: true
                font.family: "Roboto"
                font.pixelSize: 12
                Layout.fillWidth: true

                topPadding: 0
                bottomPadding: 0
                leftPadding: 5
                rightPadding: 5
            }
        }
    }
}
