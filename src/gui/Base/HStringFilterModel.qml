// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQml.Models 2.12

HFilterModel {
    model: sourceModel
    acceptItem: item => utils.filterMatches(filter, item[field])
    onFilterChanged: refilterAll()


    property string field: "id"
    property string filter: ""
    property ListModel sourceModel
}
