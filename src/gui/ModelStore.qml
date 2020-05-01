// SPDX-License-Identifier: LGPL-3.0-or-later

pragma Singleton
import QtQuick 2.12
import "PythonBridge"

QtObject {
    property QtObject privates: QtObject {
        readonly property var store: ({})

        readonly property PythonBridge py: PythonBridge {}

        readonly property Component model: Component {
            ListModel {
                // Used by HFilterModel
                signal fieldsChanged(int index, var changes)

                property var modelId

                function findIndex(id, default_=null) {
                    for (let i = 0; i < count; i++)
                        if (get(i).id === id) return i

                    return default_
                }

                function find(id, default_=null) {
                    for (let i = 0; i < count; i++)
                        if (get(i).id === id) return get(i)

                    return default_
                }
            }
        }
    }


    function get(...modelId) {
        if (modelId.length === 1) modelId = modelId[0]

        if (! privates.store[modelId])
            privates.store[modelId] =
                privates.model.createObject(this, {modelId})

        return privates.store[modelId]
    }
}
