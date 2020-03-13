// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12

HDrawer {
    id: pane
    defaultSize: buttonRepeater.summedImplicitWidth
    minimumSize:
        buttonRepeater.count > 0 ? buttonRepeater.itemAt(0).implicitWidth : 0


    property color buttonsBackgroundColor

    readonly property alias buttonRepeater: buttonRepeater
    readonly property alias swipeView: swipeView

    default property alias swipeViewData: swipeView.contentData


    HColumnLayout {
        anchors.fill: parent

        Rectangle {
            color: buttonsBackgroundColor

            Layout.fillWidth: true
            Layout.preferredHeight: childrenRect.height

            HFlow {
                id: buttonFlow
                width: parent.width
                populate: null

                HRepeater {
                    id: buttonRepeater
                }
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
