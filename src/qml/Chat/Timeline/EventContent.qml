import QtQuick 2.7
import QtQuick.Layouts 1.3
import "../../Base"

Row {
    id: messageContent
    spacing: standardSpacing / 2
    layoutDirection: isOwn ? Qt.RightToLeft : Qt.LeftToRight

    function textHueForName(name) { // TODO: move
        return Qt.hsla(avatar.hueFromName(name),
                       HStyle.displayName.saturation,
                       HStyle.displayName.lightness,
                       1)
    }

    HAvatar {
        id: avatar
        hidden: combine
        name: senderInfo.displayName || stripUserId(model.senderId)
        dimension: model.showNameLine ? 48 : 28
    }

    Rectangle {
        color: HStyle.chat.message.background

        //width: nameLabel.implicitWidth
        width: Math.min(
            roomEventListView.width - avatar.width - messageContent.spacing,
            HStyle.fontSize.normal * 0.5 * 75,  // 600 with 16px font
            Math.max(
                nameLabel.visible ? nameLabel.implicitWidth : 0,
                contentLabel.implicitWidth
            )
        )
        height: nameLabel.height + contentLabel.implicitHeight

        Column {
            spacing: 0
            anchors.fill: parent

            HLabel {
                width: parent.width
                height: model.showNameLine && ! combine ? implicitHeight : 0
                visible: height > 0

                id: nameLabel
                text: senderInfo.displayName || model.senderId
                color: textHueForName(avatar.name)
                elide: Text.ElideRight
                maximumLineCount: 1
                horizontalAlignment: isOwn ? Text.AlignRight : Text.AlignLeft

                leftPadding: horizontalPadding
                rightPadding: horizontalPadding
                topPadding: verticalPadding
            }

            HRichLabel {
                function escapeHtml(text) {  // TODO: move this
                    return text.replace("&", "&amp;")
                               .replace("<", "&lt;")
                               .replace(">", "&gt;")
                               .replace('"', "&quot;")
                               .replace("'", "&#039;")
                }

                function translate(text) {
                    if (model.translatable == false) { return text }

                    text = text.replace(
                        "%S",
                        "<font color='" + nameLabel.color + "'>" +
                        escapeHtml(senderInfo.displayName || model.senderId) +
                        "</font>"
                    )

                    var name = models.users.getUser(
                        chatPage.userId, model.targetUserId
                    ).displayName
                    var sid = avatar.stripUserId(model.targetUserId || "")

                    text = text.replace(
                        "%T",
                        "<font color='" + textHueForName(name || sid) + "'>" +
                        escapeHtml(name || model.targetUserId) +
                        "</font>"
                    )

                    text = qsTr(text)
                    if (model.translatable == true) { return text }

                    // Else, model.translatable should be an array of args
                    for (var i = 0; model.translatable.length; i++) {
                        text = text.arg(model.translatable[i])
                    }
                }

                width: parent.width

                id: contentLabel
                text: translate(model.content) +
                      "&nbsp;&nbsp;<font size=" + HStyle.fontSize.small +
                      "px color=" + HStyle.chat.message.date + ">" +
                      Qt.formatDateTime(model.date, "hh:mm:ss") +
                      "</font>" +
                      (model.isLocalEcho ?
                       "&nbsp;<font size=" + HStyle.fontSize.small +
                       "px>⏳</font>" : "")
                color: HStyle.chat.message.body
                wrapMode: Text.Wrap

                leftPadding: horizontalPadding
                rightPadding: horizontalPadding
                topPadding: nameLabel.visible ? 0 : verticalPadding
                bottomPadding: verticalPadding
            }
        }
    }
}
