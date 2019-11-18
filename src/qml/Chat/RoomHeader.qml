import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../Base"

Rectangle {
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
            mxc: chatPage.roomInfo.avatar_url
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

            HoverHandler { id: nameHover }
        }

        HRichLabel {
            id: roomTopic
            text: chatPage.roomInfo.topic
            textFormat: Text.StyledText
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

            HoverHandler { id: topicHover }
        }

        HToolTip {
            text: name && topic ? (`${name}<br>${topic}`) : (name || topic)
            label.textFormat: Text.StyledText
            visible: text && (nameHover.hovered || topicHover.hovered)

            readonly property string name:
                roomName.truncated ?
                (`<b>${chatPage.roomInfo.display_name}</b>`) : ""
            readonly property string topic:
                roomTopic.truncated ?  chatPage.roomInfo.topic : ""
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
                    spacing: theme.spacing / 1.5
                    topPadding: 0
                    bottomPadding: topPadding
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
        spacing: theme.spacing / 1.5
        topPadding: 0
        bottomPadding: topPadding
        anchors.right: parent.right
        opacity: collapseButtons ? 1 : 0
        visible: opacity > 0
        enabled: false  // TODO

        backgroundColor: "transparent"
        icon.name: "reduced-room-buttons"

        Behavior on opacity {
            HNumberAnimation { duration: buttonsAnimation.duration * 2 }
        }
    }
}
