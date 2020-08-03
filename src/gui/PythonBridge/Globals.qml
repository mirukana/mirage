// SPDX-License-Identifier: LGPL-3.0-or-later

pragma Singleton
import QtQuick 2.12

QtObject {
    readonly property var pendingCoroutines: ({})
    readonly property var hideErrorTypes: new Set(["gaierror", "SSLError"])
}
