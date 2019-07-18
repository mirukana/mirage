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
        for (let item of newItems) { model.append(item) }
    }

    function getIndices(whereRolesAre, maxResults=null, maxTries=null) {
        // maxResults, maxTries: null or int
        let results = []

        for (let i = 0; i < model.count; i++) {
            let item    = model.get(i)
            let include = true

            for (let role in whereRolesAre) {
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
        let items = []

        for (let indice of getIndices(rolesAre, maxResults, maxTries)) {
            items.push(model.get(indice))
        }
        return items
    }

    function forEachWhere(rolesAre, func, maxResults=null, maxTries=null) {
        for (let item of getWhere(rolesAre, maxResults, maxTries)) {
            func(item)
        }
    }

    function upsert(
        whereRolesAre, newItem, updateIfExist=true, maxTries=null
    ) {
        let indices = getIndices(whereRolesAre, 1, maxTries)

        if (indices.length == 0) {
            model.append(newItem)
            return model.get(model.count)
        }

		let existing = model.get(indices[0])
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
        let item = model.get(index)
        model.remove(index)
        return item
    }

    function popWhere(rolesAre, maxResults=null, maxTries=null) {
        let items = []

        for (let indice of getIndices(rolesAre, maxResults, maxTries)) {
            items.push(model.get(indice))
            model.remove(indice)
        }
        return items
    }


    function toObject(itemList=sortFilteredModel) {
        let objList = []

        for (let item of itemList) {
            let obj = JSON.parse(JSON.stringify(item))

            for (let role in obj) {
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
