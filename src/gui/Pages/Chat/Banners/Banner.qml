// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../../../Base"

Rectangle {
    id: banner

    property alias avatar: bannerAvatar
    property alias icon: bannerIcon
    property alias labelText: bannerLabel.text
    property alias buttonModel: bannerRepeater.model
    property var buttonCallbacks: []


    implicitHeight: childrenRect.height
    color: theme.controls.box.background

    HGridLayout {
        id: bannerGrid
        width: parent.width
        flow: bannerAvatarWrapper.width +
              bannerIcon.width +
              bannerLabel.implicitWidth +
              bannerButtons.width >
              parent.width ?
              GridLayout.TopToBottom : GridLayout.LeftToRight

        HRowLayout {
            id: bannerRow

            Rectangle {
                id: bannerAvatarWrapper
                color: "black"

                Layout.preferredWidth: bannerAvatar.width
                Layout.minimumHeight: bannerAvatar.height
                Layout.preferredHeight: bannerLabel.height

                HUserAvatar {
                    id: bannerAvatar
                    anchors.centerIn: parent
                    radius: 0
                }
            }

            HIcon {
                id: bannerIcon
                visible: Boolean(svgName)

                Layout.leftMargin: theme.spacing / 2
            }

            HLabel {
                id: bannerLabel
                textFormat: Text.StyledText
                wrapMode: HLabel.Wrap

                Layout.fillWidth: true
                Layout.leftMargin: bannerIcon.Layout.leftMargin
                Layout.rightMargin: Layout.leftMargin
            }

            HSpacer {}
        }

        HRowLayout {
            HRowLayout {
                id: bannerButtons

                Repeater {
                    id: bannerRepeater
                    model: []

                    HButton {
                        id: button
                        text: modelData.text
                        icon.name: modelData.iconName
                        icon.color: modelData.iconColor || theme.icons.colorize
                        onClicked: buttonCallbacks[modelData.name](button)

                        Layout.preferredHeight: theme.baseElementsHeight
                    }
                }
            }

            Rectangle {
                id: buttonsRightPadding
                color: theme.controls.button.background
                visible: bannerGrid.flow === GridLayout.TopToBottom

                Layout.fillWidth: true
                Layout.fillHeight: true
            }
        }
    }
}
