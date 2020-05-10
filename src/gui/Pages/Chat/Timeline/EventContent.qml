// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../../../Base"
import "../../.."

HRowLayout {
    id: eventContent
    spacing: theme.chat.message.horizontalSpacing
    layoutDirection: onRight ? Qt.RightToLeft: Qt.LeftToRight


    readonly property var mentions: JSON.parse(model.mentions)

    readonly property string mentionsCSS: {
        const lines = []

        for (const [name, link] of mentions) {
            if (! link.match(/^https?:\/\/matrix.to\/#\/@.+/)) continue

            lines.push(
                `.mention[data-mention='${name}'] { color: ` +
                utils.nameColor(name) +
                "}"
            )
        }

        return "<style type='text/css'>" + lines.join("\n") + "</style>"
    }

    readonly property string senderText:
        hideNameLine ? "" : (
            `<${smallAvatar ? "span" : "div"} class='sender'>` +
            utils.coloredNameHtml(model.sender_name, model.sender_id) +
            (smallAvatar ? ": " : "") +
            (smallAvatar ? "</span>" : "</div>")
        )
    property string contentText: utils.processedEventText(model)
    readonly property string timeText: utils.formatTime(model.date, false)
    readonly property string localEchoText:
        model.is_local_echo ?
        `&nbsp;<font size=${theme.fontSize.small}px>⏳</font>` :
        ""

    readonly property bool pureMedia: ! contentText && linksRepeater.count

    readonly property string hoveredLink: contentLabel.hoveredLink
    readonly property bool hoveredSelectable: contentHover.hovered

    readonly property int xOffset:
        onRight ?
        Math.min(
            contentColumn.width - contentLabel.paintedWidth -
            contentLabel.leftPadding - contentLabel.rightPadding,

            contentColumn.width - linksRepeater.widestChild -
            (
                pureMedia ?
                0 : contentLabel.leftPadding + contentLabel.rightPadding
            ),
        ) :
        0

    // ~600px max with a 16px font
    readonly property int maxMessageWidth: theme.fontSize.normal * 0.5 * 75

    readonly property alias selectedText: contentLabel.selectedText


    Item {
        id: avatarWrapper
        opacity: collapseAvatar ? 0 : 1
        visible: ! hideAvatar

        Layout.minimumWidth:
            smallAvatar ?
            theme.chat.message.collapsedAvatarSize :
            theme.chat.message.avatarSize

        Layout.minimumHeight: collapseAvatar ? 1 : Layout.minimumWidth

        Layout.maximumWidth: Layout.minimumWidth
        Layout.maximumHeight: Layout.minimumHeight
        Layout.alignment: Qt.AlignTop

        HUserAvatar {
            id: avatar
            userId: model.sender_id
            displayName: model.sender_name
            mxc: model.sender_avatar
            width: parent.width
            height: collapseAvatar ? 1 : parent.Layout.minimumWidth
            radius: theme.chat.message.avatarRadius
        }
    }

    HColumnLayout {
        id: contentColumn

        Layout.fillWidth: true
        Layout.alignment: Qt.AlignVCenter

        HSelectableLabel {
            id: contentLabel
            visible: ! pureMedia
            enableLinkActivation: ! eventList.selectedCount

            selectByMouse:
                eventList.selectedCount <= 1 &&
                eventDelegate.checked &&
                textSelectionBlocker.point.scenePosition === Qt.point(0, 0)

            topPadding: theme.chat.message.verticalSpacing
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
                theme.chat.message.styleInclude + mentionsCSS +

                // Sender name & message body
                (
                    smallAvatar && contentText.match(/^\s*<(p|h[1-6])>/) ?
                    contentText.replace(
                        /(^\s*<(p|h[1-6])>)/, "$1" + senderText,
                    ) :
                    senderText + contentText
                ) +

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

            Layout.maximumWidth: eventContent.maxMessageWidth
            Layout.fillWidth: true

            onSelectedTextChanged: if (selectedText) {
                eventList.delegateWithSelectedText = model.id
                eventList.selectedText             = selectedText
            } else if (eventList.delegateWithSelectedText === model.id) {
                eventList.delegateWithSelectedText = ""
                eventList.selectedText             = ""
            }

            Connections {
                target: eventList
                onCheckedChanged: contentLabel.deselect()
                onDelegateWithSelectedTextChanged:
                    if (eventList.delegateWithSelectedText !== model.id)
                        contentLabel.deselect()
            }

            HoverHandler { id: contentHover }

            PointHandler {
                id: mousePointHandler
                acceptedButtons: Qt.LeftButton
                acceptedModifiers: Qt.NoModifier
                acceptedPointerTypes:
                    PointerDevice.GenericPointer | PointerDevice.Eraser

                onActiveChanged: {
                    if (active &&
                            ! eventDelegate.checked &&
                            (! parent.hoveredLink ||
                            ! parent.enableLinkActivation)) {

                        eventList.check(model.index)
                        checkedNow = true
                    }

                    if (! active && eventDelegate.checked) {
                        checkedNow ?
                        checkedNow = false :
                        eventList.uncheck(model.index)
                    }
                }

                property bool checkedNow: false
            }

            PointHandler {
                id: mouseShiftPointHandler
                acceptedButtons: Qt.LeftButton
                acceptedModifiers: Qt.ShiftModifier
                acceptedPointerTypes:
                    PointerDevice.GenericPointer | PointerDevice.Eraser

                onActiveChanged: {
                    if (active &&
                            ! eventDelegate.checked &&
                            (! parent.hoveredLink ||
                            ! parent.enableLinkActivation)) {

                        eventList.checkFromLastToHere(model.index)
                    }
                }
            }

            TapHandler {
                id: touchTapHandler
                acceptedButtons: Qt.LeftButton
                acceptedPointerTypes: PointerDevice.Finger | PointerDevice.Pen
                onTapped:
                    if (! parent.hoveredLink || ! parent.enableLinkActivation)
                        eventDelegate.toggleChecked()
            }

            TapHandler {
                id: textSelectionBlocker
                acceptedPointerTypes: PointerDevice.Finger | PointerDevice.Pen
            }

            Rectangle {
                id: contentBackground
                width: Math.max(
                    parent.paintedWidth +
                    parent.leftPadding + parent.rightPadding,

                    linksRepeater.summedWidth +
                    (pureMedia ? 0 : parent.leftPadding + parent.rightPadding),
                )
                height: contentColumn.height
                radius: theme.chat.message.radius
                z: -100
                color: eventDelegate.checked &&
                       ! contentLabel.selectedText &&
                       ! mousePointHandler.active &&
                       ! mouseShiftPointHandler.active ?
                       theme.chat.message.checkedBackground :

                       isOwn?
                       theme.chat.message.ownBackground :

                       theme.chat.message.background

                Behavior on color { HColorAnimation {} }

                Rectangle {
                    visible: model.event_type === "RoomMessageNotice"
                    // y: parent.height / 2 - height / 2
                    width: theme.chat.message.noticeLineWidth
                    height: parent.height
                    radius: parent.radius
                    color: utils.nameColor(
                        model.sender_name || model.sender_id.substring(1),
                    )
                }
            }
        }

        HRepeater {
            id: linksRepeater
            model: {
                const links = JSON.parse(eventDelegate.currentModel.links)

                if (eventDelegate.currentModel.media_url)
                    links.push(eventDelegate.currentModel.media_url)

                return links
            }

            EventMediaLoader {
                singleMediaInfo: eventDelegate.currentModel
                mediaUrl: modelData
                showSender: pureMedia ? senderText : ""
                showDate: pureMedia ? timeText : ""
                showLocalEcho: pureMedia ? localEchoText : ""

                transform: Translate { x: xOffset }

                Layout.bottomMargin: pureMedia ? 0 : contentLabel.bottomPadding
                Layout.leftMargin: pureMedia ? 0 : eventContent.spacing
                Layout.rightMargin: pureMedia ? 0 : eventContent.spacing
                Layout.preferredWidth: item ? item.width : -1
                Layout.preferredHeight: item ? item.height : -1
            }
        }
    }

    HSpacer {}
}
