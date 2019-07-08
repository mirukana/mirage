// Copyright 2019 miruka
// This file is part of harmonyqml, licensed under LGPLv3.

import QtQuick 2.7
import SortFilterProxyModel 0.2
import "../Base"

HListModel {
    sorters: StringSorter {
        roleName: "userId"
        numericMode: true  // human numeric sort
    }
}
