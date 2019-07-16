// Copyright 2019 miruka
// This file is part of harmonyqml, licensed under LGPLv3.

import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import "../SidePane"

SwipeView {
    default property alias columnChildren: contentColumn.children
    property alias page: innerPage
    property alias flickable: innerFlickable

    property bool wide: width > 414 + leftPadding + rightPadding

    property int currentSpacing:
        Math.min(theme.spacing * width / 400, theme.spacing * 2)

    id: swipeView
    currentIndex: 1
    clip: true
    interactive: sidePane.reduce

    SidePane {
        canAutoSize: false
        autoWidthRatio: 1.0
        visible: swipeView.interactive
        onVisibleChanged: swipeView.setCurrentIndex(1)
    }

    Page {
        id: innerPage
        background: null

        leftPadding: currentSpacing < theme.spacing ? 0 : currentSpacing
        rightPadding: leftPadding
        Behavior on leftPadding { HNumberAnimation {} }

        Flickable {
            id: innerFlickable
            anchors.fill: parent
            clip: true
            contentWidth: parent.width
            contentHeight: contentColumn.childrenRect.height
            interactive: contentWidth > width || contentHeight > height

            HColumnLayout {
                id: contentColumn
                spacing: theme.spacing
                width: innerFlickable.width
                height: innerFlickable.height
            }
        }
    }
}
