// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Layouts 1.12
import QtAV 1.7
import "../../.."
import "../../../Base"
import "../../../Base/MediaPlayer"

VideoPlayer {
    id: video

    onHoveredChanged:
        eventDelegate.hoveredMediaTypeUrl =
            hovered ? [Utils.Media.Video, video.source, loader.title] : []
}
