import QtQuick 2.7
import QtQuick.Controls 2.0
import QtQuick.Layouts 1.4
import "../base" as Base
import "utils.js" as ChatJS

RowLayout {
    id: row
    spacing: standardSpacing / 2
    layoutDirection: isOwn ? Qt.RightToLeft : Qt.LeftToRight
    anchors.right: isOwn ? parent.right : undefined

    readonly property string contentText:
        isMessage ?  "" : ChatJS.getEventText(type, dict)

    Base.Avatar {
        id: avatar
        name: displayName
        invisible: combine
        dimmension: 28
    }

    Base.HLabel {
        id: contentLabel
        text: "<font color='" +
              (isUndecryptableEvent ? "darkred" : "gray") + "'>" +
              (displayName.value || dict.sender) +
              (contentText.startsWith("'s ") ? "" : " ") +
              contentText +
              "&nbsp;&nbsp;<font size=" + smallSize + "px color='gray'>" +
              Qt.formatDateTime(dateTime, "hh:mm:ss") +
              "</font></font>"
        textFormat: Text.RichText
        background: Rectangle {color: "#DDD"}
        wrapMode: Text.Wrap

        leftPadding: horizontalPadding
        rightPadding: horizontalPadding
        topPadding: verticalPadding
        bottomPadding: verticalPadding

        Layout.maximumWidth: Math.min(
            600, messageListView.width - avatar.width - row.spacing
        )
    }
}
