// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12


HRectangleBottomBorder {
    id: line

    property bool show: false


    transform: Scale {
        origin.x: line.width / 2
        origin.y: line.height / 2
        xScale: line.show ? 1 : 0

        Behavior on xScale { HNumberAnimation {} }
    }

    Behavior on color { HColorAnimation {} }
}
