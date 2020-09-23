// Copyright Mirage authors & contributors <https://github.com/mirukana/mirage>
// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Window 2.12
import ".."
import "../../Base"

HFlow {
    id: root

    property HPopup viewer

    property color backgroundsColor:
        viewer.info.y >= viewer.height - viewer.info.height ?
        "transparent" :
        theme.controls.button.background

    readonly property real calculatedWidth:
        utils.sumChildrenImplicitWidths(visibleChildren)


    HButton {
        id: pause
        backgroundColor: root.backgroundsColor
        icon.name: viewer.imagesPaused ? "image-play" : "image-pause"
        toolTip.text: viewer.imagesPaused ? qsTr("Play") : qsTr("Pause")
        onClicked: viewer.imagesPaused = ! viewer.imagesPaused
        visible: viewer.isAnimated

        HPopupShortcut {
            sequences: window.settings.keys.imageViewer.pause
            onActivated: pause.clicked()
        }
    }

    HButton {
        backgroundColor: root.backgroundsColor
        text: qsTr("%1x").arg(utils.round(viewer.imagesSpeed))
        label.font.pixelSize: theme.fontSize.big
        height: pause.height
        topPadding: 0
        bottomPadding: 0
        toolTip.text: qsTr("Change speed")
        onClicked: speedMenu.popup()
        visible: viewer.isAnimated

        HPopupShortcut {
            sequences: window.settings.keys.imageViewer.previousSpeed
            onActivated: viewer.imagesSpeed = viewer.availableSpeeds[Math.min(
                viewer.availableSpeeds.indexOf(viewer.imagesSpeed) + 1,
                viewer.availableSpeeds.length - 1,
            )]
        }

        HPopupShortcut {
            sequences: window.settings.keys.imageViewer.nextSpeed
            onActivated: viewer.imagesSpeed = viewer.availableSpeeds[Math.max(
                viewer.availableSpeeds.indexOf(viewer.imagesSpeed) - 1, 0,
            )]
        }

        HPopupShortcut {
            sequences: window.settings.keys.imageViewer.resetSpeed
            onActivated: viewer.imagesSpeed = 1
        }
    }

    HButton {
        id: rotateLeft
        backgroundColor: root.backgroundsColor
        icon.name: "image-rotate-left"
        toolTip.text: qsTr("Rotate left")
        autoRepeat: true
        autoRepeatDelay: 20
        autoRepeatInterval: theme.animationDuration * 3
        onPressed: viewer.animatedRotationTarget -= 45

        HPopupShortcut {
            sequences: window.settings.keys.imageViewer.rotateLeft
            onActivated: viewer.animatedRotationTarget -= 45
        }
    }

    HButton {
        id: rotateRight
        backgroundColor: root.backgroundsColor
        icon.name: "image-rotate-right"
        toolTip.text: qsTr("Rotate right")
        autoRepeat: true
        autoRepeatDelay: 20
        autoRepeatInterval: theme.animationDuration * 3
        onPressed: viewer.animatedRotationTarget += 45

        HPopupShortcut {
            sequences: window.settings.keys.imageViewer.rotateRight
            onActivated: viewer.animatedRotationTarget += 45
        }
    }

    HPopupShortcut {
        sequences: window.settings.keys.imageViewer.rotateReset
        onActivated: viewer.animatedRotationTarget = 0
    }

    HButton {
        id: expand
        backgroundColor: root.backgroundsColor
        icon.name: "image-alt-scale-mode"
        toolTip.text:
            viewer.imageLargerThanWindow ?
            qsTr("Expand to original size") :
            qsTr("Expand to screen")

        checked: viewer.alternateScaling
        onClicked: viewer.alternateScaling = ! viewer.alternateScaling

        HPopupShortcut {
            sequences: window.settings.keys.imageViewer.expand
            onActivated: expand.clicked()
        }
    }

    HButton {
        id: fullScreen
        backgroundColor: root.backgroundsColor
        icon.name: "image-fullscreen"
        toolTip.text: qsTr("Fullscreen")
        checked: window.visibility === Window.FullScreen
        onClicked: viewer.toggleFullScreen()
        visible: Qt.application.supportsMultipleWindows

        HPopupShortcut {
            sequences: window.settings.keys.imageViewer.fullScreen
            onActivated: fullScreen.clicked()
        }
    }

    HButton {
        id: close  // always visible
        backgroundColor: root.backgroundsColor
        icon.name: "image-close"
        toolTip.text: qsTr("Close")
        onClicked: viewer.close()

        HPopupShortcut {
            sequences: window.settings.keys.imageViewer.close
            onActivated: close.clicked()
        }
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
