// Copyright 2019 miruka
// This file is part of harmonyqml, licensed under LGPLv3.

import QtQuick 2.12

ListView {
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
