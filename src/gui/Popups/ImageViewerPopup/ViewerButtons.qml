// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Window 2.12
import "../../Base"

HFlow {
    property HPopup viewer

    readonly property real calculatedWidth:
        (closeButton.implicitWidth * visibleChildren.length) + theme.spacing


    HButton {
        id: playButton
        icon.name: viewer.imagesPaused ? "image-play" : "image-pause"
        toolTip.text: viewer.imagesPaused ? qsTr("Play") : qsTr("Pause")
        onClicked: viewer.imagesPaused = ! viewer.imagesPaused
        visible: viewer.isAnimated
    }

    HButton {
        text: qsTr("%1x").arg(utils.round(viewer.imagesSpeed))
        label.font.pixelSize: theme.fontSize.big
        height: playButton.height
        topPadding: 0
        bottomPadding: 0
        toolTip.text: qsTr("Change speed")
        onClicked: speedMenu.popup()
        visible: viewer.isAnimated
    }

    HButton {
        icon.name: "image-rotate-left"
        toolTip.text: qsTr("Rotate left")
        autoRepeat: true
        autoRepeatDelay: 20
        autoRepeatInterval: theme.animationDuration * 3
        onPressed: viewer.animatedRotationTarget -= 45
    }

    HButton {
        icon.name: "image-rotate-right"
        toolTip.text: qsTr("Rotate right")
        autoRepeat: true
        autoRepeatDelay: 20
        autoRepeatInterval: theme.animationDuration * 3
        onPressed: viewer.animatedRotationTarget += 45
    }

    HButton {
        icon.name: "image-alt-scale-mode"
        toolTip.text:
            viewer.imageLargerThanWindow ?
            qsTr("Expand to original size") :
            qsTr("Expand to screen")

        checked: viewer.alternateScaling
        onClicked: viewer.alternateScaling = ! viewer.alternateScaling
    }

    HButton {
        icon.name: "image-fullscreen"
        toolTip.text: qsTr("Fullscreen")
        checked: window.visibility === Window.FullScreen
        onClicked: viewer.toggleFullScreen()
        visible: Qt.application.supportsMultipleWindows
    }

    HButton {
        id: closeButton  // always visible
        icon.name: "image-close"
        toolTip.text: qsTr("Close")
        onClicked: viewer.close()
    }

    HMenu {
        id: speedMenu

        Repeater {
            model: viewer.availableSpeeds

            HMenuItem {
                text: qsTr("%1x").arg(modelData)
                onClicked: viewer.imagesSpeed = modelData
                label.horizontalAlignment: HLabel.AlignHCenter
            }
        }
    }
}
