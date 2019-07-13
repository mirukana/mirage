// Copyright 2019 miruka
// This file is part of harmonyqml, licensed under LGPLv3.

import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../Base"

Column {
    id: roomCategoryDelegate
    width: roomCategoriesList.width

    property int normalHeight: childrenRect.height  // avoid binding loop

    opacity: roomList.model.count > 0 ? 1 : 0
    height: normalHeight * opacity
    visible: opacity > 0

    Behavior on opacity { HNumberAnimation {} }

    property string roomListUserId: userId
    property bool expanded: true

    HRowLayout {
        width: parent.width

        HLabel {
            id: roomCategoryLabel
            text: name
            font.weight: Font.DemiBold
            elide: Text.ElideRight
            maximumLineCount: 1

            Layout.leftMargin: sidePane.currentSpacing
            Layout.fillWidth: true
        }

        ExpandButton {
            expandableItem: roomCategoryDelegate
            iconDimension: 12
        }
    }

    RoomList {
        id: roomList
        interactive: false  // no scrolling
        visible: height > 0
        width: roomCategoriesList.width - accountList.Layout.leftMargin
        opacity: roomCategoryDelegate.expanded ? 1 : 0
        height: childrenRect.height * opacity
        clip: listHeightAnimation.running

        userId: roomListUserId
        category: name

        Behavior on opacity {
            HNumberAnimation { id: listHeightAnimation }
        }
    }
}
