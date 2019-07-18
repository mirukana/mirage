// Copyright 2019 miruka
// This file is part of harmonyqml, licensed under LGPLv3.

import QtQuick 2.12
import SortFilterProxyModel 0.2
import "../../Base"

HRectangle {
    property alias listView: eventList

    color: theme.chat.eventList.background

    HListView {
        id: eventList
        clip: true

        model: HListModel {
            sourceModel: timelines

            filters: ValueFilter {
                roleName: "roomId"
                value: chatPage.roomId
            }
        }

        delegate: EventDelegate {}

        anchors.fill: parent
        anchors.leftMargin: theme.spacing
        anchors.rightMargin: theme.spacing

        topMargin: theme.spacing
        bottomMargin: theme.spacing
        verticalLayoutDirection: ListView.BottomToTop

        // Keep x scroll pages cached, to limit images having to be
        // reloaded from network.
        cacheBuffer: height * 4

        // Declaring this as "alias" provides the on... signal
        property real yPos: visibleArea.yPosition
        property bool canLoad: true
        property int zz: 0

        onYPosChanged: {
            if (chatPage.category != "Invites" && canLoad && yPos <= 0.1) {
                zz += 1
                print(canLoad, zz)
                eventList.canLoad = false
                py.callClientCoro(
                    chatPage.userId, "load_past_events", [chatPage.roomId],
                    moreToLoad => { eventList.canLoad = moreToLoad }
                )
            }
        }
    }

    HNoticePage {
        text: qsTr("Nothing to show here yet...")

        visible: eventList.model.count < 1
        anchors.fill: parent
    }
}
