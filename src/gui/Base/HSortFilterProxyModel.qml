// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import SortFilterProxyModel 0.2

SortFilterProxyModel {
    function findIndex(id) {
        for (let i = 0; i < count; i++)
            if (get(i).id === id) return i

        return null
    }

    function find(id) {
        for (let i = 0; i < count; i++)
            if (get(i).id === id) return get(i)

        return null
    }
}
