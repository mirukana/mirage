// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Layouts 1.12
import ".."

HButton {
    implicitHeight: theme.baseElementsHeight
    text: qsTr("Apply")
    icon.name: "apply"
    icon.color: theme.colors.positiveBackground

    Layout.fillWidth: true
}
