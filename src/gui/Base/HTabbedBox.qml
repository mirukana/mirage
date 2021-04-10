// Copyright Mirage authors & contributors <https://github.com/mirukana/mirage>
// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12

HPage {
    default property alias swipeViewData: swipeView.contentData

    property Component tabBar: HTabBar {}
    property alias backButton: backButton
    property bool showBackButton: false

    readonly property alias swipeView: swipeView

    contentWidth:
        Math.max(swipeView.contentWidth, theme.controls.box.defaultWidth)

    header: HRowLayout {
        HButton {
            id: backButton
            visible: Layout.preferredWidth > 0
            Layout.preferredWidth: showBackButton ? implicitWidth : 0

            Behavior on Layout.preferredWidth { HNumberAnimation {} }
        }

        HLoader {
            id: tabBarLoader
            asynchronous: false
            sourceComponent: tabBar

            Layout.fillWidth: true
            Layout.fillHeight: true
        }
    }

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
        target: tabBarLoader.item
        property: "currentIndex"
        value: swipeView.currentIndex
    }

    SwipeView {
        id: swipeView
        anchors.fill: parent
        clip: true
        currentIndex: tabBarLoader.item.currentIndex
        onCurrentItemChanged: currentItem.takeFocus()
    }
}
