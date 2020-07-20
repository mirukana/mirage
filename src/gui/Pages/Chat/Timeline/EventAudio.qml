// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Layouts 1.12
import QtAV 1.7
import "../../.."
import "../../../Base"
import "../../../Base/MediaPlayer"

AudioPlayer {
    id: audio

    HoverHandler {
        onHoveredChanged:
            eventDelegate.hoveredMediaTypeUrl =
                hovered ? [Utils.Media.Audio, audio.source, loader.title] : []
    }
}
