import QtQuick 2.7
import QtQuick.Controls 2.0
import QtQuick.Layouts 1.4
import "../../Base"

Row {
    id: row
    spacing: standardSpacing
    layoutDirection: isOwn ? Qt.RightToLeft : Qt.LeftToRight

    HAvatar { id: avatar; hidden: combine; name: displayName }

    HColumnLayout {
        spacing: 0

        HLabel {
            visible: ! combine
            id: nameLabel
            text: displayName.value || dict.sender
            background: Rectangle {color: HStyle.chat.message.background}
            color: Qt.hsla(Backend.hueFromString(text),
                           HStyle.displayName.saturation,
                           HStyle.displayName.lightness,
                           1)
            elide: Text.ElideRight
            maximumLineCount: 1
            Layout.preferredWidth: contentLabel.width
            horizontalAlignment: isOwn ? Text.AlignRight : Text.AlignLeft

            leftPadding: horizontalPadding
            rightPadding: horizontalPadding
            topPadding: verticalPadding
        }

        HRichLabel {
            id: contentLabel
            text: (dict.formatted_body ?
                   Backend.htmlFilter.filter(dict.formatted_body) :
                   dict.body) +
                  "&nbsp;&nbsp;<font size=" + HStyle.fontSize.small +
                  "px color=" + HStyle.chat.message.date + ">" +
                  Qt.formatDateTime(dateTime, "hh:mm:ss") +
                  "</font>" +
                  (isLocalEcho ?
                   "&nbsp;<font size=" + HStyle.fontSize.small +
                   "px>⏳</font>" : "")
            textFormat: Text.RichText
            background: Rectangle {color: HStyle.chat.message.background}
            color: HStyle.chat.message.body
            wrapMode: Text.Wrap

            leftPadding: horizontalPadding
            rightPadding: horizontalPadding
            topPadding: nameLabel.visible ? 0 : verticalPadding
            bottomPadding: verticalPadding

            Layout.minimumWidth: nameLabel.implicitWidth
            Layout.maximumWidth: Math.min(
                600, roomEventListView.width - avatar.width - row.totalSpacing
            )
        }
    }
}
