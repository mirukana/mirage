// Copyright Mirage authors & contributors <https://github.com/mirukana/mirage>
// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../../../Base"
import "../../.."

HRowLayout {
    id: eventContent

    readonly property var mentions: JSON.parse(model.mentions)

    readonly property string mentionsCSS: {
        const lines = []

        for (const [name, link] of mentions) {
            if (! link.match(/^https?:\/\/matrix.to\/#\/@.+/)) continue

            lines.push(
                `.mention[data-mention='${utils.escapeHtml(name)}'] ` +
                `{ color: ${utils.nameColor(name)} }`
            )
        }

        return "<style type='text/css'>" + lines.join("\n") + "</style>"
    }

    readonly property string senderText:
        asOneLine || onRight || combine ? "" : (
            `<${compact ? "span" : "div"} class='sender'>` +
            utils.coloredNameHtml(model.sender_name, model.sender_id) +
            (compact ? ": " : "") +
            (compact ? "</span>" : "</div>")
        )
    property string contentText: utils.processedEventText(model)
    readonly property string timeText: utils.formatTime(model.date, false)

    readonly property string stateText:
        `<font size=${theme.fontSize.small}px><font ` + (
            model.is_local_echo ?
            `color="${theme.chat.message.localEcho}">&nbsp;⧗` :  // U+29D7

            model.read_by_count ?
            `color="${theme.chat.message.readCounter}">&nbsp;⦿&nbsp;` +
            model.read_by_count :  // U+29BF

            ">"
        ) + "</font></font>"

    readonly property bool pureMedia: ! contentText && linksRepeater.count

    readonly property bool hoveredSelectable: contentHover.hovered
    readonly property string hoveredLink:
        linksRepeater.lastHovered && linksRepeater.lastHovered.hovered ?
        linksRepeater.lastHovered.mediaUrl :
        contentLabel.hoveredLink

    readonly property alias contentLabel: contentLabel

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

    readonly property int maxMessageWidth:
        contentText.includes("<pre>") || contentText.includes("<table>") ?
        -1 :
        window.settings.maxMessageCharactersPerLine < 0 ?
        -1 :
        Math.ceil(
            mainUI.fontMetrics.averageCharacterWidth *
            window.settings.maxMessageCharactersPerLine
        )

    readonly property alias selectedText: contentLabel.selectedPlainText


    spacing: theme.chat.message.horizontalSpacing
    layoutDirection: onRight ? Qt.RightToLeft: Qt.LeftToRight

    Item {
        id: avatarWrapper
        visible: ! onRight
        opacity: combine ? 0 : 1

        Layout.alignment: Qt.AlignTop

        Layout.preferredWidth:
            compact ?
            theme.chat.message.collapsedAvatarSize :
            theme.chat.message.avatarSize

        Layout.preferredHeight:
            combine ?
            1 :

            compact || (
                asOneLine &&
                nextModel &&
                eventList.canCombine(model, nextModel)
            ) ?
            theme.chat.message.collapsedAvatarSize :

            theme.chat.message.avatarSize

        HUserAvatar {
            id: avatar
            clientUserId: chat.userId
            userId: model.sender_id
            displayName: model.sender_name
            mxc: model.sender_avatar
            width: parent.width
            height: combine ? 1 : parent.Layout.preferredWidth
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
                    compact && contentText.match(/^\s*<(p|h[1-6])>/) ?
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

                stateText

            transform: Translate { x: xOffset }

            Layout.maximumWidth: eventContent.maxMessageWidth
            Layout.fillWidth: true

            onSelectedTextChanged: if (selectedPlainText) {
                eventList.delegateWithSelectedText = model.id
                eventList.selectedText             = selectedPlainText
            } else if (eventList.delegateWithSelectedText === model.id) {
                eventList.delegateWithSelectedText = ""
                eventList.selectedText             = ""
            }

            Connections {
                target: eventList
                onCheckedChanged: contentLabel.deselect()
                onDelegateWithSelectedTextChanged: {
                    if (eventList.delegateWithSelectedText !== model.id)
                        contentLabel.deselect()
                }
            }

            HoverHandler { id: contentHover }

            PointHandler {
                id: mousePointHandler

                property bool checkedNow: false

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
                       ! contentLabel.selectedPlainText &&
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

            property EventMediaLoader lastHovered: null

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
                showLocalEcho: pureMedia && (
                    singleMediaInfo.is_local_echo ||
                    singleMediaInfo.read_by_count
                ) ? stateText : ""

                transform: Translate { x: xOffset }

                onHoveredChanged: if (hovered) linksRepeater.lastHovered = this

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
