import QtQuick 2.12
import QtQuick.Controls 2.12

ListView {
    id: listView
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
        color: theme.controls.listView.highlight
    }

    // Important:
    // https://doc.qt.io/qt-5/qml-qtquick-viewtransition.html#handling-interrupted-animations

    populate: add
    displaced: move

    add: Transition {
        ParallelAnimation {
            HNumberAnimation { property: "opacity"; from: 0; to: 1 }
            HNumberAnimation { properties: "x,y"; from: 100 }
        }
    }

    move: Transition {
        ParallelAnimation {
            HNumberAnimation { property: "opacity"; to: 1 }
            HNumberAnimation { properties: "x,y" }
        }
    }

    remove: Transition {
        ParallelAnimation {
            HNumberAnimation { property: "opacity"; to: 0 }
            HNumberAnimation { properties: "x,y"; to: 100 }
        }
    }
}
