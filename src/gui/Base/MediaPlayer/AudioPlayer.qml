// Copyright Mirage authors & contributors <https://github.com/mirukana/mirage>
// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtAV 1.7

OSD {
    id: osd

    property alias source: audioPlayer.source


    audioOnly: true
    media: audioPlayer

    implicitWidth: osd.width
    implicitHeight: osd.height

    MediaPlayer {
        id: audioPlayer
        autoLoad: window.settings.media.autoLoad
        autoPlay: window.settings.media.autoPlay
        volume: window.settings.media.defaultVolume / 100
        muted: window.settings.media.startMuted
    }
}
