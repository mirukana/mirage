import QtQuick 2.7
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.4
import "../base" as Base
import "utils.js" as ChatJS

Banner {
    property var leftEvent: null

    avatarName: ChatJS.getLeftBannerAvatarName(leftEvent, chatPage.userId)
    labelText: ChatJS.getLeftBannerText(leftEvent)

    buttonModel: [
        {
            text: "Rejoin",
            iconName: "join",
            iconColor: Qt.hsla(0.13, 0.9, 0.35, 1),
        },
        {
            text: "Forget",
            iconName: "trash_can",
            iconColor: Qt.hsla(0.95, 0.9, 0.35, 1),
        }
    ]
}
