import QtQuick 2.7
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.4
import "../base" as Base

Rectangle {
    id: inviteOffer
    Layout.fillWidth: true
    Layout.preferredHeight: 32
    color: "#BBB"

    Base.HRowLayout {
        id: inviteRow
        anchors.fill: parent

        Base.Avatar {
            id: inviteAvatar
            name: ""
            dimmension: inviteOffer.Layout.preferredHeight
        }

        Base.HLabel {
            id: inviteLabel
            text: "<b>" + "Person" + "</b> " +
                  qsTr("invited you to join the room.")
            textFormat: Text.StyledText
            maximumLineCount: 1
            elide: Text.ElideRight

            visible:
                inviteRow.width - inviteAvatar.width - inviteButtons.width > 30

            Layout.maximumWidth:
                inviteRow.width -
                inviteAvatar.width - inviteButtons.width -
                Layout.leftMargin - Layout.rightMargin

            Layout.leftMargin: 10
            Layout.rightMargin: Layout.leftMargin
        }

        Item { Layout.fillWidth: true }

        Base.HRowLayout {
            id: inviteButtons
            spacing: 0

            property bool compact:
                inviteRow.width <
                inviteAvatar.width + inviteLabel.implicitWidth +
                acceptButton.implicitWidth + declineButton.implicitWidth

             property int displayMode:
                 compact ? Button.IconOnly : Button.TextBesideIcon

            Base.HButton {
                id: acceptButton
                text: qsTr("Accept")
                iconName: "accept"
                icon.color: Qt.hsla(0.45, 0.9, 0.3, 1)
                display: inviteButtons.displayMode

                Layout.maximumWidth: inviteButtons.compact ? height : -1
                Layout.fillHeight: true
            }

            Base.HButton {
                id: declineButton
                text: qsTr("Decline")
                iconName: "decline"
                icon.color: Qt.hsla(0.95, 0.9, 0.35, 1)
                icon.width: 32
                display: inviteButtons.displayMode

                Layout.maximumWidth: inviteButtons.compact ? height : -1
                Layout.fillHeight: true
            }
        }
    }
}
