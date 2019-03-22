import QtQuick 2.7
import QtQuick.Controls 2.0
import QtQuick.Layouts 1.4

Rectangle {
    readonly property string displayName:
        Backend.getUser(section).display_name

    color: "#111"
    width: roomListView.width
    height: childrenRect.height

    RowLayout {
        id: row
        spacing: 1
        width: parent.width

        Avatar { id: avatar; username: displayName }

        ColumnLayout {
            spacing: 1

            PlainLabel {
                id: accountLabel
                text: displayName
                color: "#CCC"
                elide: Text.ElideRight
                maximumLineCount: 1
                Layout.fillWidth: true
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
            }
        }
    }
}
