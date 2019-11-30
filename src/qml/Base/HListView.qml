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

    // FIXME: HOpacityAnimator creates flickering

    add: Transition {
        ParallelAnimation {
            HNumberAnimation { property: "opacity"; from: 0; to: 1 }
            HXAnimator { from: 100 }
            HYAnimator { from: 100 }
        }
    }

    move: Transition {
        ParallelAnimation {
            // Ensure opacity goes to 1 if add/remove transition is interrupted
            HNumberAnimation { property: "opacity"; to: 1 }
            HXAnimator {}
            HYAnimator {}
        }
    }

    remove: Transition {
        ParallelAnimation {
            HNumberAnimation { property: "opacity"; to: 0 }
            HXAnimator { to: 100 }
            HYAnimator { to: 100 }
        }
    }

    displaced: move
}
