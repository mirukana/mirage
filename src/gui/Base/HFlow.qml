// Copyright Mirage authors & contributors <https://github.com/mirukana/mirage>
// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12

Flow {
    populate: Transition {
        id: addTrans

        SequentialAnimation {
            PropertyAction { property: "opacity"; value: 0 }

            PauseAnimation {
                duration:
                    addTrans.ViewTransition.index * theme.animationDuration / 2
            }

            ParallelAnimation {
                HNumberAnimation { property:   "opacity"; to: 1 }
                HNumberAnimation { properties: "x,y";     from: 0 }
            }
        }
    }

    add: Transition {
        ParallelAnimation {
            HNumberAnimation { property:   "opacity"; to: 1 }
            HNumberAnimation { properties: "x,y";     from: 0 }
        }
    }

    move: Transition {
        ParallelAnimation {
            // Ensure opacity goes to 1 if add transition is interrupted
            HNumberAnimation { property:   "opacity"; to: 1 }
            HNumberAnimation { properties: "x,y" }
        }
    }
}
