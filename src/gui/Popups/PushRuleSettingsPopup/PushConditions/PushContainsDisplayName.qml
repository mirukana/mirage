// Copyright Mirage authors & contributors <https://github.com/mirukana/mirage>
// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import ".."
import "../../../Base"

CustomLabel {
    readonly property var matrixObject: ({kind: model.kind})

    text: qsTr("Message contains my display name")
}
