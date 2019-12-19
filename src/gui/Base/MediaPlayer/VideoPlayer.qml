// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Window 2.12
import QtAV 1.7

Video {
    id: video
    autoLoad: window.settings.media.autoLoad
    autoPlay: window.settings.media.autoPlay
    volume: window.settings.media.defaultVolume / 100
    muted: window.settings.media.startMuted
    implicitWidth: fullScreen ? window.width : 640
    implicitHeight: fullScreen ? window.height : (width / osd.savedAspectRatio)


    property bool hovered: false
    property alias fullScreen: osd.fullScreen

    property int oldVisibility: Window.Windowed
    property QtObject oldParent: video.parent


    onFullScreenChanged: {
        if (fullScreen) {
            oldVisibility     = window.visibility
            window.visibility = Window.FullScreen

            oldParent    = video.parent
            video.parent = mainUI.fullScreenPopup.contentItem

            mainUI.fullScreenPopup.open()

        } else {
            window.visibility = oldVisibility
            mainUI.fullScreenPopup.close()

            video.parent = oldParent
        }
    }


    Connections {
        target: mainUI.fullScreenPopup
        onClosed: fullScreen = false
    }

    TapHandler {
        onTapped: osd.togglePlay()
        onDoubleTapped: video.fullScreen = ! video.fullScreen
    }

    MouseArea {
        width: parent.width
        height: parent.height - (osd.visible ? osd.height : 0)
        acceptedButtons: Qt.NoButton
        hoverEnabled: true
        propagateComposedEvents: true

        onContainsMouseChanged: video.hovered = containsMouse
        onMouseXChanged: osd.showup = true
        onMouseYChanged: osd.showup = true
    }

    OSD {
        id: osd
        width: parent.width
        anchors.bottom: parent.bottom
    }
}
