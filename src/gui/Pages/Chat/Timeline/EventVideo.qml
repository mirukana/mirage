// Copyright Mirage authors & contributors <https://github.com/mirukana/mirage>
// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Layouts 1.12
import QtAV 1.7
import "../../.."
import "../../../Base"
import "../../../Base/MediaPlayer"

VideoPlayer {
    readonly property bool hovered: hover.hovered

    HoverHandler { id: hover }
}
