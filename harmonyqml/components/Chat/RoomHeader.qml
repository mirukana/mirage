import QtQuick 2.7
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.4
import "../Base" as Base

Base.HGlassRectangle {
    property string displayName: ""
    property string topic: ""

    id: roomHeader
    color: Base.HStyle.chat.roomHeader.background

    Layout.fillWidth: true
    Layout.preferredHeight: 32

    Base.HRowLayout {
        id: row
        spacing: 8
        anchors.fill: parent

        Base.HAvatar {
            id: avatar
            name: displayName
            dimension: roomHeader.height
            Layout.alignment: Qt.AlignTop
        }

        Base.HLabel {
            id: roomName
            text: displayName
            font.pixelSize: Base.HStyle.fontSize.big
            elide: Text.ElideRight
            maximumLineCount: 1
            Layout.maximumWidth: row.width - row.totalSpacing - avatar.width
        }

        Base.HLabel {
            id: roomTopic
            text: topic
            font.pixelSize: Base.HStyle.fontSize.small
            elide: Text.ElideRight
            maximumLineCount: 1
            Layout.maximumWidth:
                row.width - row.totalSpacing - avatar.width - roomName.width
        }

        Item { Layout.fillWidth: true }
    }
}
