// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../Base"

HLabel {
    wrapMode: HLabel.Wrap
    font.bold: true
    visible: Boolean(text)

    Layout.fillWidth: true
}
