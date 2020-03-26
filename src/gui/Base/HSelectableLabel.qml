// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Controls 2.12

TextEdit {
    id: label
    font.family: theme.fontFamily.sans
    font.pixelSize: theme.fontSize.normal
    color: theme.colors.text

    textFormat: Label.PlainText
    tabStopDistance: 4 * 4  // 4 spaces

    readOnly: true
    activeFocusOnPress: false
    focus: false

    onLinkActivated: if (enableLinkActivation) Qt.openUrlExternally(link)


    property bool enableLinkActivation: true


    function selectWordAt(position) {
        label.cursorPosition = positionAt(position.x, position.y)
        label.selectWord()
    }

    function selectAllText() {
        label.selectAll()
    }


    // XXX
    // TapHandler {
    //     acceptedButtons: Qt.LeftButton
    //     onTapped: {
    //         tapCount === 2 ? selectWordAt(eventPoint.position) :
    //         tapCount === 3 ? selectAllText() :
    //         null
    //     }
    // }

    MouseArea {
        anchors.fill: label
        acceptedButtons: Qt.NoButton
        cursorShape: label.hoveredLink ? Qt.PointingHandCursor : Qt.IBeamCursor
    }
}
