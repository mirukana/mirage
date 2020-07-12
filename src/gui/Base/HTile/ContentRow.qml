// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import ".."

HRowLayout {
    property HTile tile


    spacing: tile.spacing
    opacity: tile.contentOpacity
}
