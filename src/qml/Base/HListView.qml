import QtQuick 2.12
import QtQuick.Controls 2.12

ListView {
    id: listView
    interactive: enableFlicking
    currentIndex: -1
    keyNavigationWraps: true
    highlightMoveDuration: theme.animationDuration

    // Keep highlighted delegate at the center
    highlightRangeMode: ListView.ApplyRange
    preferredHighlightBegin: height / 2 - currentItemHeight
    preferredHighlightEnd: height / 2 + currentItemHeight

    maximumFlickVelocity: 4000

    property bool enableFlicking: true

    readonly property int currentItemHeight:
        currentItem ? currentItem.height : 0


    highlight: Rectangle {
        color: theme.controls.listView.highlight
    }

    ScrollBar.vertical: ScrollBar {
        visible: listView.interactive || ! listView.enableFlicking
    }

    add: Transition {
        ParallelAnimation {
            HOpacityAnimator { from: 0; to: 1 }
            HNumberAnimation { properties: "x,y"; from: 100 }
        }
    }

    move: Transition {
        ParallelAnimation {
            // Ensure opacity goes to 1 if add/remove transition is interrupted
            HOpacityAnimator { to: 1 }
            HNumberAnimation { properties: "x,y" }
        }
    }

    remove: Transition {
        ParallelAnimation {
            HOpacityAnimator { to: 0 }
            HNumberAnimation { properties: "x,y"; to: 100 }
        }
    }

    displaced: move
}
