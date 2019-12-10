import QtQuick 2.12
import QtQuick.Controls 2.12

ListView {
    id: listView
    interactive: allowDragging
    currentIndex: -1
    keyNavigationWraps: true
    highlightMoveDuration: theme.animationDuration

    // Keep highlighted delegate at the center
    highlightRangeMode: ListView.ApplyRange
    preferredHighlightBegin: height / 2 - currentItemHeight
    preferredHighlightEnd: height / 2 + currentItemHeight

    maximumFlickVelocity: 4000


    highlight: Rectangle {
        color: theme.controls.listView.highlight
    }

    ScrollBar.vertical: ScrollBar {
        visible: listView.interactive || ! listView.allowDragging
    }

    add: Transition {
        ParallelAnimation {
            HNumberAnimation { property:   "opacity"; from: 0; to: 1 }
            HNumberAnimation { properties: "x,y";     from: 100 }
        }
    }

    move: Transition {
        ParallelAnimation {
            // Ensure opacity goes to 1 if add/remove transition is interrupted
            HNumberAnimation { property:   "opacity"; to: 1 }
            HNumberAnimation { properties: "x,y" }
        }
    }

    remove: Transition {
        ParallelAnimation {
            HNumberAnimation { property:   "opacity"; to: 0 }
            HNumberAnimation { properties: "x,y";     to: 100 }
        }
    }

    displaced: move


    property bool allowDragging: true

    property alias cursorShape: mouseArea.cursorShape

    readonly property int currentItemHeight:
        currentItem ? currentItem.height : 0


    Connections {
        target: listView
        enabled: ! listView.allowDragging
        // interactive gets temporarily set to true below to allow wheel scroll
        onDraggingChanged: listView.interactive = false
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
