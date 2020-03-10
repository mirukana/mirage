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
                property var modelId

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
