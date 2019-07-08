// Copyright 2019 miruka
// This file is part of harmonyqml, licensed under LGPLv3.

import QtQuick 2.7
import SortFilterProxyModel 0.2
import "../Base"

HListModel {
    sorters: [
        FilterSorter { ValueFilter { roleName: "name"; value: "Invites" } },
        FilterSorter { ValueFilter { roleName: "name"; value: "Rooms" } },
        FilterSorter { ValueFilter { roleName: "name"; value: "Left" } }
    ]
}
