import QtQuick 2.7
import QtQuick.Controls 2.0
import QtQuick.Layouts 1.4
import "../../Base" as Base

Row {
    id: row
    spacing: standardSpacing
    layoutDirection: isOwn ? Qt.RightToLeft : Qt.LeftToRight

    Base.HAvatar { id: avatar; hidden: combine; name: displayName }

    Base.HColumnLayout {
        spacing: 0

        Base.HLabel {
            visible: ! combine
            id: nameLabel
            text: displayName.value || dict.sender
            background: Rectangle {color: Base.HStyle.chat.message.background}
            color: Qt.hsla(Backend.hueFromString(text),
                           Base.HStyle.displayName.saturation,
                           Base.HStyle.displayName.lightness,
                           1)
            elide: Text.ElideRight
            maximumLineCount: 1
            Layout.preferredWidth: contentLabel.width
            horizontalAlignment: isOwn ? Text.AlignRight : Text.AlignLeft

            leftPadding: horizontalPadding
            rightPadding: horizontalPadding
            topPadding: verticalPadding
        }

        Base.HRichLabel {
            id: contentLabel
            text: (dict.formatted_body ?
                   Backend.htmlFilter.filter(dict.formatted_body) :
                   dict.body) +
                  "&nbsp;&nbsp;<font size=" + Base.HStyle.fontSize.small +
                  "px color=" + Base.HStyle.chat.message.date + ">" +
                  Qt.formatDateTime(dateTime, "hh:mm:ss") +
                  "</font>" +
                  (isLocalEcho ?
                   "&nbsp;<font size=" + Base.HStyle.fontSize.small +
                   "px>⏳</font>" : "")
            textFormat: Text.RichText
            background: Rectangle {color: Base.HStyle.chat.message.background}
            color: Base.HStyle.chat.message.body
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
