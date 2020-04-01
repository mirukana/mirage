// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12

Shortcut {
    enabled: ! window.anyPopupOrMenu && active
    context: Qt.ApplicationShortcut


    // TODO: use enabled + a Binding with restoreValue when switch to Qt 5.15
    property bool active: true
}
