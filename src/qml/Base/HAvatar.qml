import QtQuick 2.12
import QtQuick.Controls 2.12
import "../Base"
import "../utils.js" as Utils

Rectangle {
    id: avatar
    implicitWidth: theme.controls.avatar.size
    implicitHeight: theme.controls.avatar.size

    property string name: ""
    property var imageUrl: ""
    property var toolTipImageUrl: imageUrl
    property alias fillMode: avatarImage.fillMode
    property alias animate: avatarImage.animate

    readonly property alias hovered: hoverHandler.hovered

    readonly property var params: Utils.thumbnailParametersFor(width, height)

    color: avatarImage.visible ? "transparent" : Utils.hsluv(
       name ? Utils.hueFrom(name) : 0,
       name ? theme.controls.avatar.background.saturation : 0,
       theme.controls.avatar.background.lightness,
       theme.controls.avatar.background.opacity
   )

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

    HImage {
        id: avatarImage
        anchors.fill: parent
        visible: imageUrl
        z: 2
        sourceSize.width: params.width
        sourceSize.height: params.height
        fillMode: Image.PreserveAspectCrop
        source: Qt.resolvedUrl(imageUrl)
        animate: false
        loadingLabel.font.pixelSize: theme.fontSize.small

        HoverHandler { id: hoverHandler }

        HToolTip {
            id: avatarToolTip
            visible: toolTipImageUrl && hoverHandler.hovered
            delay: 1000
            backgroundColor: theme.controls.avatar.hoveredImage.background

            readonly property int dimension: Math.min(
                mainUI.width / 1.25,
                mainUI.height / 1.25,
                theme.controls.avatar.hoveredImage.size +
                background.border.width * 2,
            )

            contentItem: HImage {
                id: avatarToolTipImage
                fillMode: Image.PreserveAspectCrop
                source: Qt.resolvedUrl(toolTipImageUrl)

                sourceSize.width: avatarToolTip.dimension
                sourceSize.height: avatarToolTip.dimension
                width: avatarToolTip.dimension
                height: avatarToolTip.dimension
            }
        }
    }
}
