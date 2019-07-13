// Copyright 2019 miruka
// This file is part of harmonyqml, licensed under LGPLv3.

import QtQuick 2.12
import SortFilterProxyModel 0.2

SortFilterProxyModel {
    // To initialize a HListModel with items,
    // use `Component.onCompleted: extend([{"foo": 1, "bar": 2}, ...])`

    id: sortFilteredModel

    property ListModel model: ListModel {}
    sourceModel: model  // Can't assign a "ListModel {}" directly here

    function append(dict)         { return model.append(dict) }
    function clear()              { return model.clear() }
    function insert(index, dict)  { return model.inset(index, dict) }
    function move(from, to, n)    { return model.move(from, to, n) }
    function remove(index, count) { return model.remove(index, count) }
    function set(index, dict)     { return model.set(index, dict) }
    function sync()               { return model.sync() }
    function setProperty(index, prop, value) {
        return model.setProperty(index, prop, value)
    }

    function extend(new_items) {
        for (var i = 0; i < new_items.length; i++) {
            model.append(new_items[i])
        }
    }

    function getIndices(where_roles_are, max_results, max_tries) {
        // max arguments: unefined or int
        var results = []

        for (var i = 0; i < model.count; i++) {
            var item    = model.get(i)
            var include = true

            for (var role in where_roles_are) {
                if (item[role] != where_roles_are[role]) {
                    include = false
                    break
                }
            }

            if (include) {
                results.push(i)
                if (max_results && results.length >= max_results) {
                    break
                }
            }

            if (max_tries && i >= max_tries) {
                break
            }
        }
        return results
    }

    function getWhere(roles_are, max_results, max_tries) {
        var indices = getIndices(roles_are, max_results, max_tries)
        var items = []

        for (var i = 0; i < indices.length; i++) {
            items.push(model.get(indices[i]))
        }
        return items
    }

    function forEachWhere(roles_are, func, max_results, max_tries) {
        var items = getWhere(roles_are, max_results, max_tries)
        for (var i = 0; i < items.length; i++) {
            func(items[i])
        }
    }

    function upsert(where_roles_are, new_item, update_if_exist, max_tries) {
        var indices = getIndices(where_roles_are, 1, max_tries)

        if (indices.length == 0) {
            model.append(new_item)
            return model.get(model.count)
        }

		var existing = model.get(indices[0])
        if (update_if_exist == false) { return existing }

		// Really update only if existing and new item have a difference
		for (var role in existing) {
			if (Boolean(existing[role].getTime)) {
				if (existing[role].getTime() != new_item[role].getTime()) {
					model.set(indices[0], new_item)
					return existing
				}
			} else {
				if (existing[role] != new_item[role]) {
					model.set(indices[0], new_item)
					return existing
				}
			}
		}
        return existing
    }

    function pop(index) {
        var item = model.get(index)
        model.remove(index)
        return item
    }

    function popWhere(roles_are, max_results, max_tries) {
        var indices = getIndices(roles_are, max_results, max_tries)
        var items = []

        for (var i = 0; i < indices.length; i++) {
            items.push(model.get(indices[i]))
            model.remove(indices[i])
        }
        return items
    }


    function toObject(item_list) {
        item_list = item_list || sortFilteredModel
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
