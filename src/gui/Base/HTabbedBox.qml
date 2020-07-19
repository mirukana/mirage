// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12

HPage {
    default property alias swipeViewData: swipeView.contentData


    contentWidth:
        Math.max(swipeView.contentWidth, theme.controls.box.defaultWidth)

    header: HTabBar {}

    background: Rectangle {
        color: theme.controls.box.background
        radius: theme.controls.box.radius
    }

    HNumberAnimation on scale {
        running: true
        from: 0
        to: 1
        overshoot: 2
    }

    Behavior on implicitWidth { HNumberAnimation {} }
    Behavior on implicitHeight { HNumberAnimation {} }

    Binding {
        target: header
        property: "currentIndex"
        value: swipeView.currentIndex
    }

    SwipeView {
        id: swipeView
        anchors.fill: parent
        clip: true
        currentIndex: header.currentIndex

        onCurrentItemChanged: currentItem.takeFocus()
    }
}
