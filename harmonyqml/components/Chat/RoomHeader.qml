import QtQuick 2.7
import QtQuick.Layouts 1.0
import "../Base"

HGlassRectangle {
    property string displayName: ""
    property string topic: ""

    id: roomHeader
    color: HStyle.chat.roomHeader.background

    Layout.fillWidth: true
    Layout.preferredHeight: 32

    HRowLayout {
        id: row
        spacing: 8
        anchors.fill: parent

        HAvatar {
            id: avatar
            name: displayName
            dimension: roomHeader.height
            Layout.alignment: Qt.AlignTop
        }

        HLabel {
            id: roomName
            text: displayName
            font.pixelSize: HStyle.fontSize.big
            elide: Text.ElideRight
            maximumLineCount: 1
            Layout.maximumWidth: row.width - row.totalSpacing - avatar.width
        }

        HLabel {
            id: roomTopic
            text: topic
            font.pixelSize: HStyle.fontSize.small
            elide: Text.ElideRight
            maximumLineCount: 1
            Layout.maximumWidth:
                row.width - row.totalSpacing - avatar.width - roomName.width
        }

        HSpacer {}
    }
}
