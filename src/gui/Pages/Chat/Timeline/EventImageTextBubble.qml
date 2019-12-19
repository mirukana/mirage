// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import "../../../Base"

HLabel {
    id: bubble
    anchors.margins: theme.spacing / 4

    topPadding: theme.spacing / 2
    bottomPadding: topPadding
    leftPadding: theme.spacing / 1.5
    rightPadding: leftPadding

    font.pixelSize: theme.fontSize.small

    background: Rectangle {
        color: Qt.hsla(0, 0, 0, 0.7)
        radius: theme.radius
    }

    Binding on visible {
        value: false
        when: ! Boolean(bubble.text)
    }
}
