import QtQuick 2.7
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.4
import "../base" as Base

Rectangle {
    id: banner
    Layout.fillWidth: true
    Layout.preferredHeight: 32
    color: "#BBB"

    property alias avatarName: bannerAvatar.name
    property alias avatarSource: bannerAvatar.imageSource
    property alias labelText: bannerLabel.text
    property alias buttonModel: bannerRepeater.model

    Base.HRowLayout {
        id: bannerRow
        anchors.fill: parent

        Base.Avatar {
            id: bannerAvatar
            dimmension: banner.Layout.preferredHeight
        }

        Base.HLabel {
            id: bannerLabel
            textFormat: Text.StyledText
            maximumLineCount: 1
            elide: Text.ElideRight

            visible:
                bannerRow.width - bannerAvatar.width - bannerButtons.width > 30

            Layout.maximumWidth:
                bannerRow.width -
                bannerAvatar.width - bannerButtons.width -
                Layout.leftMargin - Layout.rightMargin

            Layout.leftMargin: 10
            Layout.rightMargin: Layout.leftMargin
        }

        Item { Layout.fillWidth: true }

        Base.HRowLayout {
            id: bannerButtons
            spacing: 0

            function getButtonsWidth() {
                var total = 0

                for (var i = 0; i < bannerRepeater.count; i++) {
                    total += bannerRepeater.itemAt(i).implicitWidth
                }

                return total
            }

            property bool compact:
                bannerRow.width <
                bannerAvatar.width +
                bannerLabel.implicitWidth +
                bannerLabel.Layout.leftMargin +
                bannerLabel.Layout.rightMargin +
                getButtonsWidth()

             property int displayMode:
                 compact ? Button.IconOnly : Button.TextBesideIcon

            Repeater {
                id: bannerRepeater
                model: []

                Base.HButton {
                    id: declineButton
                    text: modelData.text
                    iconName: modelData.iconName
                    icon.color: modelData.iconColor
                    icon.width: 32
                    display: bannerButtons.displayMode

                    onClicked:
                        Backend.clientManager.clients[chatPage.userId].
                        call(modelData.clientFunction, modelData.clientArgs)

                    Layout.maximumWidth: bannerButtons.compact ? height : -1
                    Layout.fillHeight: true
                }
            }
        }
    }
}
