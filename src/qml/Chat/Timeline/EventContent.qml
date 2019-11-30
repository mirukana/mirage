import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../../Base"
import "../../utils.js" as Utils

HRowLayout {
    id: eventContent
    spacing: theme.spacing / 1.25
    layoutDirection: onRight ? Qt.RightToLeft: Qt.LeftToRight


    readonly property string senderText:
        hideNameLine ? "" : (
            "<div class='sender'>" +
            Utils.coloredNameHtml(model.sender_name, model.sender_id) +
            "</div>"
        )
    readonly property string contentText: Utils.processedEventText(model)
    readonly property string timeText: Utils.formatTime(model.date, false)
    readonly property string localEchoText:
        model.is_local_echo ?
        `&nbsp;<font size=${theme.fontSize.small}px>⏳</font>` :
        ""

    readonly property bool pureMedia: ! contentText && linksRepeater.count

    readonly property string hoveredLink: contentLabel.hoveredLink
    readonly property bool hoveredSelectable: contentHover.hovered

    readonly property int messageBodyWidth:
        width - (avatarWrapper.visible ? avatarWrapper.width : 0) -
        totalSpacing

    readonly property int xOffset:
        onRight ?
        contentLabel.width - contentLabel.paintedWidth -
        contentLabel.leftPadding - contentLabel.rightPadding :
        0


    TapHandler {
        enabled: debugMode
        onDoubleTapped:
            Utils.debug(eventContent, con => { con.runJS("json()") })
    }

    Item {
        id: avatarWrapper
        opacity: collapseAvatar ? 0 : 1
        visible: ! hideAvatar

        Layout.minimumWidth: 58
        Layout.minimumHeight: collapseAvatar ? 1 : smallAvatar ? 28 : 58
        Layout.maximumWidth: Layout.minimumWidth
        Layout.maximumHeight: Layout.minimumHeight
        Layout.alignment: Qt.AlignTop

        HUserAvatar {
            id: avatar
            userId: model.sender_id
            displayName: model.sender_name
            mxc: model.sender_avatar
            width: parent.width
            height: collapseAvatar ? 1 : 58
        }
    }

    HColumnLayout {
        id: contentColumn
        Layout.alignment: Qt.AlignVCenter

        HSelectableLabel {
            id: contentLabel
            container: selectableLabelContainer
            index: model.index
            visible: ! pureMedia

            topPadding: theme.spacing / 1.75
            bottomPadding: topPadding
            leftPadding: eventContent.spacing
            rightPadding: leftPadding

            color: model.event_type === "RoomMessageNotice" ?
                   theme.chat.message.noticeBody :
                   theme.chat.message.body

            font.italic: model.event_type === "RoomMessageEmote"
            wrapMode: TextEdit.Wrap
            textFormat: Text.RichText
            text:
                // CSS
                theme.chat.message.styleInclude +

                // Sender name
                eventContent.senderText +

                // Message body
                eventContent.contentText +

                // Time
                // For some reason, if there's only one space,
                // times will be on their own lines most of the time.
                "  " +
                `<font size=${theme.fontSize.small}px ` +
                      `color=${theme.chat.message.date}>` +
                timeText +
                "</font>" +

                // Local echo icon
                (model.is_local_echo ?
                 `&nbsp;<font size=${theme.fontSize.small}px>⏳</font>` : "")

            transform: Translate { x: xOffset }

            Layout.maximumWidth: Math.min(
                // 600px with 16px font
                theme.fontSize.normal * 0.5 * 75,
                messageBodyWidth - leftPadding - rightPadding,
            )

            function selectAllText() {
                // Select the message body without the date or name
                container.clearSelection()
                contentLabel.select(
                    0,
                    contentLabel.length -
                    timeText.length - 1  // - 1: separating space
                )
                contentLabel.updateContainerSelectedTexts()
            }

            HoverHandler { id: contentHover }

            Rectangle {
                width: Math.max(
                    parent.paintedWidth +
                    parent.leftPadding + parent.rightPadding,

                    linksRepeater.childrenWidth +
                    (pureMedia ? 0 : parent.leftPadding + parent.rightPadding),
                )
                height: contentColumn.height
                z: -1
                color: isOwn?
                       theme.chat.message.ownBackground :
                       theme.chat.message.background

                Rectangle {
                    visible: model.event_type === "RoomMessageNotice"
                    width: theme.chat.message.noticeLineWidth
                    height: parent.height
                    color: Utils.nameColor(
                        model.sender_name || model.sender_id.substring(1),
                    )
                }
            }
        }

        HRepeater {
            id: linksRepeater
            model: eventDelegate.currentItem.links

            EventMediaLoader {
                singleMediaInfo: eventDelegate.currentItem
                mediaUrl: modelData
                showSender: pureMedia ? senderText : ""
                showDate: pureMedia ? timeText : ""
                showLocalEcho: pureMedia ? localEchoText : ""

                transform: Translate { x: xOffset }

                Layout.bottomMargin: pureMedia ? 0 : contentLabel.bottomPadding
                Layout.leftMargin: pureMedia ? 0 : contentLabel.leftPadding
                Layout.rightMargin: pureMedia ? 0 : contentLabel.rightPadding

                Layout.preferredWidth: item ? item.width : -1
                Layout.preferredHeight: item ? item.height : -1
            }
        }
    }

    HSpacer {}
}
