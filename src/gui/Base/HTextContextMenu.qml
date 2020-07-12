// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12

HMenu {
    property Item control: parent  // HTextField or HTextArea

    property bool hadPersistentSelection: false  // TODO: use a Qt 5.15 Binding

    function spawn(atMousePosition=true) {
        hadPersistentSelection      = control.persistentSelection
        control.persistentSelection = true

        atMousePosition ?
        popup() :
        popup(
            control.cursorRectangle.right,
            control.cursorRectangle.bottom + theme.spacing / 4,
        )
    }


    onClosed: control.persistentSelection = hadPersistentSelection
    Component.onDestruction:
        control.persistentSelection = hadPersistentSelection

    HMenuItem {
        icon.name: "undo"
        text: qsTr("Undo")
        enabled: control.canUndo
        onTriggered: control.undo()
    }

    HMenuItem {
        icon.name: "redo"
        text: qsTr("Redo")
        enabled: control.canRedo
        onTriggered: control.redo()
    }

    HMenuSeparator {}

    HMenuItem {
        icon.name: "cut-text"
        text: qsTr("Cut")
        enabled: control.selectedText
        onTriggered: control.cut()
    }

    HMenuItem {
        icon.name: "copy-text"
        text: qsTr("Copy")
        enabled: control.selectedText
        onTriggered: control.copy()
    }

    HMenuItem {
        icon.name: "paste-text"
        text: qsTr("Paste")
        enabled: control.canPaste
        onTriggered: control.paste()
    }

    HMenuSeparator {}

    HMenuItem {
        icon.name: "select-all-text"
        text: qsTr("Select all")
        enabled: control.length > 0
        onTriggered: control.selectAll()
    }
}
