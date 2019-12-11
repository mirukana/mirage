import QtQuick 2.12
import QtQuick.Controls 2.12
import "../Base"
import "../utils.js" as Utils

Rectangle {
    id: avatar
    implicitWidth: theme.controls.avatar.size
    implicitHeight: theme.controls.avatar.size

    color: avatarImage.visible ? "transparent" : Utils.hsluv(
       name ? Utils.hueFrom(name) : 0,
       name ? theme.controls.avatar.background.saturation : 0,
       theme.controls.avatar.background.lightness,
       theme.controls.avatar.background.opacity
   )

    property string name
    property alias mxc: avatarImage.mxc

    property alias toolTipMxc: avatarToolTipImage.mxc
    property alias sourceOverride: avatarImage.sourceOverride
    property alias toolTipSourceOverride: avatarToolTipImage.sourceOverride
    property alias fillMode: avatarImage.fillMode
    property alias animate: avatarImage.animate

    readonly property alias hovered: hoverHandler.hovered

    HLabel {
        z: 1
        anchors.centerIn: parent
        visible: ! avatarImage.visible

        text: name ? name.charAt(0) : "?"
        font.pixelSize: parent.height / 1.4

        color: Utils.hsluv(
           name ? Utils.hueFrom(name) : 0,
           name ? theme.controls.avatar.letter.saturation : 0,
           theme.controls.avatar.letter.lightness,
           theme.controls.avatar.letter.opacity
       )
    }

    HMxcImage {
        id: avatarImage
        anchors.fill: parent
        progressBar.visible: false
        visible: Boolean(sourceOverride || mxc)
        z: 2
        sourceSize.width: parent.width
        sourceSize.height: parent.height
        fillMode: Image.PreserveAspectCrop
        animate: false

        HoverHandler { id: hoverHandler }

        HToolTip {
            id: avatarToolTip
            visible: ! avatarImage.broken &&
                     avatarImage.status !== Image.Error &&
                     (toolTipSourceOverride || toolTipMxc) &&
                     hoverHandler.hovered
            delay: 1000
            backgroundColor: theme.controls.avatar.hoveredImage.background

            readonly property int dimension: Math.min(
                mainUI.width / 1.25,
                mainUI.height / 1.25,
                theme.controls.avatar.hoveredImage.size +
                background.border.width * 2,
            )

            contentItem: HMxcImage {
                id: avatarToolTipImage
                fillMode: Image.PreserveAspectCrop
                mxc: avatarImage.mxc

                sourceSize.width: avatarToolTip.dimension
                sourceSize.height: avatarToolTip.dimension
                width: avatarToolTip.dimension
                height: avatarToolTip.dimension
            }
        }
    }
}
