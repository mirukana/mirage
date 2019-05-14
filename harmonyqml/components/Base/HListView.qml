import QtQuick 2.7

ListView {
    property int duration: HStyle.animationDuration

    add: Transition {
        NumberAnimation { properties: "x,y"; from: 100; duration: duration }
    }

    populate: Transition {
        NumberAnimation { properties: "x,y"; duration: duration }
    }

    move: Transition {
        NumberAnimation { properties: "x,y"; duration: duration }
    }

    displaced: Transition {
        NumberAnimation { properties: "x,y"; duration: duration }
    }

    remove: Transition {
        ParallelAnimation {
            NumberAnimation { property: "opacity"; to: 0; duration: duration }
            NumberAnimation { properties: "x,y"; to: 100; duration: duration }
        }
    }
}
