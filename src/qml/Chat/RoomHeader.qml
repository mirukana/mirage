import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../Base"

HRectangle {
    property alias buttonsImplicitWidth: viewButtons.implicitWidth
    property int buttonsWidth: viewButtons.Layout.preferredWidth
    property var activeButton: "members"

    property bool collapseButtons:
        viewButtons.implicitWidth > width * 0.33 ||
        width - viewButtons.implicitWidth <
        theme.minimumSupportedWidthPlusSpacing

    id: roomHeader
    color: theme.chat.roomHeader.background
    implicitHeight: theme.baseElementsHeight

    HRowLayout {
        id: row
        spacing: theme.spacing
        anchors.fill: parent

        HRoomAvatar {
            id: avatar
            displayName: chatPage.roomInfo.display_name
            avatarUrl: chatPage.roomInfo.avatar_url
            Layout.alignment: Qt.AlignTop
        }

        HLabel {
            id: roomName
            text: chatPage.roomInfo.display_name
            font.pixelSize: theme.fontSize.big
            color: theme.chat.roomHeader.name
            elide: Text.ElideRight
            verticalAlignment: Text.AlignVCenter

            Layout.fillHeight: true
            Layout.maximumWidth: Math.max(
                0,
                row.width - row.totalSpacing - avatar.width -
                viewButtons.width -
                (expandButton.visible ? expandButton.width : 0)
            )
        }

        HLabel {
            id: roomTopic
            text: chatPage.roomInfo.topic
            font.pixelSize: theme.fontSize.small
            color: theme.chat.roomHeader.topic
            elide: Text.ElideRight
            verticalAlignment: Text.AlignVCenter

            Layout.fillHeight: true
            Layout.maximumWidth: Math.max(
                0,
                row.width - row.totalSpacing - avatar.width -
                roomName.width - viewButtons.width -
                (expandButton.visible ? expandButton.width : 0)
            )
        }

        HSpacer {}

        Row {
            id: viewButtons
            Layout.preferredWidth: collapseButtons ? 0 : implicitWidth
            Layout.fillHeight: true

            Repeater {
                model: [
                    "members", "files", "notifications", "history", "settings"
                ]
                HButton {
                    backgroundColor: "transparent"
                    icon.name: "room-view-" + modelData
                    iconItem.dimension: 22
                    height: parent.height
                    autoExclusive: true
                    checked: activeButton == modelData
                    enabled: modelData == "members"
                    toolTip.text: qsTr(
                        modelData.charAt(0).toUpperCase() + modelData.slice(1)
                    )
                    onClicked: activeButton =
                        activeButton == modelData ?  null : modelData
                }
            }

            Behavior on Layout.preferredWidth {
                HNumberAnimation { id: buttonsAnimation }
            }
        }
    }

    HButton {
        id: expandButton
        z: 1
        width: height
        height: parent.height
        anchors.right: parent.right
        opacity: collapseButtons ? 1 : 0
        visible: opacity > 0

        backgroundColor: "transparent"
        icon.name: "reduced-room-buttons"

        Behavior on opacity {
            HNumberAnimation { duration: buttonsAnimation.duration * 2 }
        }
    }
}
