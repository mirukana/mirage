// Copyright Mirage authors & contributors <https://github.com/mirukana/mirage>
// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Controls 2.12

TextEdit {
    id: label

    property bool enableLinkActivation: true

    // For rich text, selectedText returns some weird invisible characters
    // instead of real newlines
    readonly property string selectedPlainText:
        selectedText.replace(/[\u2028\u2029]/g, "\n")

    function selectWordAt(position) {
        label.cursorPosition = positionAt(position.x, position.y)
        label.selectWord()
    }

    function selectAllText() {
        label.selectAll()
    }

    font.family: theme.fontFamily.sans
    font.pixelSize: theme.fontSize.normal
    color: theme.colors.text
    textFormat: Label.PlainText
    tabStopDistance: 4 * 4  // 4 spaces
    horizontalAlignment: Label.AlignLeft

    readOnly: true
    activeFocusOnPress: false
    focus: false
    selectByMouse: true

    onLinkActivated: if (enableLinkActivation && link !== '#state-text')
        Qt.openUrlExternally(link)

    MouseArea {
        anchors.fill: label
        acceptedButtons: Qt.NoButton
        cursorShape: label.hoveredLink ? Qt.PointingHandCursor : Qt.IBeamCursor
    }
}
