import QtQuick 2.12
import "../utils.js" as Utils

FocusScope {
    signal deselectAll()
    signal dragStarted()
    signal dragStopped()
    signal dragPointChanged(var eventPoint)


    property bool reversed: false

    property bool selecting: false
    property real selectionStart: -1
    property real selectionEnd: -1
    property point selectionStartPosition: Qt.point(-1, -1)
    property point selectionEndPosition: Qt.point(-1, -1)
    property var selectedTexts: ({})

    readonly property var selectionInfo: [
        selectionStart, selectionStartPosition,
        selectionEnd, selectionEndPosition,
    ]

    readonly property string joinedSelection: {
        let toCopy = []

        for (let key of Object.keys(selectedTexts).sort()) {
            if (! selectedTexts[key]) continue

            // For some dumb reason, Object.keys convert the floats to strings
            toCopy.push(Number.isInteger(parseFloat(key)) ? "\n\n" : "\n")
            toCopy.push(selectedTexts[key])
        }

        if (reversed) toCopy.reverse()

        return toCopy.join("").trim()
    }


    onDragStarted: {
        draggedItem.Drag.active = true
    }
    onDragStopped: {
        draggedItem.Drag.drop()
        draggedItem.Drag.active = false
        selecting               = false
    }
    onDragPointChanged: {
        let pos = mapFromItem(
            mainUI, eventPoint.scenePosition.x, eventPoint.scenePosition.y,
        )
        draggedItem.x = pos.x
        draggedItem.y = pos.y
    }


    function clearSelection() {
        selecting              = false
        selectionStart         = -1
        selectionEnd           = -1
        selectionStartPosition = Qt.point(-1, -1)
        selectionEndPosition   = Qt.point(-1, -1)
        deselectAll()
    }


    // PointHandler and TapHandler won't activate if the press occurs inside
    // a label child, so we need a Point/TapHandler inside them too.

    PointHandler {
        // We don't use a DragHandler because they have an unchangable minimum
        // drag distance before they activate.
        id: pointHandler
        onActiveChanged: active ? dragStarted() : dragStopped()
        onPointChanged: dragPointChanged(point)
    }

    TapHandler {
        acceptedButtons: Qt.LeftButton
        onTapped: clearSelection()
    }

    // This item will trigger the children labels's DropAreas
    Item { id: draggedItem }
}
