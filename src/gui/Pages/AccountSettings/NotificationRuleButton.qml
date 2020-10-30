// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import "../../Base"

HButton {
    property bool on: true

    opacity: on ? 1 : theme.disabledElementsOpacity
    hoverEnabled: true
    backgroundColor: "transparent"
}
