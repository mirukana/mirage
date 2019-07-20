// Copyright 2019 miruka
// This file is part of harmonyqml, licensed under LGPLv3.

import QtQuick 2.12
import QtQuick.Layouts 1.12
import SortFilterProxyModel 0.2
import "../Base"
import "../utils.js" as Utils

HFixedListView {
    id: roomList

    property string userId: ""
    property string category: ""

    model: SortFilterProxyModel {
        sourceModel: rooms
        filters: AllOf {
            ValueFilter {
                roleName: "category"
                value: category
            }

            ValueFilter {
                roleName: "userId"
                value: userId
            }

            ExpressionFilter {
                // Utils... won't work directly in expression?
                function filterIt(filter, text) {
                    return Utils.filterMatches(filter, text)
                }
                expression: filterIt(paneToolBar.roomFilter, displayName)
            }
        }
    }

    delegate: RoomDelegate {}
}
