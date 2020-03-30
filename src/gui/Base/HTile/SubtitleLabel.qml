// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Layouts 1.12
import ".."

HRichLabel {
    textFormat: Text.StyledText
    font.pixelSize: theme.fontSize.small
    verticalAlignment: Qt.AlignVCenter
    elide: Text.ElideRight
    color: theme.colors.dimText
    visible: Layout.maximumHeight > 0

    Layout.maximumHeight: ! tile.compact && text ? implicitHeight : 0
    Layout.fillWidth: true
    Layout.fillHeight: true


    property HTile tile


    Behavior on Layout.maximumHeight { HNumberAnimation {} }
}
