// Copyright 2019 miruka
// This file is part of harmonyqml, licensed under LGPLv3.

import QtQuick 2.7

HLabel {
    id: label
    textFormat: Text.RichText

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        propagateComposedEvents: true

        onPositionChanged: function (mouse) {
            mouse.accepted = false
            cursorShape = label.linkAt(mouse.x, mouse.y) ?
                          Qt.PointingHandCursor : Qt.ArrowCursor
        }

        onClicked: function(mouse) {
            var link = label.linkAt(mouse.x, mouse.y)
            mouse.accepted = Boolean(link)
            if (link) { Qt.openUrlExternally(link) }
        }
    }
}
