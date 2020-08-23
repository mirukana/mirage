// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Controls 2.12

Rectangle {
    id: avatar

    property bool compact: false

    property string name
    property alias clientUserId: avatarImage.clientUserId
    property alias mxc: avatarImage.mxc
    property alias title: avatarImage.title

    property alias toolTipMxc: avatarToolTipImage.mxc
    property alias sourceOverride: avatarImage.sourceOverride
    property alias toolTipSourceOverride: avatarToolTipImage.sourceOverride
    property alias fillMode: avatarImage.fillMode
    property alias animate: avatarImage.animate

    readonly property alias hovered: hoverHandler.hovered
    readonly property alias circleRadius: avatarImage.circleRadius


    implicitWidth: implicitHeight
    implicitHeight:
        compact ?
        theme.controls.avatar.compactSize :
        theme.controls.avatar.size

    radius: theme.controls.avatar.radius

    color: avatarImage.visible ? "transparent" : utils.hsluv(
       name ? utils.hueFrom(name) : 0,
       name ? theme.controls.avatar.background.saturation : 0,
       theme.controls.avatar.background.lightness,
       theme.controls.avatar.background.opacity
   )

    Behavior on color { HColorAnimation {} }

    HLabel {
        z: 1
        anchors.centerIn: parent
        visible: ! avatarImage.visible

        text: name ? name.charAt(0) : "?"
        font.pixelSize: parent.height / 1.4

        color: utils.hsluv(
           name ? utils.hueFrom(name) : 0,
           name ? theme.controls.avatar.letter.saturation : 0,
           theme.controls.avatar.letter.lightness,
           theme.controls.avatar.letter.opacity
       )

        Behavior on color { HColorAnimation {} }
    }

    HMxcImage {
        id: avatarImage
        anchors.fill: parent
        visible: Boolean(sourceOverride || mxc)
        z: 2
        sourceSize.width: parent.width
        sourceSize.height: parent.height
        showProgressBar: false
        fillMode: Image.PreserveAspectCrop
        animatedFillMode: AnimatedImage.PreserveAspectCrop
        animate: false
        radius: parent.radius

        HoverHandler { id: hoverHandler }

        HToolTip {
            id: avatarToolTip

            readonly property int dimension: Math.min(
                mainUI.width / 1.25,
                mainUI.height / 1.25,
                theme.controls.avatar.hoveredImage.size +
                background.border.width * 2,
            )

            visible:
                ! avatarImage.broken &&
                ! window.anyMenu &&
                avatarImage.width < dimension * 0.75 &&
                (toolTipSourceOverride || toolTipMxc) &&
                hoverHandler.hovered
            delay: 1000
            backgroundColor: theme.controls.avatar.hoveredImage.background

            contentItem: HMxcImage {
                id: avatarToolTipImage
                fillMode: Image.PreserveAspectCrop
                animatedFillMode: AnimatedImage.PreserveAspectCrop
                clientUserId: avatarImage.clientUserId
                mxc: avatarImage.mxc
                title: avatarImage.title

                sourceSize.width: avatarToolTip.dimension
                sourceSize.height: avatarToolTip.dimension
                width: avatarToolTip.dimension
                height: avatarToolTip.dimension
            }
        }
    }
}
