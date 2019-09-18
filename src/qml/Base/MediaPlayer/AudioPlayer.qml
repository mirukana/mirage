import QtQuick 2.12
import QtAV 1.7

OSD {
    id: osd
    audioOnly: true
    media: audioPlayer

    implicitWidth: osd.width
    implicitHeight: osd.height


    property alias source: audioPlayer.source


    MediaPlayer {
        id: audioPlayer
        autoLoad: window.settings.media.autoLoad
        autoPlay: window.settings.media.autoPlay
        volume: window.settings.media.defaultVolume / 100
        muted: window.settings.media.startMuted
    }
}
