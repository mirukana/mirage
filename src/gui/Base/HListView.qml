// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Controls 2.12

ListView {
    id: listView

    property int currentItemHeight: currentItem ? currentItem.height : 0

    property var checked: ({})
    property var checkedIndice: new Set()
    property int lastCheckedDelegateIndex: 0
    property int selectedCount: Object.keys(checked).length

    function check(...indices) {
        for (const i of indices) {
            const model       = listView.model.get(i)
            checked[model.id] = model
            checkedIndice.add(i)
        }

        lastCheckedDelegateIndex = indices.slice(-1)[0]
        checkedChanged()
        checkedIndiceChanged()
    }

    function checkFromLastToHere(here) {
        const indices = utils.range(lastCheckedDelegateIndex, here)
        eventList.check(...indices)
    }

    function uncheck(...indices) {
        for (const i of indices) {
            const model = listView.model.get(i)
            delete checked[model.id]
            checkedIndice.delete(i)
        }

        checkedChanged()
        checkedIndiceChanged()
    }

    function uncheckAll() {
        checked       = {}
        checkedIndice = new Set()
    }

    function toggleCheck(...indices) {
        const checkedNow = []

        for (const i of indices) {
            const model = listView.model.get(i)

            if (model.id in checked) {
                delete checked[model.id]
                checkedIndice.delete(i)
            } else {
                checked[model.id]       = model
                checkedNow.push(i)
                checkedIndice.add(i)
            }
        }

        if (checkedNow.length > 0)
            lastCheckedDelegateIndex = checkedNow.slice(-1)[0]

        checkedChanged()
        checkedIndiceChanged()
    }

    function getSortedChecked() {
        return Object.values(checked).sort(
            (a, b) => a.date > b.date ? 1 : -1
        )
    }


    currentIndex: -1
    keyNavigationWraps: true
    highlightMoveDuration: theme.animationDuration
    highlightResizeDuration: theme.animationDuration

    // Keep highlighted delegate at the center
    highlightRangeMode: ListView.ApplyRange
    preferredHighlightBegin: height / 2 - currentItemHeight / 2
    preferredHighlightEnd: height / 2 + currentItemHeight / 2

    maximumFlickVelocity: window.settings.kineticScrollingMaxSpeed
    flickDeceleration: window.settings.kineticScrollingDeceleration

    highlight: Rectangle {
        color: theme.controls.listView.highlight

        Rectangle {
            width: theme.controls.listView.highlightBorderThickness
            height: parent.height
            color: theme.controls.listView.highlightBorder
        }
    }

    ScrollBar.vertical: HScrollBar {
        flickableMoving: listView.moving
        visible: listView.interactive
    }

    // property bool debug: false

    // https://doc.qt.io/qt-5/qml-qtquick-viewtransition.html
    // #handling-interrupted-animations
    add: Transition {
        // ScriptAction { script: if (listView.debug) print("add") }
        HNumberAnimation { property: "opacity"; from: 0; to: 1 }
        HNumberAnimation { property: "scale";   from: 0; to: 1 }
    }

    move: Transition {
        // ScriptAction { script: if (listView.debug) print("move") }
        HNumberAnimation { property:   "opacity"; to: 1 }
        HNumberAnimation { property:   "scale";   to: 1 }
        HNumberAnimation { properties: "x,y" }
    }

    remove: Transition {
        // ScriptAction { script: if (listView.debug) print("remove") }
        HNumberAnimation { property: "opacity"; to: 0 }
        HNumberAnimation { property: "scale";   to: 0 }
    }

    displaced: Transition {
        // ScriptAction { script: if (listView.debug) print("displaced") }
        HNumberAnimation { property:   "opacity"; to: 1 }
        HNumberAnimation { property:   "scale";   to: 1 }
        HNumberAnimation { properties: "x,y" }
    }

    onSelectedCountChanged: if (! selectedCount) lastCheckedDelegateIndex = 0

    HKineticScrollingDisabler {
        width: enabled ? parent.width : 0
        height: enabled ? parent.height : 0
    }
}
