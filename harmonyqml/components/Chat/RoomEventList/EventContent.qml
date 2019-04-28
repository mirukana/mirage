import QtQuick 2.7
import QtQuick.Layouts 1.0
import "../../Base"
import "../utils.js" as ChatJS

HRowLayout {
    id: eventContent
    spacing: standardSpacing / 2
    layoutDirection: isOwn ? Qt.RightToLeft : Qt.LeftToRight

    HAvatar {
        id: avatar
        name: displayName
        hidden: combine
        dimension: 28
    }

    HLabel {
        id: contentLabel
        text: "<font color='" +
              Qt.hsla(Backend.hueFromString(displayName.value || dict.sender),
                      HStyle.chat.event.saturation,
                      HStyle.chat.event.lightness,
                      1) +
              "'>" +
              (displayName.value || dict.sender) + " " +
              ChatJS.getEventText(type, dict) +

              "&nbsp;&nbsp;" +
              "<font size=" + HStyle.fontSize.small + "px " +
              "color=" + HStyle.chat.event.date + ">" +
              Qt.formatDateTime(dateTime, "hh:mm:ss") +
              "</font> " +
              "</font>"

        textFormat: Text.RichText
        background: Rectangle {color: HStyle.chat.event.background}
        wrapMode: Text.Wrap

        leftPadding: horizontalPadding
        rightPadding: horizontalPadding
        topPadding: verticalPadding
        bottomPadding: verticalPadding

        Layout.maximumWidth: Math.min(
            600,
            roomEventListView.width - avatar.width - eventContent.totalSpacing
        )
    }
}
