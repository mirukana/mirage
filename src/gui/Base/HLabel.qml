// Copyright Mirage authors & contributors <https://github.com/mirukana/mirage>
// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick.Controls 2.12
import QtQuick 2.12

Label {
    font.family: theme.fontFamily.sans
    font.pixelSize: theme.fontSize.normal
    font.pointSize: -1
    textFormat: Label.PlainText

    color: theme.colors.text
    linkColor: theme.colors.link

    maximumLineCount: elide === Label.ElideNone ? Number.MAX_VALUE : 1

    onLinkActivated: Qt.openUrlExternally(link)
}
