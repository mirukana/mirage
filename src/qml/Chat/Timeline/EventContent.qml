import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../../Base"
import "../../utils.js" as Utils

Row {
    id: eventContent
    spacing: theme.spacing / 1.25

    readonly property string eventText: Utils.processedEventText(model)
    readonly property string eventTime: Utils.formatTime(model.date, false)

    readonly property string hoveredLink:
        nameLabel.hoveredLink || contentLabel.hoveredLink

    property string hoveredImage: ""

    readonly property int cursorShape:
        hoveredLink || hoveredImage               ? Qt.PointingHandCursor :
        nameHover.hovered || contentHover.hovered ? Qt.IBeamCursor :
        Qt.ArrowCursor


    // Needed because of eventList's MouseArea which steals the
    // HSelectableLabel's MouseArea hover events
    onCursorShapeChanged: eventList.cursorShape = cursorShape


    HoverHandler { id: hover }

    Item {
        width: hideAvatar ? 0 : 58
        height: hideAvatar ? 0 : collapseAvatar ? 1 : smallAvatar ? 28 : 58
        opacity: hideAvatar || collapseAvatar ? 0 : 1
        visible: width > 0

        HUserAvatar {
            id: avatar
            userId: model.sender_id
            displayName: model.sender_name
            avatarUrl: model.sender_avatar
            width: hideAvatar ? 0 : 58
            height: hideAvatar ? 0 : collapseAvatar ? 1 : 58
        }
    }

    Rectangle {
        color: isOwn?
               theme.chat.message.ownBackground :
               theme.chat.message.background

        //width: nameLabel.implicitWidth
        width: Math.min(
            eventList.width - avatar.width - eventContent.spacing,
            theme.fontSize.normal * 0.5 * 75,  // 600 with 16px font

            Math.max(
                nameLabel.visible ? (nameLabel.implicitWidth + 1) : 0,

                contentLabel.implicitWidth + 1,

                previewLinksRepeater.count > 0 ?
                theme.chat.message.thumbnailWidth : 0,
            )
        )
        height: childrenRect.height
        y: parent.height / 2 - height / 2

        Column {
            id: mainColumn
            width: parent.width
            spacing: theme.spacing / 1.75
            topPadding: theme.spacing / 1.75
            bottomPadding: topPadding

            HSelectableLabel {
                id: nameLabel
                width: parent.width
                visible: ! hideNameLine
                container: selectableLabelContainer
                selectable: ! unselectableNameLine
                leftPadding: eventContent.spacing
                rightPadding: leftPadding

                // This is +0.1 and content is +0 instead of the opposite,
                // because the eventList is reversed
                index: model.index + 0.1

                text: Utils.coloredNameHtml(model.sender_name, model.sender_id)
                textFormat: Text.RichText
                wrapMode: Text.Wrap
                // horizontalAlignment: onRight ? Text.AlignRight : Text.AlignLeft
                horizontalAlignment: Text.AlignLeft

                function selectAllText() {
                    // select the sender name, body and date
                    container.clearSelection()
                    nameLabel.selectAll()
                    contentLabel.selectAll()
                    contentLabel.updateContainerSelectedTexts()
                }

                HoverHandler { id: nameHover }
            }

            HSelectableLabel {
                id: contentLabel
                width: parent.width
                container: selectableLabelContainer
                index: model.index
                leftPadding: eventContent.spacing
                rightPadding: leftPadding
                bottomPadding: previewLinksRepeater.count > 0 ?
                               mainColumn.bottomPadding : 0

                text: theme.chat.message.styleInclude +
                      eventContent.eventText +
                      // time
                      // for some reason, if there's only one space,
                      // times will be on their own lines most of the time.
                      "  " +
                      "<font size=" + theme.fontSize.small +
                      "px color=" + theme.chat.message.date + '>' +
                      eventTime +
                      "</font>" +
                      // local echo icon
                      (model.is_local_echo ?
                       "&nbsp;<font size=" + theme.fontSize.small +
                       "px>⏳</font>" : "")

                color: theme.chat.message.body
                wrapMode: Text.Wrap
                textFormat: Text.RichText

                function selectAllText() {
                    // Select the message body without the date or name
                    container.clearSelection()
                    contentLabel.select(
                        0,
                        contentLabel.length -
                        eventTime.length - 1  // - 1: separating space
                    )
                    contentLabel.updateContainerSelectedTexts()
                }

                HoverHandler { id: contentHover }
            }

            Repeater {
                id: previewLinksRepeater
                model: previewLinks

                HLoader {
                    Component.onCompleted: {
                        if (modelData[0] == "image") {
                            setSource(
                                "EventImage.qml",
                                { source: modelData[1] },
                            )
                        }
                    }
                }
            }
        }
    }
}
