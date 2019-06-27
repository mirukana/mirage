import QtQuick 2.7

ListModel {
    // To initialize a HListModel with items,
    // use `Component.onCompleted: extend([{"foo": 1, "bar": 2}, ...])`

    id: listModel

    function extend(new_items) {
        for (var i = 0; i < new_items.length; i++) {
            listModel.append(new_items[i])
        }
    }

    function getIndices(where_role, is, max) {  // max: undefined or int
        var results = []

        for (var i = 0; i < listModel.count; i++) {
            if (listModel.get(i)[where_role] == is) {
                results.push(i)

                if (max && results.length >= max) {
                    break
                }
            }
        }
        return results
    }

    function getWhere(where_role, is, max) {
        var indices = getIndices(where_role, is, max)
        var results = []

        for (var i = 0; i < indices.length; i++) {
            results.push(listModel.get(indices[i]))
        }
        return results
    }

    function upsert(where_role, is, new_item) {
        // new_item can contain only the keys we're interested in updating

        var indices = getIndices(where_role, is, 1)

        if (indices.length == 0) {
            listModel.append(new_item)
        } else {
            listModel.set(indices[0], new_item)
        }
    }

    function pop(index) {
        var item = listModel.get(index)
        listModel.remove(index)
        return item
    }
}
