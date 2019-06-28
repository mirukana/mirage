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

    function forEachWhere(where_role, is, max, func) {
        var items = getWhere(where_role, is, max)
        for (var i = 0; i < items.length; i++) {
            func(item)
        }
    }

    function upsert(where_role, is, new_item, update_if_exist) {
        // new_item can contain only the keys we're interested in updating

        var indices = getIndices(where_role, is, 1)

        if (indices.length == 0) {
            listModel.append(new_item)
            return listModel.get(listModel.count)
        }

        if (update_if_exist != false) {
            listModel.set(indices[0], new_item)
        }
        return listModel.get(indices[0])
    }

    function pop(index) {
        var item = listModel.get(index)
        listModel.remove(index)
        return item
    }

    function popWhere(where_role, is, max) {
        var indices = getIndices(where_role, is, max)
        var results = []

        for (var i = 0; i < indices.length; i++) {
            results.push(listModel.get(indices[i]))
            listModel.remove(indices[i])
        }
        return results
    }


    function toObject(item_list) {
        item_list = item_list || listModel
        var obj_list = []

        for (var i = 0; i < item_list.count; i++) {
            var item = item_list.get(i)
            var obj  = JSON.parse(JSON.stringify(item))

            for (var role in obj) {
                if (obj[role]["objectName"] != undefined) {
                    obj[role] = toObject(item[role])
                }
            }
            obj_list.push(obj)
        }
        return obj_list
    }

    function toJson() {
        return JSON.stringify(toObject(), null, 4)
    }
}
