// Copyright 2019 miruka
// This file is part of harmonyqml, licensed under LGPLv3.

import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import "../../Base"
import "../../utils.js" as Utils

HRectangle {
    property string userId: ""
    readonly property var userInfo: users.find(userId)

    HColumnLayout {
        anchors.fill: parent

        HRowLayout {
            Layout.preferredHeight: theme.bottomElementsHeight

            HLabel {
                text: qsTr("Edit %1").arg(
                    Utils.coloredNameHtml(userInfo.displayName, userId)
                )
                textFormat: Text.StyledText
                font.pixelSize: theme.fontSize.big
                elide: Text.ElideRight
                maximumLineCount: 1
                // visible: width > 50

                Layout.fillWidth: true
                Layout.maximumWidth: parent.width - tabBar.width
                Layout.leftMargin: 8
                Layout.rightMargin: Layout.leftMargin
            }

            TabBar {
                id: tabBar
                currentIndex: swipeView.currentIndex
                spacing: 0
                contentHeight: parent.height

                TabButton {
                    text: qsTr("Profile")
                    width: implicitWidth * 1.25
                }

                TabButton {
                    text: qsTr("Devices")
                    width: implicitWidth * 1.25
                }

                TabButton {
                    text: qsTr("Harmony")
                    width: implicitWidth * 1.25
                }
            }
        }

        SwipeView {
            id: swipeView
            clip: true
            currentIndex: tabBar.currentIndex

            Layout.fillHeight: true
            Layout.fillWidth: true

            Profile {}
            Devices {}
            ClientSettings {}
        }
    }
}
