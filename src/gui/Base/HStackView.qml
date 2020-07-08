// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Controls 2.12

StackView {
    pushEnter: Transition {
        HNumberAnimation {
            property: "scale"
            from: 0
            to: 1
        }
    }

    pushExit: Transition {
        HNumberAnimation {
            property: "opacity"
            from: 1
            to: 0
        }
    }

    popEnter: Transition {
        HNumberAnimation {
            property: "opacity"
            from: 0
            to: 1
        }
    }

    popExit: Transition {
        HNumberAnimation {
            property: "scale"
            from: 1
            to: 0
        }
    }
}
