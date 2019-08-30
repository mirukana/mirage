import QtQuick 2.12

Item {
    signal deselectAll()


    property bool reversed: false

    readonly property bool dragging: pointHandler.active || dragHandler.active
    // onDraggingChanged: print(dragging)
    property bool selecting: false
    property int selectionStart: -1
    property int selectionEnd: -1
    property point selectionStartPosition: Qt.point(-1, -1)
    property point selectionEndPosition: Qt.point(-1, -1)
    property var selectedTexts: ({})

    readonly property var selectionInfo: [
        selectionStart, selectionStartPosition,
        selectionEnd, selectionEndPosition,
    ]

    readonly property alias dragPoint: dragHandler.centroid
    readonly property alias dragPosition: dragHandler.centroid.position


    function clearSelection() {
        selecting              = false
        selectionStart         = -1
        selectionEnd           = -1
        selectionStartPosition = Qt.point(-1, -1)
        selectionEndPosition   = Qt.point(-1, -1)
        deselectAll()
    }

    function copySelection() {
        let toCopy = []

        for (let key of Object.keys(selectedTexts).sort()) {
            if (selectedTexts[key]) toCopy.push(selectedTexts[key])
        }

        // Call some function to copy to clipboard here instead
        print("Copy: <" + toCopy.join("\n\n") + ">")
    }


    Item { id: dragPoint }

    DragHandler {
        id: dragHandler
        target: dragPoint
        onActiveChanged: {
            if (active) {
                target.Drag.active = true
            } else {
                target.Drag.drop()
                target.Drag.active = false
                selecting          = false
            }
        }
    }

    TapHandler {
        acceptedButtons: Qt.LeftButton
        onTapped: clearSelection()
    }

    PointHandler {
        id: pointHandler
    }
}
