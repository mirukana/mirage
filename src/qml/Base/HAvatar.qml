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
    property var imageUrl: null
    property var toolTipImageUrl: imageUrl
    property alias fillMode: avatarImage.fillMode

    onImageUrlChanged: if (imageUrl) { avatarImage.source = imageUrl }

    onToolTipImageUrlChanged: if (imageUrl) {
        avatarToolTipImage.source = toolTipImageUrl
    }

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
        fillMode: params.fillMode

        HoverHandler {
            id: hoverHandler
        }

        HToolTip {
            id: avatarToolTip
            visible: toolTipImageUrl && hoverHandler.hovered
            width: 128
            height: 128

            HImage {
                id: avatarToolTipImage
                width: parent.width
                height: parent.height
                sourceSize.width: parent.width
                sourceSize.height: parent.height
                fillMode: Image.PreserveAspectCrop
            }
        }
    }
}
