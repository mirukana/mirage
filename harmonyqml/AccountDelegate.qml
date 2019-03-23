import QtQuick 2.7
import QtQuick.Controls 2.0
import QtQuick.Layouts 1.4

Column {
    readonly property string displayName:
        Backend.getUser(section).display_name

    width: roomListView.width
    height: paddingItem.height + row.height

    Item { id: paddingItem; width: 1; height: row.height / 2 }

    Row {
        id: row
        width: parent.width
        height: avatar.height

        Avatar { id: avatar; username: displayName }

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
                    horizontalAlignment: Qt.AlignHCenter
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
}
