import QtQuick 2.7
import QtQuick.Controls 2.0
import QtQuick.Layouts 1.4
import "../base" as Base

Column {
    id: rootCol

    function mins_between(date1, date2) {
        return Math.round((((date2 - date1) % 86400000) % 3600000) / 60000)
    }

    readonly property string displayName:
        Backend.getUser(chatPage.room.room_id, sender_id).display_name

    readonly property bool isOwn:
        chatPage.user.user_id === sender_id

    readonly property var previousData:
        index > 0 ? messageListView.model.get(index - 1) : null

    readonly property bool isFirstMessage: ! previousData

    readonly property bool combine:
        ! isFirstMessage &&
        previousData.sender_id == sender_id &&
        mins_between(previousData.date_time, date_time) <= 5

    readonly property bool dayBreak:
        isFirstMessage ||
        previousData.date_time.getDay() != date_time.getDay()

    readonly property bool talkBreak:
        ! isFirstMessage &&
        ! dayBreak &&
        mins_between(previousData.date_time, date_time) >= 20


    property int standardSpacing: 8
    property int horizontalPadding: 7
    property int verticalPadding: 5

    width: parent.width
    topPadding:
        previousData === null ? 0 :
        talkBreak ? standardSpacing * 6 :
        combine ? standardSpacing / 2 :
        standardSpacing * 1.2

    Daybreak { visible: dayBreak }


    Row {
        id: row
        spacing: standardSpacing
        layoutDirection: isOwn ? Qt.RightToLeft : Qt.LeftToRight
        anchors.right: isOwn ? parent.right : undefined

        Base.Avatar { id: avatar; invisible: combine; name: displayName }

        ColumnLayout {
            spacing: 0

            Base.HLabel {
                visible: ! combine
                id: nameLabel
                text: displayName
                background: Rectangle {color: "#DDD"}
                color: isOwn ? "teal" : "purple"
                elide: Text.ElideRight
                maximumLineCount: 1
                Layout.preferredWidth: contentLabel.width
                horizontalAlignment: isOwn ? Text.AlignRight : Text.AlignLeft

                leftPadding: horizontalPadding
                rightPadding: horizontalPadding
                topPadding: verticalPadding
            }

            Base.HLabel {
                id: contentLabel
                //text: (isOwn ? "" : content + "&nbsp;&nbsp;") +
                      //"<font size=" + smallSize + "px color=gray>" +
                      //Qt.formatDateTime(date_time, "hh:mm:ss") +
                      //"</font>" +
                //      (isOwn ? "&nbsp;&nbsp;" + content : "")

                text: content +
                      "&nbsp;&nbsp;<font size=" + smallSize + "px color=gray>" +
                      Qt.formatDateTime(date_time, "hh:mm:ss") +
                      "</font>"
                textFormat: Text.RichText
                background: Rectangle {color: "#DDD"}
                wrapMode: Text.Wrap

                leftPadding: horizontalPadding
                rightPadding: horizontalPadding
                bottomPadding: verticalPadding

                Layout.minimumWidth: nameLabel.implicitWidth
                Layout.maximumWidth: Math.min(
                    600, messageListView.width - avatar.width - row.spacing
                )
            }
        }
    }
}
