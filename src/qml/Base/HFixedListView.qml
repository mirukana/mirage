import QtQuick 2.12
import QtQuick.Controls 2.12

ListView {
    interactive: false
    currentIndex: -1

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
