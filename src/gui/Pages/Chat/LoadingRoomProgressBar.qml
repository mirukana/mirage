// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../../Base"

HProgressBar {
    indeterminate: true
    height: chat.loadingMessages ? implicitHeight : 0
    visible: height > 0

    Behavior on height { HNumberAnimation {} }
}
