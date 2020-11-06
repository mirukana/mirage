// Copyright Mirage authors & contributors <https://github.com/mirukana/mirage>
// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Layouts 1.12
import ".."

HButton {
    property Item textControl  // HTextField or HTextArea


    icon.name: "copy-text"
    iconItem.small: true

    toolTip.text: qsTr("Copy")
    toolTip.onClosed: toolTip.text = qsTr("Copy")
    toolTip.label.wrapMode: HLabel.NoWrap

    onClicked: {
        textControl.selectAll()
        textControl.copy()
        textControl.deselect()

        toolTip.text = qsTr("Copied!")
        toolTip.instantShow(2000)
    }

    onActiveFocusChanged: if (! activeFocus && toolTip.visible) toolTip.hide()

    Layout.fillHeight: true
}
