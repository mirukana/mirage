// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Controls 2.12

GridView {
    id: gridView
    interactive: allowDragging
    currentIndex: -1
    keyNavigationWraps: true
    highlightMoveDuration: theme.animationDuration

    // Keep highlighted delegate at the center
    highlightRangeMode: GridView.ApplyRange
    preferredHighlightBegin: height / 2 - currentItemHeight / 2
    preferredHighlightEnd: height / 2 + currentItemHeight / 2

    maximumFlickVelocity: 4000


    highlight: Rectangle {
        color: theme.controls.gridView.highlight
    }

    ScrollBar.vertical: ScrollBar {
        visible: gridView.interactive || ! gridView.allowDragging
    }

    // property bool debug: false

    // https://doc.qt.io/qt-5/qml-qtquick-viewtransition.html
    // #handling-interrupted-animations
    add: Transition {
        // ScriptAction { script: if (gridView.debug) print("add") }
        HNumberAnimation { property: "opacity"; from: 0; to: 1 }
        HNumberAnimation { property: "scale";   from: 0; to: 1 }
    }

    move: Transition {
        // ScriptAction { script: if (gridView.debug) print("move") }
        HNumberAnimation { property:   "opacity"; to: 1 }
        HNumberAnimation { property:   "scale";   to: 1 }
        HNumberAnimation { properties: "x,y" }
    }

    remove: Transition {
        // ScriptAction { script: if (gridView.debug) print("remove") }
        HNumberAnimation { property: "opacity"; to: 0 }
        HNumberAnimation { property: "scale";   to: 0 }
    }

    displaced: Transition {
        // ScriptAction { script: if (gridView.debug) print("displaced") }
        HNumberAnimation { property:   "opacity"; to: 1 }
        HNumberAnimation { property:   "scale";   to: 1 }
        HNumberAnimation { properties: "x,y" }
    }

    onSelectedCountChanged: if (! selectedCount) lastCheckedDelegateIndex = 0


    property bool allowDragging: true
    property alias cursorShape: mouseArea.cursorShape
    property int currentItemHeight: currentItem ? currentItem.height : 0

    property var checked: ({})
    property int lastCheckedDelegateIndex: 0
    property int selectedCount: Object.keys(checked).length


    function check(...indices) {
        for (const i of indices) {
            const model = gridView.model.get(i)
            checked[model.id] = model
        }

        lastCheckedDelegateIndex = indices.slice(-1)[0]
        checkedChanged()
    }

    function checkFromLastToHere(here) {
        const indices = utils.range(lastCheckedDelegateIndex, here)
        eventList.check(...indices)
    }

    function uncheck(...indices) {
        for (const i of indices) {
            const model = gridView.model.get(i)
            delete checked[model.id]
        }

        checkedChanged()
    }

    function toggleCheck(...indices) {
        const checkedIndices = []

        for (const i of indices) {
            const model = gridView.model.get(i)

            if (model.id in checked) {
                delete checked[model.id]
            } else {
                checked[model.id] = model
                checkedIndices.push(i)
            }
        }

        if (checkedIndices.length > 0)
            lastCheckedDelegateIndex = checkedIndices.slice(-1)[0]

        checkedChanged()
    }

    function getSortedChecked() {
        return Object.values(checked).sort(
            (a, b) => a.date > b.date ? 1 : -1
        )
    }


    Connections {
        target: gridView
        enabled: ! gridView.allowDragging
        // interactive gets temporarily set to true below to allow wheel scroll
        onDraggingChanged: gridView.interactive = false
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        enabled: ! parent.allowDragging || cursorShape !== Qt.ArrowCursor
        acceptedButtons: Qt.NoButton
        onWheel: {
            // Allow wheel usage, will be back to false on any drag attempt
            parent.interactive = true
            wheel.accepted = false
        }
    }
}
