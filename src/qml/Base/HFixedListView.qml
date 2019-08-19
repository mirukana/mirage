import QtQuick 2.12
import QtQuick.Controls 2.12

ListView {
    interactive: false
    currentIndex: -1
    highlightMoveDuration: theme.animationDuration

    // Keep highlighted delegate at the center
    highlightRangeMode: ListView.ApplyRange
    preferredHighlightBegin: height / 2 - currentItemHeight
    preferredHighlightEnd: height / 2 + currentItemHeight


    readonly property int currentItemHeight:
        currentItem ? currentItem.height : 0


    highlight: HRectangle {
        color: theme.controls.interactiveRectangle.checkedOverlay
        opacity: theme.controls.interactiveRectangle.checkedOpacity
    }

    add: Transition {
        HNumberAnimation { properties: "x,y"; from: 100 }
    }

    move: Transition {
        HNumberAnimation { properties: "x,y" }
    }

    displaced: Transition {
        HNumberAnimation { properties: "x,y" }
    }

    remove: Transition {
        ParallelAnimation {
            HNumberAnimation { property: "opacity"; to: 0 }
            HNumberAnimation { properties: "x,y"; to: 100 }
        }
    }
}
