import QtQuick 2.7
import QtQuick.Controls 2.0
import QtQuick.Layouts 1.4
import "../base" as Base

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

        Base.RichLabel {
            id: contentLabel
            //text: (isOwn ? "" : content + "&nbsp;&nbsp;") +
                  //"<font size=" + smallSize + "px color=gray>" +
                  //Qt.formatDateTime(date_time, "hh:mm:ss") +
                  //"</font>" +
            //      (isOwn ? "&nbsp;&nbsp;" + content : "")

            text: (dict.formatted_body ?
                   Backend.htmlFilter.filter(dict.formatted_body) :
                   dict.body) +
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
