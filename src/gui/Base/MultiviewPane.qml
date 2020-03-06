// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12

HDrawer {
    id: pane

    defaultSize: buttonRepeater.summedImplicitWidth
    minimumSize:
        buttonRepeater.count > 0 ? buttonRepeater.itemAt(0).implicitWidth : 0

    background: HColumnLayout{
        Rectangle {
            color: buttonsBackgroundColor

            Layout.fillWidth: true
            Layout.preferredHeight: buttonFlow.height

            Behavior on Layout.preferredHeight { HNumberAnimation {} }
        }

        Rectangle {
            color: backgroundColor

            Layout.fillWidth: true
            Layout.fillHeight: true
        }
    }


    property color buttonsBackgroundColor
    property color backgroundColor

    readonly property alias buttonRepeater: buttonRepeater
    readonly property alias swipeView: swipeView

    default property alias swipeViewData: swipeView.contentData


    HColumnLayout {
        anchors.fill: parent

        HFlow {
            id: buttonFlow
            populate: null

            Layout.fillWidth: true

            HRepeater {
                id: buttonRepeater
            }
        }

        HSwipeView {
            id: swipeView
            clip: true
            interactive: ! pane.collapsed

            Layout.fillWidth: true
            Layout.fillHeight: true
        }
    }
}
