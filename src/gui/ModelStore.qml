// Copyright Mirage authors & contributors <https://github.com/mirukana/mirage>
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
                property var idToItems: ({})

                // Used by HFilterModel
                signal fieldsChanged(int index, var changes)

                function findIndex(id, default_=null) {
                    for (let i = 0; i < count; i++)
                        if (get(i).id === id) return i

                    return default_
                }

                function find(id, default_=null) {
                    return idToItems[id] || default_
                }
            }
        }

        signal ensureModelExists(var modelId)

        onEnsureModelExists:
            py.callCoro("models.ensure_exists_from_qml", [modelId])
    }

    function get(...modelId) {
        if (modelId.length === 1) modelId = modelId[0]

        if (! privates.store[modelId]) {
            // Using a signal somehow avoids a binding loop
            privates.ensureModelExists(modelId)

            privates.store[modelId] =
                privates.model.createObject(this, {modelId})
        }

        return privates.store[modelId]
    }
}
