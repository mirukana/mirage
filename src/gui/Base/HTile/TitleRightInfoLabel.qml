// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Layouts 1.12
import ".."

HLabel {
    property HTile tile
    property int hideUnderWidth: 200


    font.pixelSize: theme.fontSize.small
    verticalAlignment: Qt.AlignVCenter
    color: theme.colors.halfDimText
    opacity: Layout.maximumWidth > 0 ? 1 : 0
    visible: opacity > 0

    Layout.fillHeight: true
    Layout.maximumWidth:
        text && tile.width >= hideUnderWidth * theme.uiScale ?
        implicitWidth : 0

    Behavior on Layout.maximumWidth { HNumberAnimation {} }
}
