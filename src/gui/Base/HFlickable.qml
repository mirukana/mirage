// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Controls 2.12

Flickable {
    id: flickable
    interactive: contentWidth > width || contentHeight > height
    ScrollBar.vertical: ScrollBar {
        visible: flickable.interactive
    }


    readonly property HTrackpadFix trackpadFix: HTrackpadFix {
        flickable: flickable
        width: flickable.width
        height: flickable.height
    }
}
