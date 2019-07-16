// Copyright 2019 miruka
// This file is part of harmonyqml, licensed under LGPLv3.

import QtQuick 2.12
import QtQuick.Controls 2.12
import "../Base"
import "../utils.js" as Utils

HRectangle {
    id: avatar
    implicitWidth: theme.avatar.size
    implicitHeight: theme.avatar.size

    property string name: ""
    property var imageUrl: ""
    property var toolTipImageUrl: imageUrl
    property alias fillMode: avatarImage.fillMode

    readonly property alias hovered: hoverHandler.hovered

    readonly property var params: Utils.thumbnailParametersFor(width, height)

    color: imageUrl ? "transparent" :
           name ? Utils.avatarColor(name) :
           theme.avatar.background.unknown

    HLabel {
        z: 1
        anchors.centerIn: parent
        visible: ! imageUrl

        text: name ? name.charAt(0) : "?"
        color: theme.avatar.letter
        font.pixelSize: parent.height / 1.4
    }

    HImage {
        id: avatarImage
        anchors.fill: parent
        visible: imageUrl
        z: 2
        sourceSize.width: params.width
        sourceSize.height: params.height
        fillMode: Image.PreserveAspectCrop
        source: Qt.resolvedUrl(imageUrl)

        HoverHandler {
            id: hoverHandler
        }

        HToolTip {
            id: avatarToolTip
            visible: toolTipImageUrl && hoverHandler.hovered
            width: Math.min(
                mainUI.width / 1.25,
                mainUI.height / 1.25,
                192 + background.border.width * 2
            )
            height: width
            delay: 1000

            background: HRectangle {
                id: background
                border.color: "black"
                border.width: 2
            }

            HImage {
                id: avatarToolTipImage
                anchors.centerIn: parent
                sourceSize.width: parent.width - background.border.width * 2
                sourceSize.height: parent.height - background.border.width * 2
                width: sourceSize.width
                height: sourceSize.width
                fillMode: Image.PreserveAspectCrop
                source: Qt.resolvedUrl(toolTipImageUrl)
            }
        }
    }
}
