// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Layouts 1.12
import ".."

HButton {
    text: qsTr("Apply")
    icon.name: "apply"
    icon.color: theme.colors.positiveBackground

    Layout.preferredHeight: theme.baseElementsHeight
    Layout.fillWidth: true
}
