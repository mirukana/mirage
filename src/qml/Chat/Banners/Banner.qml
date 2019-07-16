// Copyright 2019 miruka
// This file is part of harmonyqml, licensed under LGPLv3.

import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../../Base"

HRectangle {
    id: banner
    Layout.fillWidth: true
    Layout.preferredHeight: theme.baseElementsHeight

    property alias avatar: bannerAvatar
    property alias icon: bannerIcon
    property alias labelText: bannerLabel.text
    property alias buttonModel: bannerRepeater.model
    property var buttonCallbacks: []

    HRowLayout {
        id: bannerRow
        anchors.fill: parent

        HUserAvatar {
            id: bannerAvatar
        }

        HIcon {
            id: bannerIcon
            dimension: bannerLabel.implicitHeight
            visible: Boolean(svgName)

            Layout.leftMargin: theme.spacing / 2
        }

        HLabel {
            id: bannerLabel
            textFormat: Text.StyledText
            elide: Text.ElideRight

            visible:
                bannerRow.width - bannerAvatar.width - bannerButtons.width > 30

            Layout.fillWidth: true
            Layout.leftMargin: bannerIcon.Layout.leftMargin
            Layout.rightMargin: Layout.leftMargin
        }

        HSpacer {}

        HRowLayout {
            id: bannerButtons

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

            Repeater {
                id: bannerRepeater
                model: []

                HUIButton {
                    id: button
                    text: modelData.text
                    iconName: modelData.iconName
                    onClicked: buttonCallbacks[modelData.name](button)

                    clip: true
                    Layout.maximumWidth: bannerButtons.compact ? height : -1
                    Layout.fillHeight: true
                }
            }
        }
    }
}
