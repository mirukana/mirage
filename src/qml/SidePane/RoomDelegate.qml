import QtQuick 2.7
import QtQuick.Layouts 1.3
import "../Base"
import "../utils.js" as Utils

MouseArea {
    id: roomDelegate
    width: roomList.width
    height: childrenRect.height

    onClicked:
        pageStack.showRoom(roomList.userId, roomList.category, model.roomId)

    HRowLayout {
        width: parent.width
        spacing: sidePane.normalSpacing

        HAvatar {
            id: roomAvatar
            name: Utils.stripRoomName(model.displayName)
        }

        HColumnLayout {
            Layout.fillWidth: true
            Layout.maximumWidth:
                parent.width - parent.totalSpacing - roomAvatar.width

            HLabel {
                id: roomLabel
                text: model.displayName || "<i>Empty room</i>"
                textFormat: model.displayName? Text.PlainText : Text.StyledText
                elide: Text.ElideRight
                maximumLineCount: 1
                verticalAlignment: Qt.AlignVCenter

                Layout.maximumWidth: parent.width
            }

            HRichLabel {
                id: subtitleLabel
                visible: Boolean(text)
                text: {
                    for (var i = 0; i < models.timelines.count; i++) {
                        var item = models.timelines.get(i) // TODO: standardize

                        if (item.roomId == model.roomId) {
                            var ev = item
                            break
                        }
                    }

                    if (! ev) { return "" }

                    if (! Utils.eventIsMessage(ev)) {
                        return Utils.translatedEventContent(ev)
                    }

                    return Utils.coloredNameHtml(
                        models.users.getUser(ev.senderId).displayName,
                        ev.senderId
                    ) + ": " + py.callSync("inlinify", [ev.content])
                }
                textFormat: Text.StyledText

                font.pixelSize: HStyle.fontSize.small
                elide: Text.ElideRight
                maximumLineCount: 1

                Layout.maximumWidth: parent.width
            }
        }
    }
}
