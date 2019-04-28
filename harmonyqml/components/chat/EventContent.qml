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

    Base.HAvatar {
        id: avatar
        name: displayName
        invisible: combine
        dimmension: 28
    }

    Base.HLabel {
        id: contentLabel
        text: "<font color='" +
              Qt.hsla(Backend.hueFromString(displayName.value || dict.sender),
                      Base.HStyle.chat.event.saturation,
                      Base.HStyle.chat.event.lightness,
                      1) +
              "'>" +
              (displayName.value || dict.sender) + " " +
              contentText +

              "&nbsp;&nbsp;" +
              "<font size=" + Base.HStyle.fontSize.small + "px " +
              "color=" + Base.HStyle.chat.event.date + ">" +
              Qt.formatDateTime(dateTime, "hh:mm:ss") +
              "</font> " +
              "</font>"

        textFormat: Text.RichText
        background: Rectangle {color: Base.HStyle.chat.event.background}
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
