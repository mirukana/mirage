// Copyright 2019 miruka
// This file is part of harmonyqml, licensed under LGPLv3.

import QtQuick 2.7
import "../Base"
import "../utils.js" as Utils

Rectangle {
    property string name: ""
    property var imageUrl: null
    property int dimension: theme.avatar.size
    property bool hidden: false

    onImageUrlChanged: if (imageUrl) { avatarImage.source = imageUrl }

    width: dimension
    height: hidden ? 1 : dimension
    implicitWidth: dimension
    implicitHeight: hidden ? 1 : dimension

    opacity: hidden ? 0 : 1

    color: name ? Utils.avatarColor(name) : theme.avatar.background.unknown

    HLabel {
        z: 1
        anchors.centerIn: parent
        visible: ! hidden && ! imageUrl

        text: name ? name.charAt(0) : "?"
        color: theme.avatar.letter
        font.pixelSize: parent.height / 1.4
    }

    HImage {
        z: 2
        id: avatarImage
        anchors.fill: parent
        visible: ! hidden && imageUrl
        fillMode: Image.PreserveAspectCrop

        sourceSize.width: dimension
        sourceSize.height: dimension
    }
}
