import QtQuick 2.12
import QSyncable 1.0

JsonListModel {
    id: model
    source: []
    Component.onCompleted: if (! keyField) { throw "keyField not set" }

    function toObject(itemList=listModel) {
        let objList = []

        for (let item of itemList) {
            let obj = JSON.parse(JSON.stringify(item))

            for (let role in obj) {
                if (obj[role]["objectName"] !== undefined) {
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
