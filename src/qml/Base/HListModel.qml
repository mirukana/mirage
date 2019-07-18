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

    function append(dict)           { return model.append(dict) }
    function clear()                { return model.clear() }
    function insert(index, dict)    { return model.inset(index, dict) }
    function move(from, to, n=1)    { return model.move(from, to, n) }
    function remove(index, count=1) { return model.remove(index, count) }
    function set(index, dict)       { return model.set(index, dict) }
    function sync()                 { return model.sync() }
    function setProperty(index, prop, value) {
        return model.setProperty(index, prop, value)
    }

    function extend(newItems) {
        for (var i = 0; i < newItems.length; i++) {
            model.append(newItems[i])
        }
    }

    function getIndices(whereRolesAre, maxResults=null, maxTries=null) {
        // maxResults, maxTries: null or int
        var results = []

        for (var i = 0; i < model.count; i++) {
            var item    = model.get(i)
            var include = true

            for (var role in whereRolesAre) {
                if (item[role] != whereRolesAre[role]) {
                    include = false
                    break
                }
            }

            if (include) {
                results.push(i)
                if (maxResults && results.length >= maxResults) {
                    break
                }
            }

            if (maxTries && i >= maxTries) {
                break
            }
        }
        return results
    }

    function getWhere(rolesAre, maxResults=null, maxTries=null) {
        var indices = getIndices(rolesAre, maxResults, maxTries)
        var items = []

        for (var i = 0; i < indices.length; i++) {
            items.push(model.get(indices[i]))
        }
        return items
    }

    function forEachWhere(rolesAre, func, maxResults=null, maxTries=null) {
        var items = getWhere(rolesAre, maxResults, maxTries)
        for (var i = 0; i < items.length; i++) {
            func(items[i])
        }
    }

    function upsert(
        whereRolesAre, newItem, updateIfExist=true, maxTries=null
    ) {
        var indices = getIndices(whereRolesAre, 1, maxTries)

        if (indices.length == 0) {
            model.append(newItem)
            return model.get(model.count)
        }

		var existing = model.get(indices[0])
        if (! updateIfExist) { return existing }

		// Really update only if existing and new item have a difference
		for (var role in existing) {
			if (Boolean(existing[role].getTime)) {
				if (existing[role].getTime() != newItem[role].getTime()) {
					model.set(indices[0], newItem)
					return existing
				}
			} else {
				if (existing[role] != newItem[role]) {
					model.set(indices[0], newItem)
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

    function popWhere(rolesAre, maxResults=null, maxTries=null) {
        var indices = getIndices(rolesAre, maxResults, maxTries)
        var items = []

        for (var i = 0; i < indices.length; i++) {
            items.push(model.get(indices[i]))
            model.remove(indices[i])
        }
        return items
    }


    function toObject(itemList=sortFilteredModel) {
        var objList = []

        for (var i = 0; i < itemList.count; i++) {
            var item = itemList.get(i)
            var obj  = JSON.parse(JSON.stringify(item))

            for (var role in obj) {
                if (obj[role]["objectName"] != undefined) {
                    obj[role] = toObject(item[role])
                }
            }
            objList.push(obj)
        }
        return objList
    }

    function toJson() {
        return JSON.stringify(toObject(), null, 4)
    }
}
