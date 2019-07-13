// Copyright 2019 miruka
// This file is part of harmonyqml, licensed under LGPLv3.

import QtQuick 2.12
import QtQuick.Layouts 1.12
import SortFilterProxyModel 0.2
import "../Base"

HListView {
    property string userId: ""

    id: roomCategoriesList

    model: SortFilterProxyModel {
        sourceModel: roomCategories
        filters: ValueFilter {
            roleName: "userId"
            value: userId
        }
    }

    delegate: RoomCategoryDelegate {}
}
