import QtQuick 2.7
import QtQuick.Layouts 1.3
import "../../Base"
import "../utils.js" as ChatJS

Row {
    id: eventContent
    spacing: standardSpacing / 2
    layoutDirection: isOwn ? Qt.RightToLeft : Qt.LeftToRight

    width: Math.min(
        roomEventListView.width - avatar.width - eventContent.spacing,
        HStyle.fontSize.normal * 0.5 * 75,  // 600 with 16px font
        contentLabel.implicitWidth
    )

    HAvatar {
        id: avatar
        name: sender.displayName || stripUserId(sender.userId)
        hidden: combine
        dimension: 28
    }

    HLabel {
        width: parent.width

        id: contentLabel
        text: "<font color='" +
              Qt.hsla(Backend.hueFromString(sender.displayName.value),
                      HStyle.chat.event.saturation,
                      HStyle.chat.event.lightness,
                      1) +
              "'>" +
              sender.displayName.value + " " +
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
    }
}
