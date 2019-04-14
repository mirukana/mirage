import QtQuick 2.7
import QtQuick.Controls 2.0
import QtQuick.Layouts 1.4
import "../base" as Base
import "utils.js" as SidePaneJS

MouseArea {
    id: "root"
    width: roomList.width
    height: roomList.childrenHeight

    onClicked: pageStack.show_room(
        roomList.for_user_id,
        roomList.model.get(index)
    )

    RowLayout {
        anchors.fill: parent
        id: row
        spacing: 1

        Base.Avatar { id: avatar; name: display_name; dimmension: root.height }

        ColumnLayout {
            spacing: 0

            Base.HLabel {
                id: roomLabel
                text: display_name ? display_name : "<i>Empty room</i>"
                textFormat: Text.StyledText
                elide: Text.ElideRight
                maximumLineCount: 1
                Layout.maximumWidth: row.width - row.spacing - avatar.width
                verticalAlignment: Qt.AlignVCenter

                topPadding: -2
                bottomPadding: subtitleLabel.visible ? 0 : topPadding
                leftPadding: 5
                rightPadding: leftPadding
            }
            Base.HLabel {
                function get_text() {
                    return SidePaneJS.get_last_room_event_text(room_id)
                }

                Connections {
                    target: Backend.models.roomEvents.get(room_id)
                    onChanged: subtitleLabel.text = subtitleLabel.get_text()
                }

                id: subtitleLabel
                visible: text !== ""
                text: get_text()
                textFormat: Text.StyledText

                font.pixelSize: smallSize
                elide: Text.ElideRight
                maximumLineCount: 1
                Layout.maximumWidth: roomLabel.Layout.maximumWidth

                topPadding: -2
                bottomPadding: topPadding
                leftPadding: 5
                rightPadding: leftPadding
            }
        }

        Item { Layout.fillWidth: true }
    }
}
