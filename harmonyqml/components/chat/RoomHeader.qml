import QtQuick 2.7
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.4
import "../base" as Base

Rectangle {
    property string displayName: ""
    property string topic: ""

    id: "root"
    Layout.fillWidth: true
    Layout.minimumHeight: 36
    Layout.maximumHeight: Layout.minimumHeight
    color: "#BBB"

    RowLayout {
        id: "row"
        spacing: 12
        anchors.fill: parent

        Base.Avatar {
            id: "avatar"
            Layout.alignment: Qt.AlignTop
            dimmension: root.Layout.minimumHeight
            name: displayName
        }

        Base.HLabel {
            id: "roomName"
            text: displayName
            font.pixelSize: bigSize
            elide: Text.ElideRight
            maximumLineCount: 1
            Layout.maximumWidth:
                row.width - row.spacing * (row.children.length - 1) -
                avatar.width
        }

        Base.HLabel {
            id: "roomTopic"
            text: topic
            font.pixelSize: smallSize
            elide: Text.ElideRight
            maximumLineCount: 1
            Layout.maximumWidth:
                row.width -
                row.spacing * (row.children.length - 1) -
                avatar.width -
                roomName.width
        }

        Item { Layout.fillWidth: true }
    }
}
