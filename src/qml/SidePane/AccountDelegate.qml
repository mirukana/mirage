// Copyright 2019 miruka
// This file is part of harmonyqml, licensed under LGPLv3.

import QtQuick 2.7
import QtQuick.Layouts 1.3
import "../Base"

Column {
    id: accountDelegate
    width: parent.width

    property var userInfo: users.find(model.userId)

    property bool expanded: true

    HRowLayout {
        width: parent.width
        height: childrenRect.height
        id: row

        HUserAvatar {
            id: avatar
            // Need to do this because conflict with the model property
            Component.onCompleted: userId = model.userId
        }

        HColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true

            HLabel {
                id: accountLabel
                text: userInfo.displayName || model.userId
                elide: HLabel.ElideRight
                maximumLineCount: 1
                Layout.fillWidth: true
                leftPadding: 6
                rightPadding: leftPadding
            }

            HTextField {
                id: statusEdit
                text: userInfo.statusMessage
                placeholderText: qsTr("Set status message")
                font.pixelSize: theme.fontSize.small
                background: null

                padding: 0
                leftPadding: accountLabel.leftPadding
                rightPadding: leftPadding
                Layout.fillWidth: true

                onEditingFinished: {
                    //Backend.setStatusMessage(model.userId, text)  TODO
                    pageStack.forceActiveFocus()
                }
            }
        }

        ExpandButton {
            expandableItem: accountDelegate
            Layout.preferredHeight: row.height
        }
    }

    RoomCategoriesList {
        id: roomCategoriesList
        interactive: false  // no scrolling
        visible: height > 0
        width: parent.width
        height: childrenRect.height * (accountDelegate.expanded ? 1 : 0)
        clip: heightAnimation.running

        userId: userInfo.userId

        Behavior on height {
            HNumberAnimation { id: heightAnimation }
        }
    }
}
