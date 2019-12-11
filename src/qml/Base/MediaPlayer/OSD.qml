import QtQuick 2.12
import QtQuick.Layouts 1.12
import QtAV 1.7
import "../../Base"
import "../../utils.js" as Utils

HColumnLayout {
    id: osd
    visible: osdScaleTransform.yScale > 0

    transform: Scale {
        id: osdScaleTransform
        yScale: audioOnly ||
                osdHover.hovered ||
                media.playbackState !== MediaPlayer.PlayingState ||
                osd.showup ?
                1 : 0
        origin.y: osd.height

        Behavior on yScale { HNumberAnimation {} }
    }


    property QtObject media: parent  // QtAV.Video or QtAV.MediaPlayer
    property bool audioOnly: false
    property bool showup: false
    property bool fullScreen: false

    property real savedAspectRatio: 16 / 9
    property int savedDuration: 0
    readonly property real aspectRatio: media.sourceAspectRatio || 0
    readonly property int duration: media.duration
    readonly property int boundPosition:
        savedDuration ?
        Math.min(media.position, savedDuration) : media.position


    onShowupChanged: if (showup) osdHideTimer.restart()
    onDurationChanged: if (duration) savedDuration = duration
    onAspectRatioChanged: if (aspectRatio) savedAspectRatio = aspectRatio


    function togglePlay() {
        media.playbackState === MediaPlayer.PlayingState ?
        media.pause() : media.play()
    }

    function seekToPosition(pos) {  // pos: 0.0 to 1.0
        if (media.playbackState === MediaPlayer.StoppedState) media.play()
        if (media.seekable) media.seek(pos * (savedDuration || boundPosition))
    }


    HoverHandler { id: osdHover }

    Timer {
        id: osdHideTimer
        interval: window.settings.media.autoHideOSDAfterMsec
        onTriggered: osd.showup = false
    }

    HSlider {
        id: timeSlider
        topPadding: 5
        z: 1
        to: savedDuration || boundPosition
        backgroundColor: theme.mediaPlayer.progress.background
        enableRadius: false
        fullHeight: true
        mouseArea.hoverEnabled: true

        onMoved: seekToPosition(timeSlider.position)

        Layout.fillWidth: true
        Layout.preferredHeight: theme.mediaPlayer.progress.height

        HToolTip {
            id: previewToolTip
            x: timeSlider.mouseArea.mouseX - width / 2
            visible: ! audioOnly &&

                     preview.implicitWidth >=
                     previewLabel.implicitWidth + previewLabel.padding &&

                     preview.implicitHeight >=
                     previewLabel.implicitHeight + previewLabel.padding &&

                     ! timeSlider.pressed && timeSlider.mouseArea.containsMouse

            readonly property int wantTimestamp:
                visible ?
                savedDuration *
                (timeSlider.mouseArea.mouseX / timeSlider.mouseArea.width) :
                -1

            Timer {
                interval: 300
                running: previewToolTip.visible
                repeat: true
                triggeredOnStart: true
                onTriggered: preview.timestamp = previewToolTip.wantTimestamp
            }

            contentItem: VideoPreview {
                id: preview
                implicitHeight: Math.min(
                    theme.mediaPlayer.hoverPreview.maxHeight,
                    media.height - osd.height - theme.spacing
                )
                implicitWidth: Math.min(
                    implicitHeight * savedAspectRatio,
                    media.width - theme.spacing,
                )
                file: media.source

                HLabel {
                    id: previewLabel
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    anchors.margins: padding / 4
                    text: Utils.formatDuration(previewToolTip.wantTimestamp)
                    padding: theme.spacing / 2
                    opacity: previewToolTip.wantTimestamp === -1 ? 0 : 1

                    background: Rectangle {
                        color: theme.mediaPlayer.controls.background
                        radius: theme.radius
                    }
                }
            }
        }

        Binding  on value {
            value: boundPosition
            when: ! timeSlider.pressed
        }
    }

    Rectangle {
        color: theme.mediaPlayer.controls.background

        Layout.fillWidth: true
        Layout.preferredHeight: childrenRect.height

        HRowLayout {
            width: parent.width

            OSDButton {
                readonly property string mode:
                    media.playbackState === MediaPlayer.StoppedState &&
                    savedDuration &&
                    boundPosition >= savedDuration - 500 ?
                    "restart" :

                    media.playbackState === MediaPlayer.PlayingState ? "pause" :

                    "play"

                icon.name: "player-" + mode
                toolTip.text: qsTr(
                    mode === "play"  ? "Play" :
                    mode === "pause" ? "Pause" :
                    "Restart"
                )
                onClicked: togglePlay()
            }

            // OSDButton {
                // icon.name: "player-loop"
                // visible: false
            // }

            OSDButton {
                id: volumeButton
                icon.name: "player-volume-" + (
                    media.muted ? "mute" : media.volume > 0.5 ? "high" : "low"
                )
                text: media.muted ? "" : Math.round(media.volume * 100)
                toolTip.text: media.muted ? qsTr("Unmute") : qsTr("Mute")
                onClicked: media.muted = ! media.muted
            }

            HSlider {
                value: media.volume
                onMoved: media.volume = value

                visible: Layout.preferredWidth > 0
                Layout.preferredWidth:
                    ! media.muted &&
                    (hovered || pressed || volumeButton.hovered) ?
                    theme.mediaPlayer.controls.volumeSliderWidth : 0
                Layout.fillHeight: true

                Behavior on Layout.preferredWidth { HNumberAnimation {} }
            }

            OSDButton {
                id: speedButton
                icon.name: "player-speed"
                text: qsTr("%1x").arg(Utils.round(media.playbackRate))
                toolTip.text: qsTr("Reset speed")
                onClicked: media.playbackRate = 1
            }

            HSlider {
                id: speedSlider
                from: 0.2
                to: 4
                value: media.playbackRate
                stepSize: 0.2
                snapMode: HSlider.SnapAlways

                onMoved: media.playbackRate = value

                visible: Layout.preferredWidth > 0
                Layout.preferredWidth:
                    (hovered || pressed || speedButton.hovered) ?
                    theme.mediaPlayer.controls.speedSliderWidth : 0
                Layout.fillHeight: true

                Behavior on Layout.preferredWidth { HNumberAnimation {} }
            }

            OSDLabel {
                text:  boundPosition && savedDuration ?

                       qsTr("%1 / %2")
                       .arg(Utils.formatDuration(boundPosition))
                       .arg(Utils.formatDuration(savedDuration)) :

                       boundPosition || savedDuration ?
                       Utils.formatDuration(boundPosition || savedDuration) :

                       ""
            }

            HSpacer {}

            OSDLabel {
                text: boundPosition && savedDuration ?
                      qsTr("-%1").arg(
                          Utils.formatDuration(savedDuration - boundPosition)
                      ) : ""
            }

            // OSDButton {
            //     icon.name: "player-track-video"
            // }

            // OSDButton {
            //     icon.name: "player-track-audio"
            // }

            // OSDButton {
            //     icon.name: "player-track-subtitle"
            // }

            OSDButton {
                icon.name: "download"
                toolTip.text: qsTr("Download")
                onClicked: Qt.openUrlExternally(media.source)
            }

            OSDButton {
                id: fullScreenButton
                visible: ! audioOnly
                icon.name: "player-fullscreen" + (fullScreen ? "-exit" : "")
                toolTip.text: fullScreen ?
                              qsTr("Exit fullscreen") : qsTr("Fullscreen")
                onClicked: fullScreen = ! fullScreen
            }
        }
    }
}
