// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQml.Models 2.12

DelegateModel {
    filterOnGroup: "filtered"

    groups: DelegateModelGroup {
        id: filtered
        name: "filtered"
        includeByDefault: false
    }

    onAcceptItemChanged: refilterAll()

    items.onChanged: {
        for (let i = 0; i < inserted.length; i++)
            for (let offset = 0; offset <= inserted[i].count - 1; offset++)
                refilterAt(inserted[i].index + offset)
    }


    property var acceptItem: item => true
    readonly property alias filtered: filtered


    function refilterAt(index) {
        const item = items.get(index)
        item.inFiltered = acceptItem(item.model)
    }

    function refilterAll() {
        for (let i = 0; i < items.count; i++) refilterAt(i)
    }

    function filteredFindIndex(id) {
        for (let i = 0; i < filtered.count; i++)
            if (filtered.get(i).id === id) return i

        return null
    }

    function filteredFind(id) {
        for (let i = 0; i < filtered.count; i++)
            if (filtered.get(i).id === id) return get(i)

        return null
    }
}
